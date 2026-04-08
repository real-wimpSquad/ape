#!/usr/bin/env bash
set -euo pipefail

# ==========================================================================
# Atomic Pumpkin — launcher
# Works in: WSL (via ape.bat), native Linux, macOS
# ==========================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
if [ -t 1 ]; then
    G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'
    C='\033[0;36m'; B='\033[1m'; N='\033[0m'
else
    G=''; R=''; Y=''; C=''; B=''; N=''
fi

ok()    { echo -e "  ${G}✓${N} $*"; }
warn()  { echo -e "  ${Y}!${N} $*"; }
err()   { echo -e "  ${R}✗${N} $*"; }
hdr()   { echo -e "\n  ${B}$*${N}"; }
lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# Are we running inside WSL?
IS_WSL=0
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1

# WSL networking fix: lower MTU to prevent TLS "bad record MAC" errors
if [ "$IS_WSL" = "1" ]; then
    current_mtu=$(cat /sys/class/net/eth0/mtu 2>/dev/null || echo "1500")
    if [ "$current_mtu" -gt 1200 ] 2>/dev/null; then
        sudo ip link set eth0 mtu 1200 2>/dev/null || true
    fi
    # Docker daemon also needs its own MTU config
    if [ ! -f /etc/docker/daemon.json ] || ! grep -q '"mtu"' /etc/docker/daemon.json 2>/dev/null; then
        sudo mkdir -p /etc/docker
        echo '{"mtu": 1200}' | sudo tee /etc/docker/daemon.json >/dev/null
    fi
fi

# ==========================================================================
# Dependency checks — friendly, step-by-step
# ==========================================================================

check_deps() {
    hdr "Checking dependencies..."
    echo ""
    local need_install=0

    # ---------- Docker ----------
    if command -v docker &>/dev/null; then
        if docker info &>/dev/null; then
            ok "Docker is running."
        else
            warn "Docker is installed but not running."
            echo ""
            if [ "$IS_WSL" = "1" ]; then
                echo "  Two possible fixes:"
                echo ""
                echo "    A) If you have Docker Desktop on Windows:"
                echo "       Open it from your Start menu / taskbar, then wait"
                echo "       about 30 seconds and try this script again."
                echo ""
                echo "       Also make sure WSL integration is turned on:"
                echo "       Docker Desktop > Settings > Resources > WSL Integration"
                echo ""
                echo "    B) If you DON'T have Docker Desktop:"
                echo "       No problem — we can install Docker right here in Linux."
                echo ""
                read -rp "  Try to start Docker here? (Y/n): " fix
                if [[ "$(lower "$fix")" != "n" ]]; then
                    start_docker_service
                fi
            else
                echo "  Starting Docker..."
                start_docker_service
            fi
        fi
    else
        err "Docker is not installed."
        echo ""
        if [ "$IS_WSL" = "1" ]; then
            echo "  You have two options:"
            echo ""
            echo "    A) Install Docker Desktop on Windows (has a nice GUI)"
            echo "       Download: https://docker.com/products/docker-desktop"
            echo "       After install, enable WSL integration in Settings."
            echo ""
            echo "    B) Install Docker Engine right here in Linux (no GUI needed)"
            echo ""
            read -rp "  Install Docker Engine here? (Y/n): " choice
            if [[ "$(lower "$choice")" != "n" ]]; then
                install_docker
            else
                echo ""
                echo "  OK! Install Docker Desktop from the link above,"
                echo "  then run this script again."
                NEED_DOCKER_MANUAL=1
            fi
        else
            read -rp "  Install Docker now? (Y/n): " choice
            if [[ "$(lower "$choice")" != "n" ]]; then
                install_docker
            else
                need_install=1
            fi
        fi
    fi

    # ---------- Docker Compose ----------
    if command -v docker &>/dev/null && docker compose version &>/dev/null; then
        ok "Docker Compose: $(docker compose version --short 2>/dev/null || echo 'OK')"
    elif command -v docker &>/dev/null; then
        warn "Docker Compose plugin not found — it usually comes with Docker."
        echo "  If Docker was just installed, try closing and reopening this script."
    fi

    echo ""

    if [ "${NEED_DOCKER_MANUAL:-0}" = "1" ]; then
        err "Docker still needs to be set up. See instructions above."
        echo ""
        read -rp "  Press Enter to continue anyway, or Ctrl+C to exit..." _
    else
        ok "Ready to go!"
    fi
}

# ==========================================================================
# Install helpers
# ==========================================================================

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null;     then echo "dnf"
    elif command -v pacman &>/dev/null;  then echo "pacman"
    elif command -v brew &>/dev/null;    then echo "brew"
    else echo "unknown"; fi
}

install_docker() {
    hdr "Installing Docker..."
    echo ""
    local pkg
    pkg=$(detect_pkg_manager)

    case $pkg in
        apt)
            echo "  Setting up Docker's package repository..."
            # Clean up any broken docker sources from a previous failed attempt
            sudo rm -f /etc/apt/sources.list.d/docker.list
            sudo apt-get update -qq
            sudo apt-get install -y -qq ca-certificates curl

            # Detect distro: debian vs ubuntu
            local distro codename
            distro=$(. /etc/os-release && echo "${ID}")
            codename=$(. /etc/os-release && echo "${VERSION_CODENAME}")

            # Docker doesn't have repos for testing/sid — fall back to stable
            case "$codename" in
                trixie|sid|"") codename="bookworm" ;;
            esac

            # Default to debian if not ubuntu
            case "$distro" in
                ubuntu) distro="ubuntu" ;;
                *)      distro="debian" ;;
            esac

            echo "  Using Docker repo: $distro/$codename"
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL "https://download.docker.com/linux/${distro}/gpg" | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${distro} ${codename} stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
            sudo apt-get update -qq
            echo "  Installing Docker Engine + Compose..."
            sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo usermod -aG docker "$USER" 2>/dev/null || true
            ;;
        dnf)
            sudo dnf install -y docker docker-compose-plugin
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER" 2>/dev/null || true
            ;;
        brew)
            brew install docker docker-compose colima
            echo ""
            echo "  On macOS, start Docker with: colima start"
            ;;
        *)
            err "Can't auto-install Docker on this system."
            err "Install manually: https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac

    start_docker_service
    echo ""
    ok "Docker installed!"
    echo ""
    if [ "$IS_WSL" = "1" ]; then
        echo "  Note: you may need to close and reopen this script"
        echo "  for Docker permissions to take effect."
        echo "  (Or run: newgrp docker)"
    fi
}

start_docker_service() {
    if docker info &>/dev/null; then
        return 0
    fi

    if [ "$IS_WSL" = "1" ]; then
        # WSL: try service command (no systemd in most WSL setups)
        sudo service docker start 2>/dev/null || true
    else
        # Native Linux
        sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
    fi

    # Wait for it
    local tries=0
    while ! docker info &>/dev/null && [ $tries -lt 20 ]; do
        sleep 2
        ((tries++))
        echo -ne "  Waiting for Docker... (${tries})\r"
    done
    echo ""

    if docker info &>/dev/null; then
        ok "Docker is running."
    else
        err "Docker didn't start."
        if [ "$IS_WSL" = "1" ]; then
            echo ""
            echo "  If you're using Docker Desktop on Windows, make sure:"
            echo "    1. Docker Desktop is running (check your taskbar)"
            echo "    2. WSL integration is on: Settings > Resources > WSL Integration"
            echo ""
            echo "  If you installed Docker Engine in Linux just now,"
            echo "  try closing this window and opening it again."
        fi
    fi
}

# ==========================================================================
# ape.toml bootstrap
# ==========================================================================

ensure_ape_toml() {
    [ -f "$SCRIPT_DIR/ape.toml" ] && return 0

    hdr "Creating ape.toml (first run)..."
    cat > "$SCRIPT_DIR/ape.toml" <<'TOML'
# APE Configuration — auto-generated on first run
# Edit directly or use: ape new concept <name>

[installation]
port = 50051

[concept_spaces.default]
qdrant_url = "http://qdrant:6334"
collection = "vdb"

[concept_spaces.default.embedder]
type = "local"
model = "jina-embeddings-v2-base-code"
dimension = 768

default_space = "default"

[services]
ape_core_url = "http://ape-core:8069"
litellm_url = "http://litellm:4000"
litellm_key_env = "LITELLM_MASTER_KEY"
TOML
    ok "Created ape.toml with default concept-space."
}

# ==========================================================================
# First-run: generate .env with secrets
# ==========================================================================

ensure_env() {
    # No .env required — secrets auto-bootstrap from the database,
    # API keys are managed in the web UI (Settings > Server Keys).
    # If a .env exists (from a prior install), it's respected as overrides.
    return 0
}

# ==========================================================================
# Docker Compose helpers
# ==========================================================================

compose_cmd() {
    local files="-f docker-compose.yml"
    for addon_dir in addons/*/; do
        [ -d "$addon_dir" ] || continue
        local addon compose_file
        addon=$(basename "$addon_dir")
        compose_file="$addon_dir/docker-compose.${addon}.yml"
        [ -f "$compose_file" ] && files="$files -f $compose_file"
    done
    for concept_dir in concepts/*/; do
        [ -d "$concept_dir" ] || continue
        local concept compose_file
        concept=$(basename "$concept_dir")
        compose_file="$concept_dir/docker-compose.concept-${concept}.yml"
        [ -f "$compose_file" ] && files="$files -f $compose_file"
    done
    echo "docker compose $files"
}

do_start() {
    ensure_ape_toml
    hdr "Starting Atomic Pumpkin..."
    echo ""
    local cmd
    cmd=$(compose_cmd)
    if $cmd up -d; then
        echo ""
        ok "Everything is running!"
        echo ""
        echo "    APE:     http://localhost:8070"
        echo ""
        echo "  Secrets auto-generate on first run."
        echo "  Add API keys in the web UI: Settings > Server Keys"
    else
        echo ""
        err "Something went wrong starting the services."
        echo ""
        echo "  Common fixes:"
        echo "    - Is Docker running? (check taskbar for Docker Desktop icon)"
        echo "    - Try option 3 (Restart) from the menu"
        echo "    - Try option 4 (Update) to pull fresh images"
    fi
}

do_stop() {
    hdr "Stopping..."
    local cmd
    cmd=$(compose_cmd)
    $cmd stop
    echo ""
    ok "Everything stopped. Your data is safe."
}

do_restart() {
    hdr "Restarting..."
    echo ""
    local cmd
    cmd=$(compose_cmd)
    $cmd down
    $cmd up -d
    echo ""
    ok "Restarted!"
}

do_update() {
    hdr "Checking for updates..."
    echo ""
    local cmd
    cmd=$(compose_cmd)
    echo "  Downloading latest versions..."
    $cmd pull
    echo ""
    echo "  Restarting with new versions..."
    $cmd down
    $cmd up -d
    echo ""
    ok "Updated and running!"
}

do_logs() {
    hdr "Live logs (press Ctrl+C to stop watching)"
    echo ""
    local cmd
    cmd=$(compose_cmd)
    $cmd logs -f
}

do_status() {
    echo ""
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
        --filter "label=com.docker.compose.project" 2>/dev/null; then
        true
    elif docker ps 2>/dev/null; then
        true
    else
        err "Can't reach Docker. Is it running?"
    fi
}

# ==========================================================================
# Concept-space management
# ==========================================================================

validate_concept_name() {
    local name="$1"
    if [ -z "$name" ]; then
        err "Name cannot be empty."; return 1
    fi
    if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
        err "Name must be lowercase alphanumeric + hyphens, starting with a letter."; return 1
    fi
    if [ "$name" = "default" ]; then
        err "'default' is reserved for the built-in concept-space."; return 1
    fi
    if [ -d "$SCRIPT_DIR/concepts/$name" ]; then
        err "Concept-space '$name' already exists."; return 1
    fi
    if grep -q "\[concept_spaces\.$name\]" "$SCRIPT_DIR/ape.toml" 2>/dev/null; then
        err "Concept-space '$name' already in ape.toml."; return 1
    fi
    return 0
}

next_qdrant_port() {
    local port=16334
    for compose_file in concepts/*/docker-compose.concept-*.yml; do
        [ -f "$compose_file" ] || continue
        local used
        used=$(grep -oP '"\K\d+(?=:6334")' "$compose_file" 2>/dev/null || true)
        if [ -n "$used" ] && [ "$used" -ge "$port" ]; then
            port=$((used + 10))
        fi
    done
    echo "$port"
}

create_concept() {
    local name="$1" embedder_type="$2" model="$3" dimension="$4"
    local api_url="${5:-}" api_key_env="${6:-}" ollama_url="${7:-}"

    ensure_ape_toml

    local port
    port=$(next_qdrant_port)

    # Create directory
    mkdir -p "$SCRIPT_DIR/concepts/$name"

    # Generate docker-compose fragment
    cat > "$SCRIPT_DIR/concepts/$name/docker-compose.concept-${name}.yml" <<EOF
# Auto-generated by: ape new concept $name
# Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)

services:
  qdrant-${name}:
    image: qdrant/qdrant:latest
    container_name: qdrant_${name}
    restart: unless-stopped
    ports:
      - "${port}:6334"
    volumes:
      - ./concepts/${name}/qdrant:/qdrant/storage
    networks:
      - atomic_pumpkin

networks:
  atomic_pumpkin:
    driver: bridge
EOF
    ok "Created concepts/$name/docker-compose.concept-${name}.yml"

    # Append concept-space to ape.toml
    {
        echo ""
        echo "[concept_spaces.$name]"
        echo "qdrant_url = \"http://qdrant-${name}:6334\""
        echo "collection = \"$name\""
        echo ""
        echo "[concept_spaces.${name}.embedder]"
        if [ "$embedder_type" = "api" ]; then
            echo "type = \"api\""
            echo "url = \"$api_url\""
            echo "model = \"$model\""
            echo "dimension = $dimension"
            [ -n "$api_key_env" ] && echo "api_key_env = \"$api_key_env\""
        elif [ "$embedder_type" = "ollama" ]; then
            echo "type = \"ollama\""
            echo "model = \"$model\""
            echo "dimension = $dimension"
            [ -n "$ollama_url" ] && echo "url = \"$ollama_url\""
        else
            echo "type = \"local\""
            echo "model = \"$model\""
            echo "dimension = $dimension"
        fi
    } >> "$SCRIPT_DIR/ape.toml"
    ok "Updated ape.toml"

    echo ""
    echo -e "  ${C}Concept-space '$name' is ready.${N}"
    echo -e "  Qdrant will be available at localhost:${port} (host) / qdrant-${name}:6334 (docker)"
    echo ""
    echo -e "  ${Y}Next:${N} ./ape.sh restart"
}

new_concept_interactive() {
    hdr "New Concept-Space"
    echo ""
    echo "  A concept-space is an isolated knowledge domain with its own"
    echo "  Qdrant instance and embedding model."
    echo ""

    # Step 1: Name
    local name=""
    while true; do
        read -rp "  Name (lowercase, e.g. 'human-resources'): " name
        validate_concept_name "$name" && break
    done

    # Step 2: Embedder type
    echo ""
    echo "  Embedder type:"
    echo "    1) Local (ONNX, runs on CPU, no API key needed)  [default]"
    echo "    2) Ollama (local LLM server — must be running)"
    echo "    3) API (OpenAI-compatible endpoint)"
    echo ""
    local embedder_choice
    read -rp "  Pick [1]: " embedder_choice
    embedder_choice="${embedder_choice:-1}"

    local embedder_type model dimension api_url="" api_key_env="" ollama_url=""

    if [ "$embedder_choice" = "3" ]; then
        embedder_type="api"

        echo ""
        read -rp "  API endpoint URL (e.g. https://api.openai.com/v1/embeddings): " api_url
        read -rp "  Model name (e.g. text-embedding-3-small): " model
        read -rp "  Vector dimension (e.g. 1536): " dimension
        read -rp "  Env var for API key (e.g. OPENAI_API_KEY, or blank for none): " api_key_env

        if [ -z "$api_url" ] || [ -z "$model" ] || [ -z "$dimension" ]; then
            err "URL, model, and dimension are required."; return 1
        fi
    elif [ "$embedder_choice" = "2" ]; then
        embedder_type="ollama"

        echo ""
        echo "  Ollama embedding models (must be pulled first: ollama pull <model>):"
        echo "    1) nomic-embed-text    (768-dim, general purpose)  [default]"
        echo "    2) mxbai-embed-large   (1024-dim, high quality)"
        echo "    3) all-minilm          (384-dim, lightweight)"
        echo "    4) snowflake-arctic-embed (1024-dim, retrieval-optimized)"
        echo "    5) Custom (enter model name + dimension)"
        echo ""
        local model_choice
        read -rp "  Pick [1]: " model_choice
        model_choice="${model_choice:-1}"

        case "$model_choice" in
            1) model="nomic-embed-text";        dimension=768 ;;
            2) model="mxbai-embed-large";       dimension=1024 ;;
            3) model="all-minilm";              dimension=384 ;;
            4) model="snowflake-arctic-embed";  dimension=1024 ;;
            5)
                read -rp "  Model name: " model
                read -rp "  Dimension: " dimension
                if [ -z "$model" ] || [ -z "$dimension" ]; then
                    err "Model and dimension are required."; return 1
                fi
                ;;
            *) model="nomic-embed-text"; dimension=768 ;;
        esac

        local default_ollama="http://host.docker.internal:11434"
        echo ""
        read -rp "  Ollama URL [$default_ollama]: " ollama_url
        ollama_url="${ollama_url:-$default_ollama}"
    else
        embedder_type="local"

        echo ""
        echo "  Local embedding model:"
        echo "    1) jina-embeddings-v2-base-code  (768-dim, code-optimized)  [default]"
        echo "    2) jina-embeddings-v2-base-en    (768-dim, general English)"
        echo "    3) bge-base-en-v1.5              (768-dim, general English)"
        echo "    4) all-MiniLM-L6-v2              (384-dim, lightweight)"
        echo "    5) bge-small-en-v1.5             (384-dim, lightweight)"
        echo ""
        local model_choice
        read -rp "  Pick [1]: " model_choice
        model_choice="${model_choice:-1}"

        case "$model_choice" in
            1) model="jina-embeddings-v2-base-code"; dimension=768 ;;
            2) model="jina-embeddings-v2-base-en";   dimension=768 ;;
            3) model="bge-base-en-v1.5";             dimension=768 ;;
            4) model="all-MiniLM-L6-v2";             dimension=384 ;;
            5) model="bge-small-en-v1.5";            dimension=384 ;;
            *) model="jina-embeddings-v2-base-code"; dimension=768 ;;
        esac
    fi

    # Summary
    echo ""
    hdr "Summary"
    echo ""
    echo "    Name:      $name"
    echo "    Embedder:  $embedder_type ($model, ${dimension}d)"
    local port
    port=$(next_qdrant_port)
    echo "    Qdrant:    qdrant-$name (port $port)"
    echo ""
    read -rp "  Create? (Y/n): " confirm
    if [[ "$(lower "$confirm")" == "n" ]]; then
        echo "  Cancelled."; return 0
    fi

    echo ""
    create_concept "$name" "$embedder_type" "$model" "$dimension" "$api_url" "$api_key_env" "$ollama_url"
}

new_concept() {
    local name="" embedder_type="" model="" dimension="" api_url="" api_key_env="" ollama_url=""

    # Parse flags
    while [ $# -gt 0 ]; do
        case "$1" in
            --embedder-type) embedder_type="$2"; shift 2 ;;
            --model)         model="$2"; shift 2 ;;
            --dimension)     dimension="$2"; shift 2 ;;
            --api-url)       api_url="$2"; shift 2 ;;
            --api-key-env)   api_key_env="$2"; shift 2 ;;
            --ollama-url)    ollama_url="$2"; shift 2 ;;
            -*)              err "Unknown flag: $1"; return 1 ;;
            *)               name="$1"; shift ;;
        esac
    done

    # No name → interactive
    if [ -z "$name" ]; then
        new_concept_interactive
        return
    fi

    validate_concept_name "$name" || return 1

    # Fill defaults
    embedder_type="${embedder_type:-local}"
    if [ "$embedder_type" = "local" ]; then
        model="${model:-jina-embeddings-v2-base-code}"
        dimension="${dimension:-768}"
    elif [ "$embedder_type" = "ollama" ]; then
        model="${model:-nomic-embed-text}"
        dimension="${dimension:-768}"
        ollama_url="${ollama_url:-http://host.docker.internal:11434}"
    else
        if [ -z "$model" ] || [ -z "$dimension" ] || [ -z "$api_url" ]; then
            err "API embedder requires: --model, --dimension, --api-url"
            return 1
        fi
    fi

    create_concept "$name" "$embedder_type" "$model" "$dimension" "$api_url" "$api_key_env" "$ollama_url"
}

do_new() {
    if [ $# -eq 0 ]; then
        # Interactive: what to create?
        if [ ! -f "$SCRIPT_DIR/ape.toml" ]; then
            # No install detected — bootstrap
            hdr "Welcome to APE setup"
            echo ""
            echo "  No ape.toml found. Let's set up your installation."
            ensure_ape_toml
            echo ""
            echo "  Your default concept-space is ready."
            echo ""
            read -rp "  Create an additional concept-space now? (y/N): " more
            if [[ "$(lower "$more")" == "y" ]]; then
                new_concept_interactive
            fi
            return
        fi

        hdr "Create new..."
        echo ""
        echo "  1) Concept-space  - New Qdrant instance + embedder"
        echo "  2) Collection     - New collection in existing space (coming soon)"
        echo "  3) Domain         - New knowledge domain (coming soon)"
        echo ""
        local choice
        read -rp "  Pick: " choice
        case "$choice" in
            1) new_concept_interactive ;;
            2) warn "Collection management is coming soon." ;;
            3) warn "Domain management is coming soon." ;;
            *) warn "Not a valid option." ;;
        esac
    else
        case "$(lower "${1:-}")" in
            concept|concept-space) shift; new_concept "$@" ;;
            *) err "Unknown: $1. Try: ape new concept <name>" ;;
        esac
    fi
}

do_list() {
    hdr "Concept-Spaces"
    echo ""

    if [ ! -f "$SCRIPT_DIR/ape.toml" ]; then
        warn "No ape.toml found. Run 'ape new' to set up."
        return
    fi

    printf "  ${B}%-20s %-10s %-35s %5s  %s${N}\n" "NAME" "EMBEDDER" "MODEL" "DIM" "QDRANT"
    printf "  %-20s %-10s %-35s %5s  %s\n" "----" "--------" "-----" "---" "------"

    local current_space="" space_url="" space_collection=""
    local emb_type="" emb_model="" emb_dim=""

    while IFS= read -r line; do
        # Detect concept-space section
        if echo "$line" | grep -qE '^\[concept_spaces\.([a-z0-9-]+)\]$'; then
            # Print previous space if we have one
            if [ -n "$current_space" ]; then
                printf "  %-20s %-10s %-35s %5s  %s\n" \
                    "$current_space" "$emb_type" "$emb_model" "$emb_dim" "$space_url"
            fi
            current_space=$(echo "$line" | sed 's/\[concept_spaces\.\(.*\)\]/\1/')
            space_url="" ; space_collection="" ; emb_type="" ; emb_model="" ; emb_dim=""
            continue
        fi

        # Skip embedder sub-sections (already captured by key parsing)
        echo "$line" | grep -qE '^\[concept_spaces\.' && continue

        # Parse key-value pairs within a concept-space
        if [ -n "$current_space" ]; then
            case "$line" in
                qdrant_url*) space_url=$(echo "$line" | sed 's/.*= *"\(.*\)"/\1/') ;;
                type*)       emb_type=$(echo "$line" | sed 's/.*= *"\(.*\)"/\1/') ;;
                model*=*)    emb_model=$(echo "$line" | sed 's/.*= *"\(.*\)"/\1/') ;;
                dimension*)  emb_dim=$(echo "$line" | sed 's/.*= *\([0-9]*\)/\1/') ;;
            esac
        fi
    done < "$SCRIPT_DIR/ape.toml"

    # Print last space
    if [ -n "$current_space" ]; then
        printf "  %-20s %-10s %-35s %5s  %s\n" \
            "$current_space" "$emb_type" "$emb_model" "$emb_dim" "$space_url"
    fi

    echo ""
}

# ==========================================================================
# Menu
# ==========================================================================

show_menu() {
    echo ""
    echo -e "  ${B}============================================${N}"
    echo -e "  ${B}  Atomic Pumpkin${N}"
    echo -e "  ${B}============================================${N}"
    echo ""
    echo "  1) Start          - Start everything"
    echo "  2) Stop           - Stop (keeps your data)"
    echo "  3) Restart        - Stop + Start"
    echo "  4) Update         - Download latest + restart"
    echo "  5) Logs           - Watch what's happening"
    echo "  6) Status         - What's running right now?"
    echo "  7) New            - Create concept-space / collection / domain"
    echo "  8) List           - Show concept-spaces"
    echo "  0) Exit"
    echo ""
}

# ==========================================================================
# Main
# ==========================================================================

# CLI mode: ape.sh start, ape.sh stop, etc.
if [ $# -gt 0 ]; then
    case "$(lower "${1:-}")" in
        start)   check_deps; do_start ;;
        stop)    do_stop ;;
        restart) check_deps; do_restart ;;
        update)  check_deps; do_update ;;
        logs)    do_logs ;;
        status)  do_status ;;
        new)     shift; do_new "$@" ;;
        ls|list) do_list ;;
        *)       echo "Unknown command: $1"; exit 1 ;;
    esac
    exit $?
fi

# Interactive mode
check_deps

while true; do
    show_menu
    read -rp "  Pick a number: " choice
    case "$choice" in
        1) do_start ;;
        2) do_stop ;;
        3) do_restart ;;
        4) do_update ;;
        5) do_logs ;;
        6) do_status ;;
        7) do_new ;;
        8) do_list ;;
        0) echo "  Bye!"; echo ""; exit 0 ;;
        *) warn "Not a valid option. Try a number 0-8." ;;
    esac
    echo ""
    read -rp "  Press Enter to go back to the menu..." _
done
