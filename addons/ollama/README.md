# Ollama Addon

Containerized local LLM server for running open-source models (Llama, Qwen, DeepSeek, etc.)

## Features

- **Persistent Storage**: Models stored in Docker volume `ollama_data`
- **GPU Support**: Optional NVIDIA GPU acceleration
- **Auto-Discovery**: APEChat can discover and sync installed models
- **Port**: `11434`

## Usage

### With Makefile

```bash
# Dev with Ollama
make dev ADDONS="ollama"

# Full stack with Ollama
make dev ADDONS="apechat ollama code-thumbs"
```

### Manual

```bash
# Development
docker-compose -f docker-compose.yml \
  -f addons/ollama/docker-compose.ollama.yml up -d

# Production
docker-compose -f docker-compose.prod.yml \
  -f addons/ollama/docker-compose.ollama.prod.yml up -d
```

## Managing Models

```bash
# Pull a model
docker exec -it ape_ollama ollama pull llama3.3

# List installed models
docker exec -it ape_ollama ollama list

# Remove a model
docker exec -it ape_ollama ollama rm llama3.3

# Run a model directly (test)
docker exec -it ape_ollama ollama run llama3.3
```

## APEChat Integration

Once Ollama is running with models installed:

1. Open APEChat → **Settings**
2. Find **Ollama Manager** section
3. Click **Discover Models** → See installed models
4. Click **Sync All** → Add to chat dropdown
5. Select model in chat → Start using

## GPU Acceleration

Uncomment the `deploy` section in the compose file:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**Requirements:**
- NVIDIA GPU
- `nvidia-docker` installed
- Docker Compose v1.28+

**Installation (Ubuntu):**
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

## Storage

Models are stored in the `ollama_data` Docker volume. To check size:

```bash
docker system df -v | grep ollama_data
```

**Backup models:**
```bash
docker run --rm -v atomic-pumpkin_ollama_data:/data \
  -v $(pwd):/backup alpine \
  tar czf /backup/ollama_backup.tar.gz /data
```

## Network

Ollama joins the `atomic_pumpkin` network and is discoverable at:
- From containers: `http://ollama:11434`
- From host: `http://localhost:11434`

## Health Check

```bash
# Check container status
docker ps | grep ollama

# Manual health check
docker exec ape_ollama ollama list

# API health
curl http://localhost:11434/api/tags
```

## Recommended Models

Small/Fast (< 10GB):
- `llama3.3:8b` - Meta Llama 3.3
- `qwen2.5:7b` - Alibaba Qwen 2.5
- `deepseek-r1:8b` - DeepSeek reasoning model

Medium (10-20GB):
- `qwen2.5:14b` - Alibaba Qwen 2.5 14B
- `llama3.3:14b` - Meta Llama 3.3

Large (20GB+):
- `qwen3-coder:30b` - Code-specialized model
- `llama3.3:70b` - Meta Llama 3.3 (requires significant RAM/VRAM)

## Troubleshooting

**Container unhealthy:**
```bash
docker logs ape_ollama
docker exec ape_ollama ollama list
```

**Out of disk space:**
```bash
# Remove unused models
docker exec -it ape_ollama ollama rm <model>

# Check volume size
docker system df -v
```

**Models not appearing in APEChat:**
1. Ensure ape-api can reach Ollama: `curl http://ollama:11434/api/tags` from ape-api container
2. Restart ape-api: `docker-compose restart ape-api`
3. Re-discover in Settings → Ollama Manager
