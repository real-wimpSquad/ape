.PHONY: help start up stop down clean logs backup pull rebuild ps caddy

# APE — Production Deployment
#
# Core stack: qdrant + ape + redis. APE binds 127.0.0.1:8070.
# Point your ingress there, or `make caddy` for bundled TLS.
#
# APE talks to services by URL (embedders, LLMs, code formatters).
# Nothing else ships bundled — configure endpoints in ape.toml.

CADDY := -f addons/caddy/docker-compose.caddy.yml

.DEFAULT_GOAL := start

help:
	@echo "APE — Production Deployment"
	@echo ""
	@echo "Core: qdrant + ape + redis on 127.0.0.1:8070"
	@echo ""
	@echo "Commands:"
	@echo "  make [start]   - Start core stack (default)"
	@echo "  make caddy     - Start core + bundled Caddy TLS"
	@echo "  make up        - Alias for start"
	@echo "  make stop      - Stop services (keep data)"
	@echo "  make down      - Stop and remove containers"
	@echo "  make clean     - Stop and remove all data"
	@echo "  make logs      - View logs"
	@echo "  make backup    - Create timestamped tarball backup"
	@echo "  make pull      - Pull latest images from registry"
	@echo "  make rebuild   - Pull latest images and restart services"
	@echo "  make ps        - Compact container status"
	@echo ""
	@echo "Ingress:"
	@echo "  - Bare rig + want HTTPS:  make caddy  (self-signed or Let's Encrypt)"
	@echo "  - Have an ingress:        omit caddy, point it at 127.0.0.1:8070"

start:
	@echo "Starting APE (core stack: qdrant + ape + redis)..."
	@docker compose up -d
	@echo ""
	@echo "APE Gateway: http://127.0.0.1:8070"

up: start

caddy:
	@echo "Starting APE + Caddy TLS..."
	@docker compose $(CADDY) up -d
	@echo ""
	@echo "HTTPS (Caddy): https://localhost/  (forwards to ape:8070)"

stop:
	@echo "Stopping services..."
	@docker compose $(CADDY) stop 2>/dev/null || true
	@docker compose stop
	@echo "Stopped (data preserved)"

down:
	@echo "Stopping and removing containers..."
	@docker compose $(CADDY) down 2>/dev/null || true
	@docker compose down
	@echo "Containers removed (data preserved)"

clean:
	@echo "This will remove ALL containers and data volumes"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker compose $(CADDY) down -v 2>/dev/null || true
	@docker compose down -v
	@echo "Cleaned (all data removed)"

logs:
	@docker compose logs -f

backup:
	@mkdir -p ../bak
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	BACKUP_FILE="../bak/ape-backup-$$TIMESTAMP.tar.gz"; \
	echo "Creating backup: $$BACKUP_FILE"; \
	tar --exclude='./backups' \
		--exclude='./.git' \
		--exclude='./models' \
		--exclude='*.log' \
		-czf "$$BACKUP_FILE" .; \
	echo "Backup created: $$BACKUP_FILE"; \
	ls -lh "$$BACKUP_FILE"

pull:
	@echo "Pulling latest images from registry..."
	@docker compose $(CADDY) pull
	@echo ""
	@echo "Latest images pulled"
	@echo "Run 'make down && make' (or 'make caddy') to restart with new images"

rebuild: pull
	@echo ""
	@echo "Restarting services with new images..."
	@docker compose down
	@docker compose up -d
	@echo ""
	@echo "Services restarted with latest images"

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
