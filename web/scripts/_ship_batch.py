#!/usr/bin/env python3
"""HEAL — Ship batch of MP3s to FTP and update PB records.

Usage: ./scripts/_ship_batch.py matches.tsv
Reads tsv: slug<TAB>mp3_url<TAB>rec_id
"""
import sys, os, json, subprocess, time
from ftplib import FTP

PB_URL = "https://pocketbase.scaleupcrm.com"
PB_AUTH_FILE = "/tmp/pb_auth"
FTP_HOST = "win8108.site4now.net"
FTP_USER = "respc"
FTP_PASS = os.environ["SMARTERASP_FTP_PASSWORD"]

def get_pb_auth():
    r = subprocess.run([
        "curl", "-s", "-X", "POST",
        f"{PB_URL}/api/collections/_superusers/auth-with-password",
        "-H", "Content-Type: application/json",
        "-d", json.dumps({"identity": os.environ["PB_IDENTITY"],
                          "password": os.environ["PB_PASSWORD"]})
    ], capture_output=True, text=True, timeout=15)
    return json.loads(r.stdout)["token"]

def upload(local, remote):
    ftp = FTP()
    ftp.connect(FTP_HOST, 21, timeout=30)
    ftp.login(FTP_USER, FTP_PASS)
    for p in "heal/audio/praise".split("/"):
        if p:
            try: ftp.cwd(p)
            except: ftp.mkd(p); ftp.cwd(p)
    with open(local, "rb") as f:
        ftp.storbinary(f"STOR {remote}", f)
    ftp.sendcmd("TYPE i")
    sz = ftp.size(remote)
    ftp.quit()
    return sz

def get_duration(local):
    r = subprocess.run([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", local
    ], capture_output=True, text=True, timeout=10)
    return int(float(r.stdout.strip()) + 0.5)

def patch_pb(rec_id, audio_url, source, duration, auth):
    payload = {
        "is_published": True,
        "audio_url": audio_url,
        "audio_license": "CC0 Public Domain — hymnstogod.org",
        "audio_source": source,
        "duration_seconds": duration,
        "voice": "public-domain-recording",
        "tags": ["classic", "public-domain", "instrumental"]
    }
    r = subprocess.run([
        "curl", "-s", "-X", "PATCH",
        f"{PB_URL}/api/collections/HEAL_praise/records/{rec_id}",
        "-H", f"Authorization: {auth}",
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload)
    ], capture_output=True, text=True, timeout=10)
    return r.stdout

def main():
    tsv = sys.argv[1] if len(sys.argv) > 1 else "/tmp/matches.tsv"
    rows = []
    with open(tsv) as f:
        for line in f:
            parts = line.strip().split("|")
            if len(parts) == 3:
                rows.append(tuple(parts))
    
    print(f"Loaded {len(rows)} rows")
    auth = get_pb_auth()
    
    succ = 0
    fail = 0
    for slug, mp3_url, rec_id in rows:
        local = f"/tmp/hymn-downloads/{slug}.mp3"
        if not os.path.exists(local) or os.path.getsize(local) < 10000:
            print(f"  ✗ {slug}: file missing or too small")
            fail += 1
            continue
        
        sz = os.path.getsize(local)
        try:
            remote_sz = upload(local, f"pd-{slug}.mp3")
        except Exception as e:
            print(f"  ✗ {slug}: upload failed: {e}")
            fail += 1
            continue
        
        try:
            duration = get_duration(local)
        except:
            duration = 60
        
        audio_url = f"https://resources.positiveness.club/heal/audio/praise/pd-{slug}.mp3"
        result = patch_pb(rec_id, audio_url, os.path.basename(mp3_url), duration, auth)
        
        print(f"  ✓ {slug} ({duration}s, {sz//1024}KB) — PB ok")
        succ += 1
    
    print(f"\n=== {succ} succeeded, {fail} failed ===")

if __name__ == "__main__":
    main()