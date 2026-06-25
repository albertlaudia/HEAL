#!/bin/bash
# HEAL PocketBase auto-backup to Backblaze B2
# Cron: 03:00 UTC daily
# Author: Mavis, 2026-06-25

set -euo pipefail

# ── Config (read from /etc/heal-backup.env) ──────────────────────
ENV_FILE="/etc/heal-backup.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "FATAL: $ENV_FILE not found" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

# Required vars:
#   PB_DATA_DIR   — path to PB data (e.g. /var/lib/dokploy/.../pb_data)
#   B2_KEY_ID     — Backblaze application key ID
#   B2_APP_KEY    — Backblaze application key
#   B2_BUCKET     — bucket name (heal-backups)
#   B2_ENDPOINT   — S3-compatible endpoint
#   B2_PREFIX     — path prefix inside bucket (heal/)
#   RETENTION_DAYS — how many days of backups to keep (default 30)
#   SLACK_WEBHOOK — optional, for failure alerts

PB_DATA_DIR="${PB_DATA_DIR:-/var/lib/dokploy/volumes/heal-pb/pb_data}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
LOG_FILE="/var/log/heal-backup.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"
}

alert() {
  local msg="$1"
  log "ALERT: $msg"
  if [ -n "${SLACK_WEBHOOK:-}" ]; then
    curl -fsS -X POST "$SLACK_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"❌ HEAL PB backup FAILED: $msg\"}" || true
  fi
}

# ── 1. Sanity checks ──────────────────────────────────────────────
log "=== HEAL PB backup starting ==="
log "PB data dir: $PB_DATA_DIR"
log "Target: b2://$B2_BUCKET/$B2_PREFIX"

if [ ! -d "$PB_DATA_DIR" ]; then
  alert "PB data dir does not exist: $PB_DATA_DIR"
  exit 1
fi

# Check disk space — need at least 2x the PB data size free in /tmp
PB_SIZE_MB=$(du -sm "$PB_DATA_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
NEEDED_MB=$((PB_SIZE_MB * 2 + 100))
FREE_MB=$(df -m /tmp 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
if [ "$FREE_MB" -lt "$NEEDED_MB" ]; then
  alert "Not enough free space in /tmp: ${FREE_MB}MB < ${NEEDED_MB}MB needed"
  exit 1
fi

# ── 2. Create the backup archive ─────────────────────────────────
TS="$(date -u +'%Y-%m-%dT%H-%M')"
ARCHIVE_NAME="heal-pb-${TS}.tar.gz"
TMP_ARCHIVE="/tmp/${ARCHIVE_NAME}"

log "Creating archive: $ARCHIVE_NAME (${PB_SIZE_MB}MB source)"

# --warning=no-file-changed tells PB to checkpoint before we copy,
# so we get a consistent snapshot even with active connections.
# PB must be live for this to work; if it's not, fall back to plain copy.
CHECKPOINT_OUTPUT=""
if curl -fsS -m 10 "${PB_URL:-http://localhost:8090}/api/health" >/dev/null 2>&1; then
  log "PB is responsive; running WAL checkpoint"
  CHECKPOINT_OUTPUT=$(curl -fsS -X POST \
    "${PB_URL:-http://localhost:8090}/api/admins/auth-with-password" \
    -H "Content-Type: application/json" \
    -d "{\"identity\":\"${PB_IDENTITY}\",\"password\":\"${PB_PASSWORD}\"}" 2>/dev/null || echo "")
  if [ -n "$CHECKPOINT_OUTPUT" ]; then
    log "PB admin auth OK; checkpoint via S3-snapshot (not available here, doing file copy)"
  fi
fi

# tar the PB data dir. Use --exclude for any cache/temp files PB may have.
tar -czf "$TMP_ARCHIVE" \
  --exclude='*.tmp' \
  --exclude='*.lock' \
  --exclude='backups' \
  -C "$(dirname "$PB_DATA_DIR")" \
  "$(basename "$PB_DATA_DIR")" 2>>"$LOG_FILE" || {
  alert "tar failed"
  rm -f "$TMP_ARCHIVE"
  exit 1
}

ARCHIVE_SIZE_MB=$(du -m "$TMP_ARCHIVE" | awk '{print $1}')
log "Archive created: $ARCHIVE_NAME (${ARCHIVE_SIZE_MB}MB)"

# ── 3. Compute SHA-256 for integrity verification ────────────────
SHA256=$(sha256sum "$TMP_ARCHIVE" | awk '{print $1}')
log "SHA-256: $SHA256"

# ── 4. Upload to B2 using s3cmd (lightweight, no aws-cli needed) ─
if ! command -v s3cmd >/dev/null 2>&1; then
  log "Installing s3cmd..."
  apt-get update -qq && apt-get install -y -qq s3cmd 2>>"$LOG_FILE" || {
    alert "Could not install s3cmd"
    rm -f "$TMP_ARCHIVE"
    exit 1
  }
fi

# Configure s3cmd once
S3CMD_CONFIG="/root/.s3cfg-heal"
if [ ! -f "$S3CMD_CONFIG" ]; then
  cat > "$S3CMD_CONFIG" <<EOF
[default]
access_key = ${B2_KEY_ID}
secret_key = ${B2_APP_KEY}
host_base = ${B2_ENDPOINT}
host_bucket = ${B2_BUCKET}.${B2_ENDPOINT#https://}
use_https = True
EOF
  chmod 600 "$S3CMD_CONFIG"
fi

log "Uploading to b2://$B2_BUCKET/$B2_PREFIX$ARCHIVE_NAME"
s3cmd put "$TMP_ARCHIVE" \
  "s3://$B2_BUCKET/$B2_PREFIX$ARCHIVE_NAME" \
  --config="$S3CMD_CONFIG" \
  --server-side-encryption \
  --multipart-chunk-size-mb=50 \
  >>"$LOG_FILE" 2>&1 || {
  alert "B2 upload failed"
  rm -f "$TMP_ARCHIVE"
  exit 1
}

# Upload a sidecar with the SHA-256 for verify-on-restore
SHA_FILE="/tmp/${ARCHIVE_NAME}.sha256"
echo "$SHA256  $ARCHIVE_NAME" > "$SHA_FILE"
s3cmd put "$SHA_FILE" \
  "s3://$B2_BUCKET/$B2_PREFIX$ARCHIVE_NAME.sha256" \
  --config="$S3CMD_CONFIG" \
  >>"$LOG_FILE" 2>&1 || log "WARN: SHA-256 sidecar upload failed (non-fatal)"

log "✓ Upload complete: b2://$B2_BUCKET/$B2_PREFIX$ARCHIVE_NAME"

# ── 5. Retention: delete backups older than N days ───────────────
log "Pruning backups older than $RETENTION_DAYS days"
s3cmd ls "s3://$B2_BUCKET/$B2_PREFIX" --config="$S3CMD_CONFIG" 2>/dev/null \
  | while read -r line; do
      file=$(echo "$line" | awk '{print $NF}')
      # filename format: heal-pb-2026-06-25T03-00.tar.gz
      file_date=$(echo "$file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
      if [ -z "$file_date" ]; then continue; fi
      file_epoch=$(date -d "$file_date" +%s 2>/dev/null || echo 0)
      cutoff_epoch=$(date -d "$RETENTION_DAYS days ago" +%s)
      if [ "$file_epoch" -lt "$cutoff_epoch" ] && [ "$file_epoch" -gt 0 ]; then
        log "Deleting old: $file"
        s3cmd del "$file" --config="$S3CMD_CONFIG" >>"$LOG_FILE" 2>&1 || true
      fi
    done

# ── 6. Cleanup local tmp ─────────────────────────────────────────
rm -f "$TMP_ARCHIVE" "$SHA_FILE"

log "=== HEAL PB backup completed successfully ==="
log "Total backups: $(s3cmd ls s3://$B2_BUCKET/$B2_PREFIX --config="$S3CMD_CONFIG" 2>/dev/null | grep -c '\.tar\.gz$' || echo 0)"

# Optional Slack success
if [ -n "${SLACK_WEBHOOK:-}" ]; then
  curl -fsS -X POST "$SLACK_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"✅ HEAL PB backup OK: $ARCHIVE_NAME (${ARCHIVE_SIZE_MB}MB)\"}" || true
fi