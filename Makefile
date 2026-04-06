.PHONY: help start up stop down clean logs backup pull rebuild ps

# Composable Addons System for Atomic Pumpkin Deploy
# Uses pre-built images from ghcr.io
# Usage: make ADDONS="apechat ollama mcp-server code-thumbs"

ADDONS ?=
AVAILABLE_ADDONS := apechat ollama code-thumbs

# Build compose file list
define build_compose_files
	$(eval COMPOSE_FILES := -f docker-compose.yml)
	$(foreach addon,$(ADDONS),\
		$(if $(filter $(addon),$(AVAILABLE_ADDONS)),\
			$(eval COMPOSE_FILES += -f addons/$(addon)/docker-compose.$(addon).yml),\
			$(error Unknown addon: $(addon). Available: $(AVAILABLE_ADDONS))\
		)\
	)
endef

.DEFAULT_GOAL := start

help:
	@echo "🎃 Atomic Pumpkin - Production Deployment"
	@echo ""
	@echo "Quick Start:"
	@echo "  make                         - Core stack only"
	@echo "  make ADDONS=\"apechat\"         - Core + APEChat UI"
	@echo "  make ADDONS=\"apechat ollama\"  - Full stack with local LLMs"
	@echo ""
	@echo "Available Addons:"
	@echo "  apechat      - Web UI for chat interface"
	@echo "  ollama       - Local LLM server (Llama, Qwen, etc.)"
	@echo "  code-thumbs  - Multi-language formatter/linter"
	@echo ""
	@echo "Commands:"
	@echo "  make [start]             - Start services (default)"
	@echo "  make up                  - Alias for start"
	@echo "  make stop                - Stop services (keep data)"
	@echo "  make down                - Stop and remove containers"
	@echo "  make clean               - Stop and remove all data"
	@echo "  make logs                - View logs"
	@echo "  make backup              - Create timestamped tarball backup"
	@echo "  make pull                - Pull latest images from registry"
	@echo "  make rebuild             - Pull latest images and restart services"
	@echo ""
	@echo "Examples:"
	@echo "  make                                # Minimal stack"
	@echo "  make ADDONS=\"apechat\"                # + Web UI"
	@echo "  make ADDONS=\"apechat ollama\"         # + Web UI + Local LLMs"
	@echo "  make ADDONS=\"apechat code-thumbs\"    # + Web UI + Code Tools"
	@echo ""

start:
	@$(call build_compose_files)
	@echo "🚀 Starting Atomic Pumpkin (production images)..."
	@echo "   Core: qdrant + engine + postgres + redis + litellm + wrapper"
	@if [ -n "$(ADDONS)" ]; then \
		echo "   Addons: $(ADDONS)"; \
	else \
		echo "   Addons: (none - use ADDONS=\"...\" to add)"; \
	fi
	@echo ""
	@docker compose $(COMPOSE_FILES) up -d
	@echo ""
	@echo "✓ Services started"
	@echo ""
	@echo "Access points:"
	@echo "  Core API:    http://localhost:8069"
	@echo "  Wrapper API: http://localhost:8070"
	@if echo "$(ADDONS)" | grep -q "apechat"; then \
		echo "  APEChat UI:  http://localhost:3080"; \
	fi
	@if echo "$(ADDONS)" | grep -q "ollama"; then \
		echo "  Ollama:      http://localhost:11434"; \
	fi
	@if echo "$(ADDONS)" | grep -q "code-thumbs"; then \
		echo "  Code Thumbs: http://localhost:8072"; \
	fi

up: start

stop:
	@$(call build_compose_files)
	@echo "Stopping services..."
	@docker compose $(COMPOSE_FILES) stop
	@echo "✓ Stopped (data preserved)"

down:
	@$(call build_compose_files)
	@echo "Stopping and removing containers..."
	@docker compose $(COMPOSE_FILES) down
	@echo "✓ Containers removed (data preserved)"

clean:
	@echo "⚠️  This will remove ALL containers and data volumes"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(call build_compose_files)
	@docker compose $(COMPOSE_FILES) down -v
	@echo "✓ Cleaned (all data removed)"

logs:
	@$(call build_compose_files)
	@docker compose $(COMPOSE_FILES) logs -f

backup:
	@mkdir -p ../bak
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	BACKUP_FILE="../bak/ape-backup-$$TIMESTAMP.tar.gz"; \
	echo "Creating backup: $$BACKUP_FILE"; \
	tar --exclude='./backups' \
		--exclude='./.git' \
		--exclude='*.log' \
		-czf "$$BACKUP_FILE" .; \
	echo "✓ Backup created: $$BACKUP_FILE"; \
	ls -lh "$$BACKUP_FILE"

pull:
	@$(call build_compose_files)
	@echo "📥 Pulling latest images from registry..."
	@if [ -n "$(ADDONS)" ]; then \
		echo "   Core + Addons: $(ADDONS)"; \
	else \
		echo "   Core only (use ADDONS=\"...\" to pull addon images)"; \
	fi
	@echo ""
	@docker compose $(COMPOSE_FILES) pull
	@echo ""
	@echo "✓ Latest images pulled"
	@echo "Run 'make down && make up ADDONS=\"$(ADDONS)\"' to restart with new images"

rebuild: pull
	@$(call build_compose_files)
	@echo ""
	@echo "🔄 Restarting services with new images..."
	@docker compose $(COMPOSE_FILES) down
	@docker compose $(COMPOSE_FILES) up -d
	@echo ""
	@echo "✓ Services restarted with latest images"

# Compact docker ps - shows name, status, and condensed ports
ps:
	@docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' | awk -F'\t' '{ \
		name=$$1; status=$$2; ports=$$3; \
		gsub(/0\.0\.0\.0:/, "", ports); \
		gsub(/->[^,]+/, "", ports); \
		gsub(/, +/, ",", ports); \
		n=split(ports, arr, ","); delete seen; out=""; \
		for(i=1;i<=n;i++) if(arr[i] && !seen[arr[i]]++) out=out (out?",":"") arr[i]; \
		printf "%-24s %-14s %s\n", name, status, out \
	}'
