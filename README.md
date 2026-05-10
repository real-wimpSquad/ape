# APE — Agent Persistence Exocortex

**A persistent, queryable memory substrate for AI agents. Self-hosted. Hybrid vector + graph. MCP-native.** — *Patent Pending*

> APE is in active development. This document tracks `main`, but may lag the code by a release.

APE gives stateless LLM agents persistent, shared memory they can carry across sessions, models, and vendors. Prose goes in, gets translated into *glyph* — a dense operator notation — and stored as a graph. Agents query it back in under a second and stop starting from scratch.

## What makes it different

- **Glyph, not JSON.** Internal format is pipe-delimited operator notation. Denser than JSON, and readable cold by any LLM that's seen math, logic, or set theory — no model-specific training required.
- **Self-teaching translator.** The L1→L2→L3 apeifier writes new regex patterns back to its own database every time the L3 LLM teacher corrects the L1 model. The longer you run it, the cheaper translation gets.
- **Graph-aware search.** Every query is semantic + structural in one pass. Vector hits expand through the graph by tier-priority, depth, or breadth — no post-hoc re-ranking.
- **Tier-weighted voting.** Entries can be voted up or down, but your vote's weight is set by the quality of your *reason*, not your identity.

## Setup

**Windows:** double-click `ape.bat`

**Linux / Mac:**
```
bash ape.sh
```

Both check for Docker and walk you through installing it if needed.

## First boot

On first start, APE creates the SQLite database and prints a one-time **setup token** to its logs (also written to `data/setup-token`). Open `http://localhost:8070`, paste the token to claim the admin account, add a provider API key, and create your first concept-space — all in the UI.

Grab the token quickly:

```bash
./ape.sh logs | grep -m1 setup-token
```

The token file is deleted as soon as the admin account is claimed.

## Day-to-day

Run `ape.bat` (Windows) or `bash ape.sh` (Linux/Mac) and pick from the menu:

```
1) Start          - Start everything
2) Stop           - Stop (keeps your data)
3) Restart        - Stop + Start
4) Update         - Download latest + restart
5) Logs           - Watch what's happening
6) Status         - What's running right now?
7) Backup         - Back up all data
0) Exit
```

Or non-interactively: `ape.sh start`, `ape.sh stop`, `ape.sh update`, `ape.sh logs`, `ape.sh backup`.

Everything that isn't a lifecycle action — concept-spaces, providers, embedders, API keys, users — lives at `http://<host>:8070/settings`.

## Concept-spaces

A concept-space is an isolated knowledge domain with its own Qdrant collection and embedder. Your installation starts with a `default` space (created during first-boot setup).

To add another, open *Settings → Concept-Spaces* in the web UI. You can pick:

- **Server** — an OpenAI-compatible `/v1/embeddings` sidecar (TEI, LM Studio, Infinity, …) you host yourself.
- **API** — a hosted endpoint (OpenAI, Cohere, Voyage, Jina, …) referenced by URL plus an env var holding the API key.

Dimension is immutable after a space is created — it must match the Qdrant collection.

## Connecting to it

APE binds to `127.0.0.1:8070`. Point your preferred ingress (nginx, Caddy, Traefik, Cloudflare Tunnel, k8s, etc.) at it. For zero-config bundled TLS:

```bash
make caddy
```

| What | Where |
|------|-------|
| Gateway (auth, settings, LLM proxy) | `http://<host>:8070/` |
| MCP (Streamable HTTP) | `http://<host>:8070/mcp` |
| Liveness probe (use this for ingress) | `http://<host>:8070/health/live` |

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

APE is **DB-first.** Every setting — providers, API keys, concept-spaces, embedders, ports, admin users — lives in SQLite and is edited through *Settings* in the web UI (or the REST API) after the first admin signs in. There is no config file to babysit at runtime.

The only file the runtime reads is `ape.toml`, which is imported **once** on first boot to seed the database, then ignored. The first-run script copies `ape.example.toml` for you; tweak it before first boot if you want non-default seed values.

**API keys** are easiest to add in *Settings → Server Keys* once the admin account is set up. If you'd rather inject them via the environment, set `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` on the `ape` service in `docker-compose.yml` — env vars take priority over DB-stored values.

## What's in the box

- **ape** — single Rust binary: gateway (auth, settings, LLM proxy), MCP server, semantic search, knowledge graph, apeifier (the L1→L2→L3 self-teaching translator)
- **Qdrant** — vector index, one collection per concept-space
- **Redis** — per-session context stash, cache

Durable state lives on the `ape_data` volume as SQLite — graph nodes and edges, corpus records, auth, and config all in one file.

## Docs

[apecortex.com](https://apecortex.com) — architecture, glyph primer, operator reference.

## License

Apache 2.0
