#!/usr/bin/env bash
# HEAL — PocketBase backup fetcher.
#
# PB instance auto-backs up daily at 00:00 UTC (cron: 0 0 * * *) to its
# own /pb_data/backups/ directory. We copy the latest auto-backup
# to /var/backups/heal-pocketbase/ (off-instance) and prune to 30 daily
# + 8 weekly. This gives us a recoverable copy even if the PB Docker
# volume is lost.
#
# Cron: 0 4 * * * /usr/local/bin/heal-pb-backup.sh >> /var/log/heal-pb-backup.log 2>&1

set -euo pipefail

BACKUP_DIR="/var/backups/heal-pocketbase"
KEEP_DAILY=30
KEEP_WEEKLY=8
TIMESTAMP=$(date -u +'%Y-%m-%dT%H-%M-%SZ')

PB_BACKUP_SRC="/var/lib/docker/volumes/gop-pocketbase-g7e4oj_pocketbase-data/_data/data/backups"

mkdir -p "$BACKUP_DIR"

# Find the latest auto backup file in the source
LATEST=$(ls -1t "$PB_BACKUP_SRC"/@auto_pb_backup_*.zip 2>/dev/null | grep -v ".attrs$" | head -n 1 || true)

if [ -z "$LATEST" ] || [ ! -f "$LATEST" ]; then
  echo "[$TIMESTAMP] FAIL — no auto backup found in $PB_BACKUP_SRC" >&2
  exit 1
fi

LOCAL_FILE="$BACKUP_DIR/$(basename "$LATEST")"

# Skip if we already have today's copy (idempotent)
if [ -e "$LOCAL_FILE" ]; then
  SIZE=$(stat -c%s "$LOCAL_FILE")
  if [ "$SIZE" -gt 1000000 ]; then
    echo "[$TIMESTAMP] SKIP — already have $LOCAL_FILE ($SIZE bytes)"
    exit 0
  fi
fi

# Copy it
cp "$LATEST" "$LOCAL_FILE"
SIZE=$(stat -c%s "$LOCAL_FILE")

if [ "$SIZE" -lt 1000000 ]; then
  echo "[$TIMESTAMP] FAIL — backup too small: $SIZE bytes" >&2
  rm -f "$LOCAL_FILE"
  exit 1
fi

echo "[$TIMESTAMP] OK — copied $(basename "$LATEST") ($SIZE bytes)"

# Mark one as weekly (only if not already marked for this ISO week)
WEEK_DIR="$BACKUP_DIR/weekly"
mkdir -p "$WEEK_DIR"
ISO_WEEK=$(date -u +'%G-W%V')
WEEKLY_MARK="$WEEK_DIR/$(basename "$LATEST")"
if [ ! -e "$WEEKLY_MARK" ]; then
  cp "$LOCAL_FILE" "$WEEKLY_MARK"
  echo "[$TIMESTAMP] Marked weekly: $WEEKLY_MARK"
fi

# Prune daily
DAILY_BACKUPS=$(ls -1t "$BACKUP_DIR"/@auto_pb_backup_*.zip 2>/dev/null | head -n 999 || true)
if [ -n "$DAILY_BACKUPS" ]; then
  echo "$DAILY_BACKUPS" | tail -n +$((KEEP_DAILY + 1)) | xargs -r rm -f --
fi
WEEKLY_BACKUPS=$(ls -1t "$WEEK_DIR"/@auto_pb_backup_*.zip 2>/dev/null | head -n 999 || true)
if [ -n "$WEEKLY_BACKUPS" ]; then
  echo "$WEEKLY_BACKUPS" | tail -n +$((KEEP_WEEKLY + 1)) | xargs -r rm -f --
fi

TOTAL_MB=$(du -sm "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo 0)
echo "[$TIMESTAMP] Total backup dir: ${TOTAL_MB}MB"
if [ "$TOTAL_MB" -gt 10240 ]; then
  echo "[$TIMESTAMP] WARNING — backup dir over 10GB, consider offsite rotation" >&2
fi
