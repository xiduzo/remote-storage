#!/bin/sh
set -e
# Ensure /data exists and is writable by node user (fixes root-owned volume mounts)
mkdir -p /data
chown -R node:node /data 2>/dev/null || true
# Ensure database directory exists (in case SQLITE_DATABASE_PATH uses a subdir)
DB_PATH="${SQLITE_DATABASE_PATH:-/data/database.sqlite}"
DB_DIR="$(dirname "$DB_PATH")"
mkdir -p "$DB_DIR"
chown -R node:node "$DB_DIR" 2>/dev/null || true
exec su -s /bin/sh node -c "cd /data && exec node /app/dist/main.js"
