#!/bin/bash
# HEAL media → FTP (resources.positiveness.club) — single-lftp-session approach.
#
# Strategy:
# - One lftp session, fed commands via stdin in batches of ~100 files
# - Passive mode (the only mode that works from this sandbox reliably)
# - connection-limit 1, no parallel
# - Reconnects automatically if lftp drops the session
# - Tracks every file in JSON tracker for idempotent reruns

set +e

FTP_HOST="win8108.site4now.net"
FTP_USER="${SMARTERASP_FTP_USER:-respc}"
FTP_PASS="${SMARTERASP_FTP_PASSWORD:?SMARTERASP_FTP_PASSWORD must be set}"
LOCAL_ROOT="/workspace/HEAL/public"
REMOTE_BASE="heal"

LOG="/tmp/heal-ftp-upload.log"
TRACKER="/tmp/heal-ftp-tracker.json"
REPORT="/tmp/heal-ftp-report.txt"

> "$LOG"
echo "HEAL → FTP upload starting $(date -u)" | tee "$REPORT" > /dev/null

# Build full list
mapfile -t FILES < <(cd "$LOCAL_ROOT" && find images audio -type f | sort)
TOTAL=${#FILES[@]}

# Filter out already-uploaded
TODO=()
for f in "${FILES[@]}"; do
  if [ -f "$TRACKER" ] && python3 -c "import json; d=json.load(open('$TRACKER')); exit(0 if d.get('$f',{}).get('ok') else 1)" 2>/dev/null; then
    continue
  fi
  TODO+=("$f")
done
echo "files total: $TOTAL  todo: ${#TODO[@]}" | tee -a "$REPORT"

[ ${#TODO[@]} -eq 0 ] && { echo "Nothing to upload."; exit 0; }

START=$(date +%s)

# Build lftp command file
build_cmd_file() {
  local start=$1
  local end=$2
  local outfile=$3
  {
    echo "set ftp:passive-mode true"
    echo "set ftp:prefer-epsv yes"
    echo "set net:connection-limit 1"
    echo "set net:timeout 60"
    echo "set net:max-retries 2"
    echo "set net:reconnect-interval-base 5"
    for ((i=start; i<end; i++)); do
      rel="${TODO[$i]}"
      printf 'put "%s/%s" -o "%s/%s"\n' "$LOCAL_ROOT" "$rel" "$REMOTE_BASE" "$rel"
    done
    echo "quit"
  } > "$outfile"
}

run_batch() {
  local cmdfile=$1
  local batch_num=$2
  local batch_size=$3

  echo "Batch $batch_num: $(date -u +%H:%M:%S)" >> "$REPORT"
  timeout 1800 lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" < "$cmdfile" >> "$LOG" 2>&1
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "  lftp exit $exit_code" >> "$REPORT"
  fi

  # Parse which puts succeeded by checking the log
  # A successful put doesn't print anything specific; failure prints "Access failed"
  for ((i=0; i<batch_size; i++)); do
    local idx=$((batch_num * batch_size + i))
    [ $idx -ge ${#TODO[@]} ] && break
    local rel="${TODO[$idx]}"
    # Mark as ok unless we see a clear failure for this exact file
    if grep -qF "Access failed.*${rel}" "$LOG" 2>/dev/null; then
      python3 -c "import json; d=json.load(open('$TRACKER')); d.setdefault('$rel',{})['ok']=False; json.dump(d,open('$TRACKER','w'))" 2>/dev/null
    else
      python3 -c "import json; d=json.load(open('$TRACKER')); d.setdefault('$rel',{})['ok']=True; json.dump(d,open('$TRACKER','w'))" 2>/dev/null
    fi
  done

  local uploaded=$(python3 -c "import json; d=json.load(open('$TRACKER')); print(sum(1 for v in d.values() if v.get('ok')))")
  local failed=$(python3 -c "import json; d=json.load(open('$TRACKER')); print(sum(1 for v in d.values() if not v.get('ok')))")
  local elapsed=$(($(date +%s) - START))
  echo "  progress: uploaded=$uploaded failed=$failed elapsed=${elapsed}s" >> "$REPORT"
}

# Run in batches of 100
BATCH_SIZE=100
NUM_BATCHES=$(( (${#TODO[@]} + BATCH_SIZE - 1) / BATCH_SIZE ))

for ((b=0; b<NUM_BATCHES; b++)); do
  start=$((b * BATCH_SIZE))
  end=$(( start + BATCH_SIZE ))
  [ $end -gt ${#TODO[@]} ] && end=${#TODO[@]}

  CMDFILE="/tmp/heal-batch-$b.lftp"
  build_cmd_file $start $end "$CMDFILE"
  run_batch "$CMDFILE" $b $((end - start))

  # Cooldown between batches
  sleep 10
done

ELAPSED=$(($(date +%s) - START))
UPLOADED=$(python3 -c "import json; d=json.load(open('$TRACKER')); print(sum(1 for v in d.values() if v.get('ok')))")
FAILED=$(python3 -c "import json; d=json.load(open('$TRACKER')); print(sum(1 for v in d.values() if not v.get('ok')))")

echo "" | tee -a "$REPORT"
echo "=== Final ===" | tee -a "$REPORT"
echo "total:    $TOTAL" | tee -a "$REPORT"
echo "uploaded: $UPLOADED" | tee -a "$REPORT"
echo "failed:   $FAILED" | tee -a "$REPORT"
echo "elapsed:  ${ELAPSED}s" | tee -a "$REPORT"

if [ $FAILED -gt 0 ]; then
  echo "" | tee -a "$REPORT"
  echo "=== Failed files ===" | tee -a "$REPORT"
  python3 -c "
import json
d = json.load(open('$TRACKER'))
for f, v in sorted(d.items()):
    if not v.get('ok'):
        print(f)
" | tee -a "$REPORT"
fi

echo "" | tee -a "$REPORT"
echo "Log:     $LOG" | tee -a "$REPORT"
echo "Tracker: $TRACKER" | tee -a "$REPORT"
echo "Report:  $REPORT" | tee -a "$REPORT"