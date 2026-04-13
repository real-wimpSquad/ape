# Atomic Pumpkin v11

**Working towards a manageable, robust, persistent memory substrate for agentic LLM users with enterprise in mind.**

*Patent Pending*

Atomic Pumpkin gives stateless AI agents persistent, shared memory. Agents inherit collective knowledge across context resets and contribute back what they learn. Hybrid vector + graph engine with MCP support.

## Setup

**Windows:** Double-click `ape.bat`

**Linux / Mac:**
```
bash ape.sh
```

Both check for Docker and walk you through installing it if needed.

## Day-to-Day

Run `ape.bat` (Windows) or `bash ape.sh` (Linux/Mac) and pick from the menu:

```
1) Start          - Start everything
2) Stop           - Stop (keeps your data)
3) Restart        - Stop + Start
4) Update         - Download latest + restart
5) Logs           - Watch what's happening
6) Status         - What's running right now?
7) New            - Create concept-space / collection / domain
8) List           - Show concept-spaces
0) Exit
```

Or from the command line: `ape.sh start`, `ape.sh stop`, `ape.sh update`, `ape.sh new`, `ape.sh ls`, etc.

## Concept-Spaces

A concept-space is an isolated knowledge domain with its own Qdrant instance and embedding model. Your installation starts with a `default` space. Add more as needed:

```bash
# Interactive wizard (walks you through it)
bash ape.sh new

# Direct
bash ape.sh new concept human-resources

# With an API embedder (OpenAI, Cohere, etc.)
bash ape.sh new concept research --embedder-type api --model text-embedding-3-small \
  --dimension 1536 --api-url https://api.openai.com/v1/embeddings --api-key-env OPENAI_API_KEY

# See what you have
bash ape.sh ls
```

Each concept-space gets its own Qdrant instance, automatically configured and composed into your deployment.

## Connecting to it

Once running:

| What | Where |
|------|-------|
| Gateway (auth, settings, LLM proxy) | http://localhost:8070 |
| MCP (StreamableHTTP) | http://localhost:50051/mcp |
| MCP (dedicated port) | http://localhost:8071/mcp |

### Claude Code

Add to your MCP server config:
```json
{
  "url": "http://<this-machine's-ip>:50051/mcp"
}
```

### Other MCP clients

Point any MCP-compatible client at `http://<ip>:8071/mcp` (dedicated MCP port) or `http://<ip>:50051/mcp` (bridge port).

## Configuration

**Quick start:** Copy `.env.example` to `.env` and fill in your API keys. At minimum you need:

- `LITELLM_MASTER_KEY` — any string, used internally
- `JWT_SECRET` — any string, used for auth tokens
- At least one LLM provider key (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, or `GEMINI_API_KEY`)

**Advanced:** APE uses `ape.toml` for structured configuration (auto-generated on first start, or copy `ape.example.toml`). This is where concept-spaces, embedders, and service endpoints are defined.

Restart after changes.

## What's in the box

- **ape-graph** — Rust engine: semantic search, knowledge graph, MCP server, auth gateway, LLM proxy
- **Qdrant** — Vector database + graph edge storage (one instance per concept-space)
- **LiteLLM** — Unified LLM provider routing
- **Redis** — Context stash (per-session, 24h TTL)
- **Postgres** — Auth, settings, pattern storage

## License

Apache 2.0
