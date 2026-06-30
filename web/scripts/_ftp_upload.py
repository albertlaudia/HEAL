#!/usr/bin/env python3
"""HEAL — single-file FTP upload via ftplib. Goes into /heal/audio/praise/"""
import sys, os
from ftplib import FTP

FTP_HOST = "win8108.site4now.net"
FTP_USER = os.environ.get("SMARTERASP_FTP_USER", "respc")
FTP_PASS = os.environ["SMARTERASP_FTP_PASSWORD"]

local = sys.argv[1]
remote_subdir = sys.argv[2]  # e.g. "heal/audio/praise"
remote_name = sys.argv[3]

ftp = FTP()
ftp.connect(FTP_HOST, 21, timeout=30)
ftp.login(FTP_USER, FTP_PASS)

# Walk into the subdir, mkdir as needed
for part in remote_subdir.strip("/").split("/"):
    if not part:
        continue
    try:
        ftp.cwd(part)
    except Exception:
        ftp.mkd(part)
        ftp.cwd(part)
        print(f"  mkdir {part}/")

size = os.path.getsize(local)
with open(local, "rb") as f:
    ftp.storbinary(f"STOR {remote_name}", f)
print(f"✓ Uploaded {local} ({size} bytes) -> /{remote_subdir}/{remote_name}")
ftp.quit()
