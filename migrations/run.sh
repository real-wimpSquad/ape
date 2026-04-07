#!/bin/bash
# ============================================================================
# APE Migration Runner
# Applies all pending migrations in order, tracks applied migrations
# ============================================================================

set -e

# Configuration (can be overridden via env vars)
PGUSER=${PGUSER:-litellm}
PGPASS=${PGPASSWORD:-litellm_pass}
PGHOST=${PGHOST:-postgres}
PGPORT=${PGPORT:-5432}
PGDB=${PGDB:-ape}

export PGPASSWORD=$PGPASS

# Migration directory (same dir as this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "APE Migration Runner"
echo "=============================================="
echo "Database: $PGHOST:$PGPORT/$PGDB"
echo ""

# Function to run SQL
run_sql() {
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 "$@"
}

# Function to run SQL quietly
run_sql_quiet() {
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 -t -q "$@"
}

# Ensure _migrations table exists (bootstrap)
echo "Checking migration tracking table..."
run_sql_quiet <<-EOSQL
    CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        applied_at TIMESTAMP DEFAULT NOW()
    );
EOSQL

# Get list of applied migrations
APPLIED=$(run_sql_quiet -c "SELECT name FROM _migrations ORDER BY name;")

# Find and apply pending migrations
PENDING=0
for migration in "$SCRIPT_DIR"/*.sql; do
    if [[ ! -f "$migration" ]]; then
        continue
    fi

    name=$(basename "$migration")

    # Skip if already applied
    if echo "$APPLIED" | grep -q "^${name}$"; then
        echo "  ✓ $name (already applied)"
        continue
    fi

    echo "  → Applying $name..."

    # Apply migration
    run_sql -f "$migration"

    # Record migration
    run_sql_quiet -c "INSERT INTO _migrations (name) VALUES ('$name');"

    echo "  ✓ $name applied"
    PENDING=$((PENDING + 1))
done

echo ""
if [[ $PENDING -eq 0 ]]; then
    echo "All migrations already applied."
else
    echo "Applied $PENDING new migration(s)."
fi

echo ""
echo "Migration summary:"
run_sql -c "SELECT name, applied_at FROM _migrations ORDER BY name;"
