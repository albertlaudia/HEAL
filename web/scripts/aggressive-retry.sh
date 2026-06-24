#!/bin/bash
# HEAL media → FTP — aggressive retry for stubborn files.
#
# Some files hit the FTP server's anti-flapping limit and silently fail to
# register. This script finds every local file, checks via HTTPS, and retries
# any 404s up to 5 times each with cooldown.

set +e

FTP_HOST="win8108.site4now.net"
FTP_USER="${SMARTERASP_FTP_USER:-respc}"
FTP_PASS="${SMARTERASP_FTP_PASSWORD:-R3sourceSc4leupCRM!}"
LOCAL_ROOT="/workspace/HEAL/public"
REMOTE_BASE="heal"
URL_BASE="https://resources.positiveness.club/heal"

LOG="/tmp/heal-aggressive-retry.log"
REPORT="/tmp/heal-aggressive-retry-report.txt"

> "$LOG"
> "$REPORT"

cd /workspace/HEAL

total=0
recovered=0
still_missing=()
first_pass_skipped=0
second_pass_checked=0

echo "Aggressive retry starting $(date -u)" | tee -a "$REPORT"

# ---- Pass 1: identify all 404 files ----
echo "" | tee -a "$REPORT"
echo "Pass 1: identify all 404 files..." | tee -a "$REPORT"

for f in $(find public/images public/audio -type f | sort); do
  rel=${f#public/}
  total=$((total + 1))
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 "$URL_BASE/$rel")
  if [ "$code" = "200" ]; then
    first_pass_skipped=$((first_pass_skipped + 1))
    continue
  fi
  # 404 or other — try upload up to 5 times
  recovered_this=0
  for attempt in 1 2 3 4 5; do
    sleep 4
    out=$(lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode true
set ftp:prefer-epsv yes
set net:connection-limit 1
set net:timeout 30
set net:max-retries 1
put \"$LOCAL_ROOT/$rel\" -o \"$REMOTE_BASE/$rel\"
quit
" 2>&1)
    sleep 3
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 "$URL_BASE/$rel")
    if [ "$code" = "200" ]; then
      recovered=$((recovered + 1))
      recovered_this=1
      echo "  RECOVERED on attempt $attempt: $rel" >> "$LOG"
      break
    fi
  done
  if [ $recovered_this -eq 0 ]; then
    still_missing+=("$rel")
    echo "  STILL MISSING after 5 attempts: $rel" >> "$LOG"
  fi
  if [ $((total % 25)) -eq 0 ]; then
    echo "  checked $total, ok=$first_pass_skipped, recovered=$recovered, still_missing=${#still_missing[@]}" | tee -a "$REPORT"
  fi
done

# ---- Final ----
echo "" | tee -a "$REPORT"
echo "=== FINAL ===" | tee -a "$REPORT"
echo "Total local files:    $total" | tee -a "$REPORT"
echo "Already OK (skip):    $first_pass_skipped" | tee -a "$REPORT"
echo "Recovered via retry:  $recovered" | tee -a "$REPORT"
echo "Still missing:        ${#still_missing[@]}" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
if [ ${#still_missing[@]} -gt 0 ]; then
  echo "Files still missing on the server:" | tee -a "$REPORT"
  printf '  %s\n' "${still_missing[@]}" | tee -a "$REPORT"
fi
echo "" | tee -a "$REPORT"
echo "Done at $(date -u)" | tee -a "$REPORT"