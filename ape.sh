#!/usr/bin/env bash
set -euo pipefail

# ==========================================================================
# APE — launcher
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
    if [ -f "$SCRIPT_DIR/ape.example.toml" ]; then
        cp "$SCRIPT_DIR/ape.example.toml" "$SCRIPT_DIR/ape.toml"
        ok "Created ape.toml from ape.example.toml."
    else
        err "ape.example.toml is missing — re-clone the repo."
        return 1
    fi
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
    echo "docker compose $files"
}

do_start() {
    ensure_ape_toml
    hdr "Starting APE..."
    echo ""
    local cmd first_boot=0
    [ ! -f "$SCRIPT_DIR/data/ape.db" ] && first_boot=1
    cmd=$(compose_cmd)
    if $cmd up -d; then
        echo ""
        ok "Everything is running!"
        echo ""
        echo "    APE:     http://localhost:8070"
        echo ""
        if [ "$first_boot" = "1" ]; then
            echo "  First boot detected. To finish setup:"
            echo "    1. Open http://localhost:8070 in a browser."
            echo "    2. Grab the one-time setup token printed in the logs"
            echo "       (or read it from data/setup-token)."
            echo "    3. Create the admin account, add an API key,"
            echo "       and configure your first concept-space — all in the UI."
            echo ""
            echo "  Tail the token:  ./ape.sh logs | grep -m1 setup-token"
        else
            echo "  Settings live in the web UI: http://localhost:8070/settings"
        fi
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
# Concept-space management — moved to the web UI
# ==========================================================================
# APE is DB-first. Concept-spaces, embedders, providers, and API keys are
# all created and edited at http://localhost:8070/settings. The wizard that
# used to write TOML fragments here is gone — those fragments are ignored
# by the runtime now.

do_concept_redirect() {
    hdr "Concept-spaces are now managed in the web UI"
    echo ""
    echo "  Open:    http://localhost:8070/settings"
    echo "  Path:    Settings → Concept-Spaces"
    echo ""
    echo "  Not started yet?  ./ape.sh start"
    echo ""
}

# ==========================================================================
# Backup & Restore
# ==========================================================================

BACKUP_DIR="$SCRIPT_DIR/backups"
BACKUP_VERSION="1"

do_backup() {
    local cron_mode=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --cron) cron_mode=1; shift ;;
            *) shift ;;
        esac
    done

    hdr "Backup"
    echo ""

    # Verify services are running (we need the container for SQLite copy)
    if ! docker ps --format '{{.Names}}' | grep -q '^ape$'; then
        err "APE container is not running. Start it first: ./ape.sh start"
        return 1
    fi

    local timestamp
    timestamp=$(date -u +%Y%m%d-%H%M%S)
    local backup_name="ape-backup-${timestamp}"
    local tmpdir
    tmpdir=$(mktemp -d)
    local workdir="$tmpdir/$backup_name"
    mkdir -p "$workdir"

    # --- 1. SQLite database ---
    echo -n "  Copying SQLite database... "
    if docker cp ape:/app/data/. "$workdir/data/" 2>/dev/null; then
        ok "done"
    else
        err "failed to copy SQLite data"
        rm -rf "$tmpdir"
        return 1
    fi

    # --- 2. Qdrant data ---
    # Qdrant uses a bind mount at ./qdrant/ — snapshot via API if reachable,
    # otherwise direct directory copy.
    echo -n "  Snapshotting Qdrant... "
    local qdrant_api=""

    # Try host-exposed ports first (dev mode)
    if curl -sf "http://localhost:6334/collections" &>/dev/null; then
        qdrant_api="http://localhost:6334"
    elif curl -sf "http://localhost:6333/collections" &>/dev/null; then
        qdrant_api="http://localhost:6333"
    fi

    mkdir -p "$workdir/qdrant"
    if [ -n "$qdrant_api" ]; then
        # API-based snapshot (consistent while running)
        local collections
        collections=$(curl -sf "$qdrant_api/collections" | sed -n 's/.*"name":"\([^"]*\)".*/\1/gp' | tr ',' '\n' | sort -u)
        local snap_ok=1
        for coll in $collections; do
            local snap_resp
            snap_resp=$(curl -sf -X POST "$qdrant_api/collections/$coll/snapshots" 2>/dev/null)
            local snap_name
            snap_name=$(echo "$snap_resp" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
            if [ -n "$snap_name" ]; then
                curl -sf "$qdrant_api/collections/$coll/snapshots/$snap_name" \
                    -o "$workdir/qdrant/${coll}.snapshot" 2>/dev/null || snap_ok=0
                # Clean up snapshot on server
                curl -sf -X DELETE "$qdrant_api/collections/$coll/snapshots/$snap_name" &>/dev/null
            else
                snap_ok=0
            fi
        done
        if [ "$snap_ok" = "1" ] && [ -n "$collections" ]; then
            ok "done (API snapshot, $(echo "$collections" | wc -w | tr -d ' ') collections)"
        else
            warn "API snapshot partial — falling back to directory copy"
            rm -rf "$workdir/qdrant"
            if [ -d "$SCRIPT_DIR/qdrant" ]; then
                cp -r "$SCRIPT_DIR/qdrant" "$workdir/qdrant"
                ok "done (directory copy)"
            else
                warn "no Qdrant data directory found"
            fi
        fi
    elif [ -d "$SCRIPT_DIR/qdrant" ]; then
        # Direct copy fallback (Qdrant ports not exposed — production mode)
        cp -r "$SCRIPT_DIR/qdrant" "$workdir/qdrant"
        ok "done (directory copy)"
    else
        warn "no Qdrant data found — skipping"
    fi

    # --- 3. Config ---
    echo -n "  Copying configuration... "
    if [ -f "$SCRIPT_DIR/ape.toml" ]; then
        cp "$SCRIPT_DIR/ape.toml" "$workdir/ape.toml"
        ok "done"
    else
        warn "no ape.toml found"
    fi

    # --- 4. Encryption key export ---
    echo -n "  Exporting encryption key... "
    local key_exported=0
    local raw_key=""

    # Extract key from the copied SQLite DB
    if command -v sqlite3 &>/dev/null; then
        raw_key=$(sqlite3 "$workdir/data/ape.db" \
            "SELECT value FROM ape_settings WHERE key = 'encryption_key';" 2>/dev/null || true)
    fi

    if [ -n "$raw_key" ]; then
        if [ "$cron_mode" = "1" ]; then
            # Cron mode: store key as-is (the whole archive should be on encrypted storage)
            echo "$raw_key" > "$workdir/encryption_key.txt"
            ok "done (unencrypted — cron mode)"
            key_exported=1
        else
            # Interactive: encrypt with operator passphrase
            echo ""
            echo ""
            echo -e "  ${Y}The encryption key protects API keys and OAuth tokens.${N}"
            echo -e "  ${Y}Enter a passphrase to protect this key in the backup.${N}"
            echo ""
            local passphrase=""
            local confirm=""
            while true; do
                read -rsp "  Passphrase: " passphrase; echo ""
                if [ -z "$passphrase" ]; then
                    warn "Empty passphrase — storing key unencrypted"
                    echo "$raw_key" > "$workdir/encryption_key.txt"
                    key_exported=1
                    break
                fi
                read -rsp "  Confirm:    " confirm; echo ""
                if [ "$passphrase" = "$confirm" ]; then
                    echo "$raw_key" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
                        -pass "pass:$passphrase" -out "$workdir/encryption_key.enc" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        ok "done (AES-256-CBC encrypted)"
                        key_exported=1
                    else
                        err "openssl encryption failed — storing unencrypted"
                        echo "$raw_key" > "$workdir/encryption_key.txt"
                        key_exported=1
                    fi
                    break
                else
                    warn "Passphrases don't match. Try again."
                fi
            done
        fi
    else
        warn "could not extract encryption key (sqlite3 not available or key not found)"
        echo "  The key is still inside ape.db — a full restore will recover it."
    fi

    # --- 5. Manifest ---
    local ape_version
    ape_version=$(curl -sf "http://localhost:8070/health" 2>/dev/null | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' || echo "unknown")
    local db_size
    db_size=$(du -sh "$workdir/data/ape.db" 2>/dev/null | cut -f1 || echo "unknown")
    local qdrant_size
    qdrant_size=$(du -sh "$workdir/qdrant" 2>/dev/null | cut -f1 || echo "unknown")

    cat > "$workdir/manifest.json" <<EOF
{
  "backup_version": "$BACKUP_VERSION",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "ape_version": "$ape_version",
  "contents": {
    "sqlite": true,
    "qdrant": $([ -d "$workdir/qdrant" ] && echo "true" || echo "false"),
    "config": $([ -f "$workdir/ape.toml" ] && echo "true" || echo "false"),
    "encryption_key": $key_exported
  },
  "sizes": {
    "sqlite": "$db_size",
    "qdrant": "$qdrant_size"
  }
}
EOF

    # --- 6. Package ---
    echo -n "  Creating archive... "
    mkdir -p "$BACKUP_DIR"
    local archive="$BACKUP_DIR/${backup_name}.tar.gz"
    tar -czf "$archive" -C "$tmpdir" "$backup_name" 2>/dev/null
    rm -rf "$tmpdir"

    local archive_size
    archive_size=$(du -sh "$archive" 2>/dev/null | cut -f1 || echo "unknown")
    ok "done"

    # --- 7. Retention (cron mode only) ---
    if [ "$cron_mode" = "1" ]; then
        local deleted=0
        while IFS= read -r old_backup; do
            [ -f "$old_backup" ] || continue
            rm -f "$old_backup"
            ((deleted++))
        done < <(find "$BACKUP_DIR" -name "ape-backup-*.tar.gz" -mtime +30 2>/dev/null)
        if [ "$deleted" -gt 0 ]; then
            ok "Pruned $deleted backups older than 30 days"
        fi
    fi

    # --- 8. Write last-backup metadata (for UI) ---
    # Persist to SQLite via the container so the admin dashboard can show backup status
    local backup_ts
    backup_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local backup_file
    backup_file=$(basename "$archive")
    docker exec ape sqlite3 /app/data/ape.db "
        INSERT INTO ape_settings (key, value, encrypted, updated_at)
        VALUES ('last_backup_timestamp', '$backup_ts', 0, datetime('now'))
        ON CONFLICT (key) DO UPDATE SET value = '$backup_ts', updated_at = datetime('now');
        INSERT INTO ape_settings (key, value, encrypted, updated_at)
        VALUES ('last_backup_size', '$archive_size', 0, datetime('now'))
        ON CONFLICT (key) DO UPDATE SET value = '$archive_size', updated_at = datetime('now');
        INSERT INTO ape_settings (key, value, encrypted, updated_at)
        VALUES ('last_backup_file', '$backup_file', 0, datetime('now'))
        ON CONFLICT (key) DO UPDATE SET value = '$backup_file', updated_at = datetime('now');
    " 2>/dev/null || true

    echo ""
    echo -e "  ${G}Backup complete!${N}"
    echo ""
    echo "    Archive:  $archive"
    echo "    Size:     $archive_size"
    echo "    Contains: SQLite DB ($db_size) + Qdrant ($qdrant_size) + config"
    if [ "$key_exported" = "1" ]; then
        echo "    Key:      exported ($([ -f "$workdir/encryption_key.enc" ] && echo "encrypted" || echo "plaintext"))"
    else
        echo "    Key:      embedded in ape.db (not separately exported)"
    fi
    echo ""
    echo "  Restore with: ./ape.sh restore $archive"
    echo ""
}

do_restore() {
    local archive="${1:-}"

    if [ -z "$archive" ]; then
        # Try to find most recent backup
        if [ -d "$BACKUP_DIR" ]; then
            archive=$(ls -t "$BACKUP_DIR"/ape-backup-*.tar.gz 2>/dev/null | head -1)
        fi
        if [ -z "$archive" ]; then
            err "Usage: ./ape.sh restore <archive.tar.gz>"
            echo ""
            echo "  No backup archive specified and no backups found in $BACKUP_DIR/"
            return 1
        fi
        echo ""
        warn "No archive specified — using most recent: $(basename "$archive")"
    fi

    if [ ! -f "$archive" ]; then
        err "File not found: $archive"
        return 1
    fi

    hdr "Restore from backup"
    echo ""

    # Extract to temp dir and read manifest
    local tmpdir
    tmpdir=$(mktemp -d)
    tar -xzf "$archive" -C "$tmpdir" 2>/dev/null
    local workdir
    workdir=$(find "$tmpdir" -maxdepth 1 -type d -name "ape-backup-*" | head -1)

    if [ -z "$workdir" ] || [ ! -f "$workdir/manifest.json" ]; then
        err "Invalid backup archive — no manifest found."
        rm -rf "$tmpdir"
        return 1
    fi

    # Show manifest
    echo -e "  ${B}Backup contents:${N}"
    echo ""
    local ts ver
    ts=$(sed -n 's/.*"timestamp": *"\([^"]*\)".*/\1/p' "$workdir/manifest.json")
    ver=$(sed -n 's/.*"ape_version": *"\([^"]*\)".*/\1/p' "$workdir/manifest.json")
    local sq_size qd_size
    sq_size=$(sed -n 's/.*"sqlite": *"\([^"]*\)".*/\1/p' "$workdir/manifest.json")
    qd_size=$(sed -n 's/.*"qdrant": *"\([^"]*\)".*/\1/p' "$workdir/manifest.json")
    echo "    Date:       $ts"
    echo "    APE version: $ver"
    echo "    SQLite:     $sq_size"
    echo "    Qdrant:     $qd_size"
    [ -f "$workdir/ape.toml" ]           && echo "    Config:     ape.toml"
    [ -f "$workdir/encryption_key.enc" ] && echo "    Key:        encrypted (passphrase required)"
    [ -f "$workdir/encryption_key.txt" ] && echo "    Key:        plaintext"
    echo ""

    echo -e "  ${R}WARNING: This will REPLACE all current data.${N}"
    echo ""
    read -rp "  Type 'restore' to confirm: " confirm
    if [ "$confirm" != "restore" ]; then
        echo "  Cancelled."
        rm -rf "$tmpdir"
        return 0
    fi
    echo ""

    # --- Decrypt encryption key if needed ---
    if [ -f "$workdir/encryption_key.enc" ]; then
        echo -n "  Decrypting encryption key... "
        read -rsp "Passphrase: " passphrase; echo ""
        local decrypted_key
        decrypted_key=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
            -pass "pass:$passphrase" -in "$workdir/encryption_key.enc" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "$decrypted_key" ]; then
            err "Wrong passphrase or corrupted key file."
            echo "  The encryption key is also inside the SQLite DB."
            echo "  If you proceed, existing encrypted data will still be accessible"
            echo "  as long as the key in the DB is intact."
            echo ""
            read -rp "  Continue anyway? (y/N): " cont
            if [[ "$(lower "$cont")" != "y" ]]; then
                rm -rf "$tmpdir"
                return 1
            fi
        else
            ok "done"
        fi
    fi

    # --- Stop services ---
    echo -n "  Stopping services... "
    local cmd
    cmd=$(compose_cmd)
    $cmd stop &>/dev/null
    ok "done"

    # --- Restore SQLite ---
    if [ -d "$workdir/data" ]; then
        echo -n "  Restoring SQLite database... "
        # Remove existing data from volume, then copy new
        docker run --rm -v ape_data:/app/data debian:bookworm-slim \
            sh -c "rm -rf /app/data/*" 2>/dev/null
        # Use a temp container to copy data into the volume
        local copy_container
        copy_container=$(docker create -v ape_data:/app/data debian:bookworm-slim true)
        docker cp "$workdir/data/." "$copy_container:/app/data/" 2>/dev/null
        docker rm "$copy_container" &>/dev/null
        ok "done"
    fi

    # --- Restore Qdrant ---
    if [ -d "$workdir/qdrant" ]; then
        echo -n "  Restoring Qdrant data... "

        # Check if backup contains snapshots (API backup) or raw data (directory copy)
        local has_snapshots=0
        ls "$workdir/qdrant/"*.snapshot &>/dev/null && has_snapshots=1

        if [ "$has_snapshots" = "1" ]; then
            # Snapshot-based restore: need Qdrant running
            # Start just Qdrant, restore snapshots, then stop
            warn "snapshot restore requires Qdrant — starting it temporarily"
            $cmd up -d qdrant &>/dev/null
            sleep 3

            local qdrant_api=""
            if curl -sf "http://localhost:6334/collections" &>/dev/null; then
                qdrant_api="http://localhost:6334"
            elif curl -sf "http://localhost:6333/collections" &>/dev/null; then
                qdrant_api="http://localhost:6333"
            fi

            if [ -n "$qdrant_api" ]; then
                for snap_file in "$workdir/qdrant/"*.snapshot; do
                    local coll_name
                    coll_name=$(basename "$snap_file" .snapshot)
                    # Upload snapshot to restore the collection
                    curl -sf -X POST "$qdrant_api/collections/$coll_name/snapshots/upload" \
                        -H "Content-Type: multipart/form-data" \
                        -F "snapshot=@$snap_file" &>/dev/null \
                        && ok "  restored collection: $coll_name" \
                        || warn "  failed to restore collection: $coll_name"
                done
            else
                warn "cannot reach Qdrant API — falling back to directory restore"
                $cmd stop qdrant &>/dev/null
                rm -rf "$SCRIPT_DIR/qdrant"
                cp -r "$workdir/qdrant" "$SCRIPT_DIR/qdrant"
            fi
            $cmd stop qdrant &>/dev/null
        else
            # Directory-based restore
            rm -rf "$SCRIPT_DIR/qdrant"
            cp -r "$workdir/qdrant" "$SCRIPT_DIR/qdrant"
            ok "done (directory restore)"
        fi
    fi

    # --- Restore config ---
    if [ -f "$workdir/ape.toml" ]; then
        echo -n "  Restoring configuration... "
        cp "$workdir/ape.toml" "$SCRIPT_DIR/ape.toml"
        ok "done"
    fi

    # --- Clean up ---
    rm -rf "$tmpdir"

    # --- Restart ---
    echo ""
    read -rp "  Start services now? (Y/n): " start_now
    if [[ "$(lower "$start_now")" != "n" ]]; then
        echo ""
        $cmd up -d
        echo ""
        ok "Restore complete — services starting!"
    else
        echo ""
        ok "Restore complete. Start with: ./ape.sh start"
    fi
    echo ""
}

# ==========================================================================
# Menu
# ==========================================================================

show_menu() {
    echo ""
    echo -e "  ${B}============================================${N}"
    echo -e "  ${B}  APE${N}"
    echo -e "  ${B}============================================${N}"
    echo ""
    echo "  1) Start          - Start everything"
    echo "  2) Stop           - Stop (keeps your data)"
    echo "  3) Restart        - Stop + Start"
    echo "  4) Update         - Download latest + restart"
    echo "  5) Logs           - Watch what's happening"
    echo "  6) Status         - What's running right now?"
    echo "  7) Backup         - Back up all data"
    echo "  0) Exit"
    echo ""
    echo "  Concept-spaces, providers, and API keys live in the web UI:"
    echo "  http://localhost:8070/settings"
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
        new|ls|list|concept|concepts) do_concept_redirect ;;
        backup)  shift; do_backup "$@" ;;
        restore) shift; do_restore "$@" ;;
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
        7) do_backup ;;
        0) echo "  Bye!"; echo ""; exit 0 ;;
        *) warn "Not a valid option. Try a number 0-7." ;;
    esac
    echo ""
    read -rp "  Press Enter to go back to the menu..." _
done
