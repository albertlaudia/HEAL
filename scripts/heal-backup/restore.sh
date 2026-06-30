#!/bin/bash
# HEAL PB restore from Backblaze B2
# Run on a fresh machine to validate a backup is restorable.
#
# Usage:
#   ./restore.sh heal-pb-2026-06-25T03-00.tar.gz
#   ./restore.sh latest

set -euo pipefail

ENV_FILE="/etc/heal-backup.env"
# shellcheck disable=SC1090
source "$ENV_FILE"

B2_BUCKET="${B2_BUCKET:-heal-backups}"
B2_PREFIX="${B2_PREFIX:-heal/}"
S3CMD_CONFIG="/root/.s3cfg-heal"
RESTORE_DIR="/tmp/heal-restore"

if [ "$1" = "latest" ]; then
  echo "Finding latest backup..."
  LATEST=$(s3cmd ls "s3://$B2_BUCKET/$B2_PREFIX" --config="$S3CMD_CONFIG" 2>/dev/null \
    | grep '\.tar\.gz$' \
    | sort \
    | tail -1 \
    | awk '{print $NF}')
  if [ -z "$LATEST" ]; then
    echo "No backups found" >&2
    exit 1
  fi
  ARCHIVE=$(basename "$LATEST")
else
  ARCHIVE="$1"
fi

echo "Restoring: $ARCHIVE"
mkdir -p "$RESTORE_DIR"
cd "$RESTORE_DIR"

s3cmd get "s3://$B2_BUCKET/$B2_PREFIX$ARCHIVE" --config="$S3CMD_CONFIG"
s3cmd get "s3://$B2_BUCKET/$B2_PREFIX$ARCHIVE.sha256" --config="$S3CMD_CONFIG" 2>/dev/null || true

# Verify integrity
if [ -f "${ARCHIVE}.sha256" ]; then
  echo "Verifying SHA-256..."
  if sha256sum -c "${ARCHIVE}.sha256"; then
    echo "✓ SHA-256 verified"
  else
    echo "✗ SHA-256 mismatch! Aborting." >&2
    exit 1
  fi
fi

# Extract
tar -xzf "$ARCHIVE"
echo ""
echo "✓ Restored to: $RESTORE_DIR/$(basename "${ARCHIVE%.tar.gz}")"
echo ""
echo "=== Verify the data ==="
echo "PB data files:"
ls -la "$RESTORE_DIR/"*.db 2>/dev/null | head -5 || echo "  (no .db found — check archive contents)"
echo ""
echo "=== To use this restore ==="
echo "1. Stop the current PB container in Dokploy"
echo "2. Replace /var/lib/dokploy/volumes/heal-pb/pb_data/ with:"
echo "   $RESTORE_DIR/$(basename "${ARCHIVE%.tar.gz}")"
echo "3. Restart PB container"
echo "4. Verify collections at https://pocketbase.scaleupcrm.com/_/"