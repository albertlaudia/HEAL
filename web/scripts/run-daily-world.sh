#!/usr/bin/env bash
# Runs the daily world generator. Idempotent.
# Cron entry: 21:00 UTC = 06:00 WST Australia (any time zone would work; we run a few
# minutes before midnight AEST so the Australia-morning gets fresh content).

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Env vars — should come from /etc/heal-world.env in production
export PB_IDENTITY="${PB_IDENTITY:-minimax@scaleupcrm.com}"
export PB_PASSWORD="${PB_PASSWORD:-8ik,9ol.Q123!}"
export PB_URL="${PB_URL:-https://pocketbase.scaleupcrm.com}"

# Use the system python (must support urllib)
PY="${PY:-/usr/bin/python3}"

exec "$PY" "$SCRIPT_DIR/daily-world.py"
