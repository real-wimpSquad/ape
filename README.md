# APE — Agent Persistence Exocortex

**A persistent, queryable memory substrate for AI agents. Self-hosted. Hybrid vector + graph. MCP-native.**

*Patent Pending*

APE gives stateless LLM agents persistent, shared memory they can carry across sessions, models, and vendors. Prose goes in, gets translated into *glyph* — a dense operator notation — and stored as a graph. Agents query it back in under a second and stop starting from scratch.

## What makes it different

- **Glyph, not JSON.** Internal format is pipe-delimited operator notation. Denser than JSON, and readable cold by any LLM that's seen math, logic, or set theory — no model-specific training required.
- **Self-teaching translator.** The L1→L2→L3 apeifier writes new regex patterns back to its own database every time a heavy model corrects a light one. The longer you run it, the less it costs.
- **Graph-aware search.** Every query is semantic + structural in one pass. Vector hits expand through the graph by tier-priority, depth, or breadth — no post-hoc re-ranking.
- **Tier-weighted voting.** Entries can be voted up or down, but your vote's weight is set by the quality of your *reason*, not your identity.

## Setup

**Windows:** Double-click `ape.bat`

**Linux / Mac:**
```
bash ape.sh
```

Both check for Docker and walk you through installing it if needed.

## Day-to-day

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

## Concept-spaces

A concept-space is an isolated knowledge domain with its own Qdrant collection and embedder. Your installation starts with a `default` space. Add more as needed:

```bash
# Interactive wizard
bash ape.sh new

# Direct
bash ape.sh new concept human-resources

# With an API embedder (OpenAI, Cohere, etc.)
bash ape.sh new concept research --embedder-type api --model text-embedding-3-small \
  --dimension 1536 --api-url https://api.openai.com/v1/embeddings --api-key-env OPENAI_API_KEY

# See what you have
bash ape.sh ls
```

Each space is automatically configured and composed into your deployment.

## Connecting to it

APE binds to `127.0.0.1:8070`. Point your preferred ingress (nginx, Caddy, Traefik, Cloudflare Tunnel, k8s, etc.) at it. For zero-config bundled TLS, enable the Caddy addon:

```bash
make ADDONS="caddy"
```

| What | Where |
|------|-------|
| Gateway (auth, settings, LLM proxy) | `http://<host>:8070/` |
| MCP (Streamable HTTP) | `http://<host>:8070/mcp` |
| Health | `http://<host>:8070/health` |

### Claude Code

Add to your MCP server config:

```json
{
  "url": "http://<host>:8070/mcp"
}
```

### Other MCP clients

Point any MCP-compatible client at `http://<host>:8070/mcp`.

## Configuration

**Quick start:** Copy `.env.example` to `.env` and fill in your API keys. At minimum, one LLM provider key:

- `ANTHROPIC_API_KEY` and/or `OPENAI_API_KEY`

Everything else auto-bootstraps from the database on first run and is editable via the Admin UI.

**Advanced:** APE reads `ape.toml` for structured configuration (auto-generated on first start, or copy `ape.example.toml`). Concept-spaces, embedders, and service endpoints live here. Restart after changes.

## What's in the box

- **ape** — single Rust binary: gateway (auth, settings, LLM proxy), MCP server, semantic search, knowledge graph, apeifier (the L1→L2→L3 self-teaching translator)
- **Qdrant** — vector index (one collection per concept-space) + graph edge storage
- **Redis** — per-session context stash, cache

Durable state lives on the `ape_data` volume as SQLite — graph nodes, edges, corpus records, auth, and config all in one file.

## Docs

[apecortex.com](https://apecortex.com) — architecture, glyph primer, operator reference.

## License

Apache 2.0
