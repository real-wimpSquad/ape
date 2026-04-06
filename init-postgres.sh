#!/bin/bash
# ============================================================================
# Postgres Multi-Database Initialization
# Creates databases and runs migrations
# ============================================================================

set -e

echo "[init-postgres] Starting database initialization..."

# ============================================================================
# Create APE database
# ============================================================================
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    -- Create ape database if it doesn't exist
    SELECT 'CREATE DATABASE ape'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ape')\gexec

    -- Grant all privileges on ape database
    GRANT ALL PRIVILEGES ON DATABASE ape TO $POSTGRES_USER;

    SELECT '[init-postgres] APE database ready';
EOSQL

# ============================================================================
# Run migrations on APE database
# ============================================================================
echo "[init-postgres] Running migrations..."

# Create migration tracking table
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ape" <<-EOSQL
    CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        applied_at TIMESTAMP DEFAULT NOW()
    );
EOSQL

# Find and apply migrations from /docker-entrypoint-initdb.d/migrations/
MIGRATION_DIR="/docker-entrypoint-initdb.d/migrations"
if [ -d "$MIGRATION_DIR" ]; then
    for migration in "$MIGRATION_DIR"/*.sql; do
        if [ -f "$migration" ]; then
            name=$(basename "$migration")

            # Check if already applied
            applied=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ape" -t -c \
                "SELECT 1 FROM _migrations WHERE name='$name';" | tr -d ' ')

            if [ "$applied" = "1" ]; then
                echo "  ✓ $name (already applied)"
            else
                echo "  → Applying $name..."
                psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ape" -f "$migration"
                psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ape" -c \
                    "INSERT INTO _migrations (name) VALUES ('$name');"
                echo "  ✓ $name applied"
            fi
        fi
    done
else
    echo "  [WARN] Migration directory not found: $MIGRATION_DIR"
    echo "  [WARN] Skipping migrations. Run 'make migrate' after container starts."
fi

echo "[init-postgres] Initialization complete"
