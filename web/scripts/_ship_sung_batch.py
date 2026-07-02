#!/usr/bin/env python3
"""
HEAL — Ship sung hymns batch (download + upload + PB patch).

Reads web/scripts/_sung_paths_v2.json — entries with full metadata.
For each:
  1. Download from archive.org
  2. Upload to FTP as sing-{slug}.mp3
  3. Patch PB record with:
     - review (description)
     - respect (scripture)
     - learning (reflection)
     - full tagging (emotion, category, mood, scripture_refs, tags)
     - voice = vocal-chorus-historical
     - audio_license = CC0 Public Domain
"""
import json, os, subprocess, sys
from ftplib import FTP
from pathlib import Path

PB_URL = "https://pocketbase.scaleupcrm.com"
FTP_HOST = "win8108.site4now.net"
FTP_USER = "respc"
FTP_PASS = os.environ["SMARTERASP_FTP_PASSWORD"]
PB_IDENTITY = os.environ["PB_IDENTITY"]
PB_PASSWORD = os.environ["PB_PASSWORD"]
DL_DIR = "/tmp/heal-sung-batch2"
PATHS_JSON = "/workspace/HEAL/web/scripts/_sung_paths_v2.json"


def get_pb_auth():
    r = subprocess.run([
        "curl", "-s", "-X", "POST",
        f"{PB_URL}/api/collections/_superusers/auth-with-password",
        "-H", "Content-Type: application/json",
        "-d", json.dumps({"identity": PB_IDENTITY, "password": PB_PASSWORD})
    ], capture_output=True, text=True, timeout=15)
    return json.loads(r.stdout)["token"]


def upload(local, remote):
    for attempt in range(4):
        try:
            ftp = FTP()
            ftp.connect(FTP_HOST, 21, timeout=60)
            ftp.login(FTP_USER, FTP_PASS)
            for p in "heal/audio/praise".split("/"):
                if p:
                    try: ftp.cwd(p)
                    except: ftp.mkd(p); ftp.cwd(p)
            with open(local, "rb") as f:
                ftp.storbinary(f"STOR {remote}", f, blocksize=8192)
            ftp.sendcmd("TYPE i")
            sz = ftp.size(remote)
            ftp.quit()
            return sz
        except Exception as e:
            print(f"    ✗ upload attempt {attempt+1}: {e}")
            import time
            time.sleep(2)
    return None


def get_duration(local):
    r = subprocess.run([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", local
    ], capture_output=True, text=True, timeout=10)
    try:
        return int(float(r.stdout.strip()) + 0.5)
    except:
        return 180


def find_or_create_pb(slug, title, lyrics, auth):
    """Find existing PB record by slug, or create one with full content."""
    r = subprocess.run([
        "curl", "-s", f"{PB_URL}/api/collections/HEAL_praise/records?perPage=1&filter=slug='{slug}'",
        "-H", f"Authorization: {auth}"
    ], capture_output=True, text=True, timeout=10)
    items = json.loads(r.stdout).get("items", [])
    if items:
        return items[0]["id"]
    # Create with the standard fields
    # First get required fields
    sample = subprocess.run([
        "curl", "-s", f"{PB_URL}/api/collections/HEAL_praise/records?perPage=1&fields=*",
        "-H", f"Authorization: {auth}"
    ], capture_output=True, text=True, timeout=10)
    sample_data = json.loads(sample.stdout)["items"][0] if json.loads(sample.stdout).get("items") else {}
    # We know lyrics is required
    payload = {
        "title": title,
        "slug": slug,
        "lyrics": lyrics or "(lyrics to be added)",
    }
    r = subprocess.run([
        "curl", "-s", "-X", "POST", f"{PB_URL}/api/collections/HEAL_praise/records",
        "-H", f"Authorization: {auth}",
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload)
    ], capture_output=True, text=True, timeout=10)
    try:
        result = json.loads(r.stdout)
        return result.get("id")
    except:
        return None


def patch_pb(rec_id, audio_url, source, duration, scripture, category, mood, emotion, description, reflection, tags, auth):
    payload = {
        "is_published": True,
        "audio_url": audio_url,
        "audio_license": "CC0 Public Domain — Archive.org (pre-1928 US recording)",
        "audio_source": f"archive.org {source}",
        "duration_seconds": duration,
        "scripture_refs": [scripture] if scripture else [],
        "category": category,
        "mood": mood,
        "emotion": emotion,
        "description": description,
        "reflection": reflection,
        "voice": "vocal-chorus-historical",
        "tags": tags + ["classic", "public-domain", "vocal", "sung", "historical-recording"],
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
    Path(DL_DIR).mkdir(parents=True, exist_ok=True)
    items = json.load(open(PATHS_JSON))
    print(f"═══ Shipping {len(items)} sung hymns (download + upload + PB) ═══\n")
    auth = get_pb_auth()

    SUCC = 0
    SKIP = 0
    FAIL = 0
    for item in items:
        slug = item["slug"]
        url = item["url"]
        ident = item["identifier"]
        date = item.get("date", "1900")[:10]
        title = item.get("title", slug)
        local = f"{DL_DIR}/{slug}.mp3"

        # 1. Download
        if not os.path.exists(local) or os.path.getsize(local) < 50000:
            r = subprocess.run([
                "curl", "-sL", "-o", local, "-m", "120", "--connect-timeout", "30",
                "-A", "Mozilla/5.0", url
            ], capture_output=True, timeout=130)
        if not os.path.exists(local) or os.path.getsize(local) < 50000:
            print(f"  ✗ {slug}: download failed")
            FAIL += 1
            continue
        size = os.path.getsize(local)

        # 2. Upload
        remote = f"sing-{slug}.mp3"
        sz = upload(local, remote)
        if not sz:
            print(f"  ✗ {slug}: upload failed")
            FAIL += 1
            continue
        print(f"  ✓ uploaded {slug} ({(sz or 0)//1024} KB)")

        # 3. Patch PB
        duration = get_duration(local)
        pb_id = find_or_create_pb(slug, title, item.get("description", ""), auth)
        if not pb_id:
            print(f"    ✗ no PB record for {slug}")
            FAIL += 1
            continue
        audio_url = f"https://resources.positiveness.club/heal/audio/praise/{remote}"
        result = patch_pb(
            pb_id, audio_url, f"{ident} ({date})", duration,
            item.get("scripture", ""), item.get("category", "comfort"),
            item.get("mood", "gentle"), item.get("emotion", "settled"),
            item.get("description", ""), item.get("reflection", ""),
            item.get("tags", []), auth
        )
        SUCC += 1

    print(f"\n=== {SUCC} succeeded, {FAIL} failed ===")


if __name__ == "__main__":
    main()