# APE UI - Ephemeral Agent Lifecycle Interface

Minimal chat UI with transparent collective intelligence.

## Features

- **Auto-bootstrap:** Loads collective memory on session start (silent)
- **Context sidebar:** LLM-curated highlights from APE
- **Server-side magic:** Wrapper handles Redis verbatim + APE semantic injection
- **SSE streaming:** Real-time responses

## Development

```bash
# Install dependencies
pnpm install

# Start dev server (proxies to localhost:8070 and :8069)
pnpm run dev
```

Visit: http://localhost:5173

## Production (Docker)

```bash
# From repo root
docker-compose -f docker-compose.yml \
  -f docker-compose.litellm.yml \
  -f docker-compose.ui.yml up -d
```

Visit: http://localhost:3000

## Stack

- **SvelteKit** - UI framework (Svelte 5)
- **DaisyUI** - Component library (dark theme)
- **TailwindCSS** - Styling
- **pnpm** - Package manager

## Architecture

```
User types message
  ↓
UI → ape-api:8070
  ↓
Wrapper stores verbatim to Redis (1hr TTL, last 10 msgs)
Wrapper queries APE session history
Wrapper injects semantic context into system prompt
  ↓
Wrapper → LiteLLM → Anthropic/OpenAI/etc
  ↓
LLM has tools to query APE + Redis if needed
  ↓
Response streams back to UI (SSE)
  ↓
Sidebar shows simple context hints (LLM-curated)
```

**User sees:** Normal chat
**LLM sees:** Full collective memory + verbatim history

## Proxies

- Dev: Vite proxies in `vite.config.ts`
- Prod: SvelteKit hooks in `src/hooks.server.ts`

Both proxy:
- `/v1/*` → ape-api (LiteLLM)
- `/api/ape/*` → ape-core

## Philosophy

APE semantics are invisible to users. Compressed knowledge (`jwt_missing→pip_jose`) gets referenced naturally by the LLM in prose. Users just see helpful context hints in sidebar.
