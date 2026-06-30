#!/usr/bin/env python3
"""HEAL — delete a single file from FTP."""
import sys, os
from ftplib import FTP

FTP_HOST = "win8108.site4now.net"
FTP_USER = os.environ.get("SMARTERASP_FTP_USER", "respc")
FTP_PASS = os.environ["SMARTERASP_FTP_PASSWORD"]

remote_subdir = sys.argv[1]
remote_name = sys.argv[2]

ftp = FTP()
ftp.connect(FTP_HOST, 21, timeout=60)
ftp.login(FTP_USER, FTP_PASS)

for part in remote_subdir.strip("/").split("/"):
    if not part:
        continue
    try:
        ftp.cwd(part)
    except Exception:
        ftp.mkd(part)
        ftp.cwd(part)

try:
    ftp.delete(remote_name)
    print(f"✓ deleted /{remote_subdir}/{remote_name}", flush=True)
except Exception as e:
    print(f"✗ could not delete /{remote_subdir}/{remote_name}: {e}", flush=True)
ftp.quit()