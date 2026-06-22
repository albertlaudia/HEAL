#!/usr/bin/env python3
"""
HEAL media → FTP — verify-and-retry for files that returned 404.
Uses urllib for HEAD check + subprocess+lftp for upload (single-line -e works).
"""
import os
import sys
import time
import json
import urllib.request
import subprocess

FTP_USER = "Ressup"
FTP_PASS = "R3sourceSc4leupCRM!"
FTP_HOST = "win8108.site4now.net"
LOCAL_ROOT = "/workspace/HEAL/public"
URL_BASE = "https://resources.positiveness.club/heal"
REMOTE_BASE = "heal"

LOG = "/tmp/heal-verify.log"
REPORT = "/tmp/heal-verify-report.txt"


def log(msg, also_report=False, log_f=None, report_f=None):
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    if log_f:
        log_f.write(line + "\n")
        log_f.flush()
    if also_report and report_f:
        report_f.write(line + "\n")
        report_f.flush()
    print(line)


def check_url(rel):
    url = f"{URL_BASE}/{rel}"
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=8) as r:
            return r.status == 200
    except urllib.error.HTTPError as e:
        return e.code == 200
    except Exception:
        return False


def upload_file(rel, max_attempts=5):
    local_path = os.path.join(LOCAL_ROOT, rel)
    remote_path = f"{REMOTE_BASE}/{rel}"
    for attempt in range(1, max_attempts + 1):
        try:
            # Single-line lftp -e with semicolons (the format that works)
            cmd = [
                "lftp", "-u", f"{FTP_USER},{FTP_PASS}",
                f"ftp://{FTP_HOST}",
                "-e",
                f"set ftp:passive-mode true; set net:connection-limit 1; set net:timeout 30; put \"{local_path}\" -o \"{remote_path}\"; quit"
            ]
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            time.sleep(2)
            if check_url(rel):
                return True
        except Exception as e:
            pass
        time.sleep(3)
    return False


def main():
    log_f = open(LOG, "a")
    report_f = open(REPORT, "w")

    try:
        log(f"=== Verify-and-retry starting ===", also_report=True, log_f=log_f, report_f=report_f)
        log(f"Local root: {LOCAL_ROOT}", also_report=True, log_f=log_f, report_f=report_f)

        # Collect all local files
        local_files = []
        for root in ["images", "audio"]:
            for dp, dirs, files in os.walk(os.path.join(LOCAL_ROOT, root)):
                for f in files:
                    rel = os.path.relpath(os.path.join(dp, f), LOCAL_ROOT)
                    local_files.append(rel)
        local_files.sort()
        total = len(local_files)
        log(f"Total local files: {total}", also_report=True, log_f=log_f, report_f=report_f)

        # Phase 1: check all via HTTPS
        log("Phase 1: checking all files via HTTPS...", also_report=True, log_f=log_f, report_f=report_f)
        missing = []
        for i, rel in enumerate(local_files):
            if not check_url(rel):
                missing.append(rel)
            if (i + 1) % 50 == 0:
                log(f"  checked {i+1}/{total}, missing={len(missing)}", also_report=True, log_f=log_f, report_f=report_f)

        log(f"Phase 1 done: {len(missing)}/{total} missing", also_report=True, log_f=log_f, report_f=report_f)

        if not missing:
            log("Nothing to retry — all files accessible.", also_report=True, log_f=log_f, report_f=report_f)
            return

        # Phase 2: retry each missing file up to 5 times
        log(f"Phase 2: retrying {len(missing)} files (5 attempts each)...", also_report=True, log_f=log_f, report_f=report_f)
        recovered = []
        still_missing = []
        for i, rel in enumerate(missing):
            log(f"  [{i+1}/{len(missing)}] retrying {rel}", log_f=log_f)
            if upload_file(rel, max_attempts=5):
                recovered.append(rel)
                log(f"    ✓ recovered", log_f=log_f)
            else:
                still_missing.append(rel)
                log(f"    ✗ still missing", log_f=log_f)

        # Final
        log("", also_report=True, log_f=log_f, report_f=report_f)
        log("=== FINAL ===", also_report=True, log_f=log_f, report_f=report_f)
        log(f"Total files:       {total}", also_report=True, log_f=log_f, report_f=report_f)
        log(f"Already OK:        {total - len(missing)}", also_report=True, log_f=log_f, report_f=report_f)
        log(f"Recovered:         {len(recovered)}", also_report=True, log_f=log_f, report_f=report_f)
        log(f"Still missing:     {len(still_missing)}", also_report=True, log_f=log_f, report_f=report_f)
        if still_missing:
            log("Files still missing on the server:", also_report=True, log_f=log_f, report_f=report_f)
            for m in still_missing:
                log(f"  {m}", also_report=True, log_f=log_f, report_f=report_f)
        log("Done.", also_report=True, log_f=log_f, report_f=report_f)
    finally:
        log_f.close()
        report_f.close()


if __name__ == "__main__":
    main()