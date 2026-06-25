#!/bin/bash
# HEAL media → FTP (resources.positiveness.club)
#
# Uploads /workspace/HEAL/public/images and /workspace/HEAL/public/audio
# to https://resources.positiveness.club/heal/{images,audio}/...
#
# Strategy: lftp active-mode FTP, parallel transfers, 3 retry attempts per file.
# All output captured to /tmp/heal-upload.log. Exit summary saved to /tmp/heal-upload-report.txt
#
# Re-running this is idempotent — already-uploaded files are skipped via lftp's --ignore-age check.
# To force re-upload of everything, pass --force as first arg.

set +e  # don't bail on first error — we want the full report

FORCE=""
if [ "$1" = "--force" ]; then
  FORCE="--ignore-age --overwrite"
fi

FTP_USER="${SMARTERASP_FTP_USER:-respc}"
FTP_PASS="${SMARTERASP_FTP_PASSWORD:?SMARTERASP_FTP_PASSWORD must be set}"
FTP_HOST="win8108.site4now.net"
LOCAL_ROOT="/workspace/HEAL/public"
REMOTE_BASE="heal"

LOGFILE="/tmp/heal-upload.log"
REPORT="/tmp/heal-upload-report.txt"

> "$LOGFILE"
echo "HEAL → FTP upload starting $(date -u)" | tee "$REPORT"
echo "host: $FTP_HOST  remote base: /$REMOTE_BASE/" | tee -a "$REPORT"
echo "source: $LOCAL_ROOT/{images,audio}/" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"

# ---- Phase 1: Create directory structure ----
echo "[1/3] Creating remote directories..." | tee -a "$REPORT"

# Build list of all needed subdirs
SUBDIRS="heal heal/images heal/images/badges heal/images/essays heal/images/meditations heal/images/praise heal/images/prayers heal/audio heal/audio/meditations heal/audio/praise"

lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
set net:connection-limit 1
set net:timeout 30
set net:max-retries 2
set net:reconnect-interval-base 5
$(for d in $SUBDIRS; do echo "mkdir -p $d"; done)
quit
" >> "$LOGFILE" 2>&1

# Verify the dirs exist
echo "  Directory listing after creation:" | tee -a "$REPORT"
lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
ls $REMOTE_BASE/images/
ls $REMOTE_BASE/audio/
quit
" >> "$LOGFILE" 2>&1

# ---- Phase 2: Upload images (largest payload, 652MB) ----
echo "" | tee -a "$REPORT"
echo "[2/3] Uploading images (652MB / 457 files)..." | tee -a "$REPORT"
echo "  Start: $(date -u +%H:%M:%S)" | tee -a "$REPORT"

# lftp mirror: --parallel=N for concurrent transfers, --no-perms to avoid Windows ACL issues
# --ignore-age skips files that haven't changed (idempotent on re-runs)
lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
set net:connection-limit 1
set net:timeout 120
set net:max-retries 5
set net:reconnect-interval-base 10
set ftp:ssl-force false
set ftp:use-pret no
mirror --reverse --verbose=1 --parallel=4 --no-perms --ignore-time $FORCE --log=/tmp/lftp-images.log $LOCAL_ROOT/images $REMOTE_BASE/images
bye
" >> "$LOGFILE" 2>&1
IMAGES_EXIT=$?
echo "  mirror exit: $IMAGES_EXIT" | tee -a "$REPORT"
echo "  End:   $(date -u +%H:%M:%S)" | tee -a "$REPORT"

# ---- Phase 3: Upload audio (30MB / 63 files) ----
echo "" | tee -a "$REPORT"
echo "[3/3] Uploading audio (30MB / 63 files)..." | tee -a "$REPORT"
echo "  Start: $(date -u +%H:%M:%S)" | tee -a "$REPORT"

lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
set net:connection-limit 1
set net:timeout 120
set net:max-retries 5
set net:reconnect-interval-base 10
set ftp:ssl-force false
set ftp:use-pret no
mirror --reverse --verbose=1 --parallel=4 --no-perms --ignore-time $FORCE --log=/tmp/lftp-audio.log $LOCAL_ROOT/audio $REMOTE_BASE/audio
bye
" >> "$LOGFILE" 2>&1
AUDIO_EXIT=$?
echo "  mirror exit: $AUDIO_EXIT" | tee -a "$REPORT"
echo "  End:   $(date -u +%H:%M:%S)" | tee -a "$REPORT"

# ---- Phase 4: Verification ----
echo "" | tee -a "$REPORT"
echo "[4/4] Verifying remote file counts..." | tee -a "$REPORT"

LOCAL_IMG=$(find "$LOCAL_ROOT/images" -type f | wc -l)
LOCAL_AUD=$(find "$LOCAL_ROOT/audio" -type f | wc -l)
echo "  Local  images: $LOCAL_IMG" | tee -a "$REPORT"
echo "  Local  audio:  $LOCAL_AUD" | tee -a "$REPORT"

# Count remote files (recursive ls, may take a while)
REMOTE_IMG=$(lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
find $REMOTE_BASE/images -type f
bye
" 2>/dev/null | grep -v "^drwx\|^total\|^ls\|^cd\|^find\|^bye\|^----\|^lftp" | wc -l)
REMOTE_AUD=$(lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
find $REMOTE_BASE/audio -type f
bye
" 2>/dev/null | grep -v "^drwx\|^total\|^ls\|^cd\|^find\|^bye\|^----\|^lftp" | wc -l)

echo "  Remote images: $REMOTE_IMG" | tee -a "$REPORT"
echo "  Remote audio:  $REMOTE_AUD" | tee -a "$REPORT"

# ---- Final report ----
echo "" | tee -a "$REPORT"
echo "=== Summary ===" | tee -a "$REPORT"
echo "Images: local=$LOCAL_IMG  remote=$REMOTE_IMG  delta=$((LOCAL_IMG - REMOTE_IMG))" | tee -a "$REPORT"
echo "Audio:  local=$LOCAL_AUD  remote=$REMOTE_AUD  delta=$((LOCAL_AUD - REMOTE_AUD))" | tee -a "$REPORT"

if [ $((LOCAL_IMG - REMOTE_IMG)) -ne 0 ] || [ $((LOCAL_AUD - REMOTE_AUD)) -ne 0 ]; then
  echo "" | tee -a "$REPORT"
  echo "Files missing on remote (sample):" | tee -a "$REPORT"
  # List local files not on remote
  comm -23 \
    <(cd "$LOCAL_ROOT" && find images audio -type f | sort) \
    <(lftp -u "$FTP_USER,$FTP_PASS" "ftp://$FTP_HOST" -e "
set ftp:passive-mode false
set ftp:prefer-epsv no
find $REMOTE_BASE/images $REMOTE_BASE/audio -type f
bye
" 2>/dev/null | sed "s|^$REMOTE_BASE/||" | sort) \
    | head -50 >> "$REPORT"
  echo "  ... (truncated to 50)" | tee -a "$REPORT"
fi

echo "" | tee -a "$REPORT"
echo "Full lftp logs: $LOGFILE" | tee -a "$REPORT"
echo "Report:         $REPORT" | tee -a "$REPORT"
echo "Done at $(date -u)" | tee -a "$REPORT"