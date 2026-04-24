# Code Thumbs Addon

**Multi-language code formatting, linting, and auto-fixing tools for APE.**

This addon pulls pre-built images from [code-thumbs](https://github.com/real-wimpsquad/code-thumbs) - a standalone project that provides HTTP API for formatting, linting, and fixing code across 17+ languages.

## 🚀 Quick Start

Add code-thumbs to your stack using the ADDONS parameter:

```bash
# From APE root directory
make ADDONS="code-thumbs"                    # Production (pre-built :stable images)
make dev ADDONS="code-thumbs"                # Development (pre-built :latest images)
make ADDONS="apechat ollama code-thumbs"     # Full stack
```

**Status Check:**
```bash
docker ps | grep code_thumbs
curl http://localhost:8072/health
```

## 📦 Images

This addon uses **pre-built images** from GitHub Container Registry:

- `ghcr.io/real-wimpsquad/code-thumbs:stable` (production)
- `ghcr.io/real-wimpsquad/code-thumbs:latest` (development)
- `ghcr.io/real-wimpsquad/code-thumbs-api:stable` (production)
- `ghcr.io/real-wimpsquad/code-thumbs-api:latest` (development)

No local building required - images are pulled automatically. The APE project root (`../..`) is mounted to `/workspace` in the containers for file operations.

## 📚 API Overview

**Base URL:** `http://localhost:8072`

**Interactive Docs:** http://localhost:8072/docs (Swagger UI)

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/languages` | GET | List supported languages and available tools |
| `/format` | POST | Format code content (in-memory) |
| `/lint` | POST | Lint code content and return structured issues |
| `/fix` | POST | Auto-fix code content issues |
| `/check` | POST | Combined format + lint check (in-memory) |
| `/format/file` | POST | **Format file by path** (read + format + write) |
| `/lint/file` | POST | **Lint file by path** |
| `/fix/file` | POST | **Fix file by path** (read + fix + write) |
| `/check/file` | POST | **Check file by path** (format + lint) |
| `/batch/format` | POST | Format multiple code contents |
| `/batch/lint` | POST | Lint multiple code contents |
| `/batch/fix` | POST | Fix multiple code contents |
| `/batch/format/files` | POST | **Format multiple files by paths** |
| `/batch/lint/files` | POST | **Lint multiple files by paths** |
| `/batch/fix/files` | POST | **Fix multiple files by paths** |
| `/tools/openai` | GET | OpenAI function calling schemas |

### Example Usage

**Format Python code:**
```bash
curl -X POST http://localhost:8072/format \
  -H "Content-Type: application/json" \
  -d '{
    "language": "python",
    "content": "def foo(  x,y  ):\n  return x+y"
  }'
```

**Response:**
```json
{
  "result": "tool:ruff|changed:yes\n\ndef foo(x, y):\n    return x + y\n"
}
```

**Lint TypeScript:**
```bash
curl -X POST http://localhost:8072/lint \
  -H "Content-Type: application/json" \
  -d '{
    "language": "typescript",
    "content": "const x = 5;\nconst y = 10;"
  }'
```

**Combined check (format + lint):**
```bash
curl -X POST http://localhost:8072/check \
  -H "Content-Type: application/json" \
  -d '{
    "language": "python",
    "content": "import os\n\ndef foo():\n  pass"
  }'
```

## 🛠️ Supported Languages

Code Thumbs supports **17 languages** with multiple tools per language:

| Language | Extensions | Format Tools | Lint Tools | Fix Tools |
|----------|-----------|--------------|------------|-----------|
| **Python** | `.py` | ruff, black | ruff, pylint, mypy | ruff |
| **JavaScript** | `.js`, `.jsx`, `.mjs` | prettier | eslint | eslint |
| **TypeScript** | `.ts`, `.tsx` | prettier | eslint, tsc | eslint |
| **Go** | `.go` | gofmt, goimports | golangci-lint | golangci-lint |
| **Rust** | `.rs` | rustfmt, cargo-fmt | cargo-clippy | - |
| **C** | `.c`, `.h` | clang-format | clang-tidy | - |
| **C++** | `.cpp`, `.hpp`, `.cc` | clang-format | clang-tidy | - |
| **C#** | `.cs` | csharpier, dotnet-format | dotnet-format | - |
| **Java** | `.java` | google-java-format | checkstyle | - |
| **Kotlin** | `.kt`, `.kts` | ktlint | ktlint | ktlint |
| **Swift** | `.swift` | swiftformat | - | - |
| **PHP** | `.php` | php-cs-fixer | phpstan | php-cs-fixer |
| **Ruby** | `.rb` | rubocop | rubocop | rubocop |
| **Shell** | `.sh`, `.bash` | shfmt | shellcheck | - |
| **SQL** | `.sql` | sqlfluff | sqlfluff | sqlfluff |
| **Markdown** | `.md` | prettier | markdownlint | markdownlint |
| **YAML** | `.yaml`, `.yml` | prettier | yamllint | - |

## 🤖 For AI Agents

**Tool discovery:** `GET http://localhost:8072/tools` → compressed ml-exclusive format

### When to Use

✅ **Use:** writing_code|modifying_code|ensure_formatting|catch_issues|user_requests_quality
❌ **Skip:** trivial_1line|unsupported_lang|time_sensitive_ops

### Quick Reference

**Workflow:** `POST/format/file{path}→read+fmt+write_atomic` (1 call, auto-detect lang)

**Paths:** Relative to APE root (e.g., `src/api_server.py`, not `/workspace/src/api_server.py`)

```bash
# Recommended: Atomic file operations
POST /format/file {"path":"src/main.py"}           # → tool:ruff|changed:yes\n\n{code}
POST /lint/file {"path":"src/utils.ts"}            # → path:...|tool:eslint|err:3|warn:5\n...
POST /fix/file {"path":"src/app.py"}               # → tool:ruff|fixed:yes|remaining:0\n\n{code}
POST /batch/format/files {"paths":["a.py","b.py"]} # → a.py|tool:ruff|changed:yes\n---\nb.py|...

# Legacy: Content-based (avoid - requires Read→POST→parse→Write)
POST /format {"language":"python","content":"..."}  # → tool:ruff|changed:yes\n\n{code}
POST /check {"language":"typescript","content":"..."} # → fmt:clean|lint:err:2+warn:1\n...
```

**Pattern:** `file_ops→1_step_atomic` > `content_ops→5_step_dance`
**Discovery:** `GET/tools→compressed_specs` | `GET/tools/openai→verbose_schemas`
**Health:** `GET/health→{status,tools:{ruff:available,...}}`

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│  APE Stack                          │
│                                     │
│  ┌───────────────┐  ┌─────────────┐│
│  │ Code Thumbs   │  │ Code Thumbs ││
│  │ Container     │◄─┤ API         ││
│  │ (Tools)       │  │ (HTTP)      ││
│  └───────────────┘  └─────┬───────┘│
│                           │         │
│                      Port 8072      │
└────────────────────────────┼────────┘
                             │
                   ┌─────────▼─────────┐
                   │ AI Agents         │
                   │ Users             │
                   │ IDEs              │
                   └───────────────────┘
```

## 🔧 Configuration

### Environment Variables

```bash
CODE_THUMBS_PORT=8072  # API port (default: 8072)
```

### Docker Compose Files

- **Dev:** `addons/code-thumbs/docker-compose.code-thumbs.yml`
- **Prod:** `addons/code-thumbs/docker-compose.code-thumbs.prod.yml`

### Volumes

The API has access to the entire workspace via `/workspace` mount.

## 📖 Additional Resources

- **OpenAPI Schema:** http://localhost:8072/openapi.json
- **Swagger UI:** http://localhost:8072/docs
- **ReDoc:** http://localhost:8072/redoc
- **Upstream Repo:** https://github.com/real-wimpsquad/code-thumbs

## 🧪 Testing

```bash
# Health check
curl http://localhost:8072/health

# List supported languages
curl http://localhost:8072/languages | python3 -m json.tool

# Format sample Python code
curl -X POST http://localhost:8072/format \
  -H "Content-Type: application/json" \
  -d '{"language":"python","content":"def foo(x,y): return x+y"}'

# Lint JavaScript
curl -X POST http://localhost:8072/lint \
  -H "Content-Type: application/json" \
  -d '{"language":"javascript","content":"const x = 5"}'
```

## 📝 Notes

- **Container Access:** The API executes formatting/linting tools inside the `ape_code_thumbs` container
- **State:** Stateless HTTP API - no session management required
- **Performance:** Tools run in isolated container, no interference with main services
- **Availability:** Runs alongside main stack, check health before use
