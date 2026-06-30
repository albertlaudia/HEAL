#!/usr/bin/env python3
"""HEAL — single-file FTP upload with retry on BrokenPipe.

Per memory: SmarterASP FTP drops single session on large files (>1 MB).
Solution: fresh connection per attempt + exponential backoff + retry up to 5x.
Also uses binary mode + reasonable buffer for big files.
"""
import sys, os, time
from ftplib import FTP

FTP_HOST = "win8108.site4now.net"
FTP_USER = os.environ.get("SMARTERASP_FTP_USER", "respc")
FTP_PASS = os.environ["SMARTERASP_FTP_PASSWORD"]

local = sys.argv[1]
remote_subdir = sys.argv[2]
remote_name = sys.argv[3]

size = os.path.getsize(local)
print(f"  Uploading {local} ({size//1024} KB) -> /{remote_subdir}/{remote_name}", flush=True)

# Retry with fresh connection per attempt
for attempt in range(1, 6):
    try:
        ftp = FTP()
        ftp.connect(FTP_HOST, 21, timeout=120)
        ftp.login(FTP_USER, FTP_PASS)

        for part in remote_subdir.strip("/").split("/"):
            if not part:
                continue
            try:
                ftp.cwd(part)
            except Exception:
                ftp.mkd(part)
                ftp.cwd(part)

        # Stream in larger chunks (8 KB default is fine, but let it auto-buffer)
        # The key is: keep the FTP session alive by streaming
        uploaded = 0
        with open(local, "rb") as f:
            # Use a callback to track progress and keep session warm
            def callback(chunk):
                nonlocal uploaded
                uploaded += len(chunk)

            ftp.storbinary(f"STOR {remote_name}", f, blocksize=8192, callback=callback)

        # Verify size
        try:
            ftp.sendcmd("TYPE i")
            remote_size = ftp.size(remote_name)
        except Exception:
            remote_size = None

        ftp.quit()

        if remote_size and remote_size != size:
            raise RuntimeError(f"size mismatch: local={size}, remote={remote_size}")

        print(f"  ✓ attempt {attempt}: uploaded {size} bytes (remote={remote_size})", flush=True)
        sys.exit(0)
    except (BrokenPipeError, EOFError, ConnectionResetError, OSError) as e:
        print(f"  ✗ attempt {attempt}: {type(e).__name__}: {e}", flush=True)
        try:
            ftp.quit()
        except Exception:
            pass
        # More aggressive backoff for large files
        backoff = min(2 ** attempt, 30)
        time.sleep(backoff)
    except Exception as e:
        print(f"  ✗ attempt {attempt}: {type(e).__name__}: {e}", flush=True)
        try:
            ftp.quit()
        except Exception:
            pass
        backoff = 2 ** attempt
        time.sleep(backoff)

print(f"FATAL: upload failed after 5 attempts", file=sys.stderr)
sys.exit(1)