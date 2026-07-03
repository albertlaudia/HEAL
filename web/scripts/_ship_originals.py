#!/usr/bin/env python3
"""HEAL — Upload 100 original mixed songs to CDN."""
import os, json, subprocess
from ftplib import FTP
from pathlib import Path

FTP_HOST = "win8108.site4now.net"
FTP_USER = "respc"
FTP_PASS = os.environ["SMARTERASP_FTP_PASSWORD"]
MIX_DIR = "/workspace/.mavis-cache/heal-song-mixes"


def upload(local, remote, retries=4):
    for attempt in range(retries):
        try:
            ftp = FTP()
            ftp.connect(FTP_HOST, 21, timeout=120)
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
            print(f"    attempt {attempt+1}: {e}")
            import time
            time.sleep(3)
    return None


def delete_remote(remote):
    try:
        ftp = FTP()
        ftp.connect(FTP_HOST, 21, timeout=30)
        ftp.login(FTP_USER, FTP_PASS)
        ftp.cwd("heal/audio/praise")
        ftp.delete(remote)
        ftp.quit()
        return True
    except Exception as e:
        print(f"    delete err: {e}")
        return False


def main():
    files = sorted(Path(MIX_DIR).glob("original-*.mp3"))
    print(f"═══ Uploading {len(files)} original songs ═══\n")
    SUCC = 0
    FAIL = 0
    for f in files:
        slug = f.stem.replace("original-", "")
        remote = f"orig-{slug}.mp3"  # use orig- prefix to mark our original
        size = os.path.getsize(f)
        # Skip if already exists with same size
        # (we'll just overwrite to be safe)
        sz = upload(str(f), remote)
        if sz:
            print(f"  ✓ {slug} ({sz//1024} KB)")
            SUCC += 1
        else:
            print(f"  ✗ {slug}")
            FAIL += 1

    print(f"\n=== {SUCC}/{len(files)} uploaded ===")


if __name__ == "__main__":
    main()