# Caddy Addon

TLS reverse proxy in front of `ape:8070`. Bundled HTTPS for deployers who don't
already run an ingress.

## When to use this addon

Use it if:
- You're deploying on a bare rig and nothing else owns `:80` / `:443`.
- You want zero-config HTTPS with a self-signed cert (air-gapped / on-prem).
- You want zero-config HTTPS with Let's Encrypt (internet-facing, you own a domain).

Skip it if:
- You already run an ingress (host nginx/caddy/traefik, k8s ingress controller,
  Cloudflare Tunnel, etc.) — point your existing ingress at `127.0.0.1:8070`.
- You're on a managed platform that terminates TLS upstream (Fly, Railway, etc.).
- You're on a dev laptop and `http://localhost:8070` is fine.

## Setup

### Self-signed (air-gapped / on-prem)

```bash
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/tls.key -out certs/tls.crt -subj '/CN=ape.local'

make ADDONS="caddy"
```

### Let's Encrypt (internet-facing)

Edit `addons/caddy/Caddyfile` — replace the `:443` block with your domain:

```caddy
ape.yourdomain.com {
    reverse_proxy ape:8070
}
```

Caddy handles cert issuance and renewal automatically. Then:

```bash
make ADDONS="caddy"
```

## Ports

- `:80`  → redirects to `:443`
- `:443` → reverse-proxies to `ape:8070`
