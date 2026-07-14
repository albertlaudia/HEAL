#!/usr/bin/env python3
"""
Migrate all HEAL media (audio + images) from SmarterASP FTP to Backblaze B2.

Why: 2026-07-14 user reported AudioService.play error in HEAL mobile app.
Root cause: HTTPS URL https://resources.positiveness.club/heal/... was
returning 404 from Cloudflare edge (CF was caching the 404 from when the
SmarterASP origin went down). Files actually exist on FTP at
win8108.site4now.net:/heal/... and were 200 OK there.

This script:
1. Fetches all HEAL_meditations, HEAL_praise, HEAL_prayers, HEAL_breathwork,
   HEAL_essays records from PB
2. For each audio_url or illustration_url on the broken CDN:
   a. Tries the URL as-is
   b. Falls back to /orig-{slug}.mp3 and /orig-v2-{slug}.mp3 variants
   c. Downloads from FTP
   d. Uploads to B2 (GOPResources bucket, /heal/ prefix)
   e. PATCHes PB record with new B2 URL
3. For files with no match: clears the URL in PB

Re-runnable: PB records already on B2 are skipped. Use --dry-run to preview.

Usage:
  python3 scripts/migrate-cdn.py --dry-run                    # preview all
  python3 scripts/migrate-cdn.py --type audio --limit 5      # first 5 audio
  python3 scripts/migrate-cdn.py --type images --collection HEAL_praise
"""
import ftplib, io, json, sys, time, urllib.request, base64, hashlib

# === CONFIG ===
FTP_HOST = "win8108.site4now.net"
FTP_USER = "respc"
FTP_PASS = "R3sourceSc4leupCRM!"
PB_URL = "https://pocketbase.scaleupcrm.com"
PB_USER = "minimax@scaleupcrm.com"
PB_PASS = "8ik,9ol.Q123!"
UA = "Mozilla/5.0 (HEAL-CDN-Migration)"
B2_BUCKET_ID = "3a602931153582da97ee0c1a"
B2_KEY_ID = "004a091552a7eca0000000001"
B2_APP_KEY = "K004u59enPVdHysLQ2LtnK0vX4+qyZM"
NEW_CDN_BASE = "https://f004.backblazeb2.com/file/GOPResources"

# Manual overrides for non-standard naming
# null = clear URL, "filename" = use this FTP file
MANUAL_MAPPING = {
    "HEAL_praise": {
        "it-is-well-with-my-soul-abridged": "orig-it-is-well-with-my-soul-full.mp3",
        "amazing-grace-common-meter": "orig-amazing-grace-full.mp3",
        "joy-to-the-world-edmonds": "orig-v2-joy-to-the-world.mp3",
        # PB has these slugs but no good file in FTP
        "come-thou-fount-of-every-blessing": None,
        "what-a-friend-we-have-in-jesus": None,
        "rock-of-ages": None,
        "behold-the-lamb-of-god": None,
        "come-ye-thankful-people-come": None,
        "in-the-sweet-by-and-by": None,
        "silent-night": None,
        "the-old-rugged-cross": None,
        "this-is-my-fathers-world": None,
        "twas-grace-that-taught-my-heart-to-fear": None,
        "wonderful-words-of-life": None,
        "yield-not-to-temptation": None,
        "pass-me-not-o-gentle-savior": None,
    },
    "HEAL_meditations": {},
    "HEAL_prayers": {},
    "HEAL_breathwork": {},
    "HEAL_essays": {},
}

# Args
DRY_RUN = "--dry-run" in sys.argv
TYPE_FILTER = "both"
if "--type" in sys.argv:
    TYPE_FILTER = sys.argv[sys.argv.index("--type") + 1]
LIMIT = 0
if "--limit" in sys.argv:
    LIMIT = int(sys.argv[sys.argv.index("--limit") + 1])
ONLY_COLLECTION = None
if "--collection" in sys.argv:
    ONLY_COLLECTION = sys.argv[sys.argv.index("--collection") + 1]


def log(msg):
    print(msg, flush=True)


def http_json(url, data=None, headers=None, method=None):
    h = {"User-Agent": UA}
    if headers: h.update(headers)
    if data is not None and not isinstance(data, (bytes, bytearray)):
        h.setdefault("Content-Type", "application/json")
        data = json.dumps(data).encode()
    if method is None: method = "POST" if data else "GET"
    return json.loads(urllib.request.urlopen(urllib.request.Request(url, data=data, headers=h, method=method), timeout=60).read())


def http_post_raw(url, data, headers):
    h = {"User-Agent": UA}
    h.update(headers)
    req = urllib.request.Request(url, data=data, headers=h, method="POST")
    return json.loads(urllib.request.urlopen(req, timeout=120).read())


def ftp_download(path, retries=3):
    for i in range(retries):
        try:
            ftp = ftplib.FTP(FTP_HOST, timeout=15)
            ftp.login(FTP_USER, FTP_PASS)
            buf = io.BytesIO()
            ftp.retrbinary(f"RETR {path}", buf.write)
            ftp.quit()
            return buf.getvalue()
        except Exception as e:
            try: ftp.quit()
            except: pass
            if i < retries - 1: time.sleep(1)
            else: raise


def b2_auth():
    creds = base64.b64encode(f"{B2_KEY_ID}:{B2_APP_KEY}".encode()).decode()
    return http_json("https://api.backblazeb2.com/b2api/v2/b2_authorize_account",
                     headers={"Authorization": f"Basic {creds}"})


def b2_upload(auth, data, name, ct):
    info = http_json(f"{auth['apiUrl']}/b2api/v2/b2_get_upload_url",
                     {"bucketId": B2_BUCKET_ID},
                     headers={"Authorization": auth["authorizationToken"]})
    sha1 = hashlib.sha1(data).hexdigest()
    return http_post_raw(info["uploadUrl"], data, headers={
        "Authorization": info["authorizationToken"],
        "X-Bz-File-Name": name,
        "Content-Type": ct,
        "X-Bz-Content-Sha1": sha1,
    })


def detect_content_type(path):
    if path.endswith(".mp3"): return "audio/mpeg"
    if path.endswith(".png"): return "image/png"
    if path.endswith(".jpg") or path.endswith(".jpeg"): return "image/jpeg"
    if path.endswith(".webp"): return "image/webp"
    if path.endswith(".wav"): return "audio/wav"
    return "application/octet-stream"


def try_ftp_variants_audio(remote_dir, slug):
    """Try common audio filename patterns."""
    variants = [
        f"{remote_dir}/sing-{slug}.mp3",
        f"{remote_dir}/orig-{slug}.mp3",
        f"{remote_dir}/orig-v2-{slug}.mp3",
        f"{remote_dir}/audio-{slug}.mp3",
        f"{remote_dir}/{slug}.mp3",
    ]
    for v in variants:
        try: return ftp_download(v), v
        except: continue
    return None, None


def try_ftp_variants_image(remote_dir, slug, ext=".png"):
    """Try common image filename patterns."""
    variants = [
        f"{remote_dir}/illustration-{slug}{ext}",
        f"{remote_dir}/{slug}{ext}",
        f"{remote_dir}/praise-{slug}{ext}",
        f"{remote_dir}/meditation-{slug}{ext}",
        f"{remote_dir}/prayer-{slug}{ext}",
    ]
    for v in variants:
        try: return ftp_download(v), v
        except: continue
    return None, None


def process_field(token, auth, collection, field, remote_dir):
    log(f"\n=== {collection} ({field}) ===")
    response = http_json(f"{PB_URL}/api/collections/{collection}/records?perPage=300&fields=id,slug,{field}",
                        headers={"Authorization": token})
    records = response.get("items", [])
    log(f"  Total: {len(records)}")
    
    success = 0
    fail = 0
    skip = 0
    cleared = 0
    count = 0
    
    for i, rec in enumerate(records, 1):
        slug = rec.get("slug", "")
        url = rec.get(field, "")
        if "resources.positiveness.club" not in (url or ""):
            skip += 1
            continue
        
        if LIMIT and count >= LIMIT:
            break
        
        mapping = MANUAL_MAPPING.get(collection, {}).get(slug, "auto")
        
        if mapping == "auto":
            # Try URL as-is
            remote = "/" + url.split("resources.positiveness.club/heal/", 1)[1]
            data = None
            try:
                data = ftp_download(remote)
            except:
                if field == "audio_url":
                    data, found = try_ftp_variants_audio(remote_dir, slug)
                else:
                    ext = ".png"
                    if url.lower().endswith(".jpg"): ext = ".jpg"
                    data, found = try_ftp_variants_image(remote_dir, slug, ext)
                if data:
                    remote = found
        elif mapping is None:
            # Clear
            if DRY_RUN:
                log(f"  [{i}/{len(records)}] {slug}: would clear (no match)")
                cleared += 1
                count += 1
                continue
            try:
                http_json(f"{PB_URL}/api/collections/{collection}/records/{rec['id']}",
                         {field: ""}, headers={"Authorization": token}, method="PATCH")
                cleared += 1
                log(f"  [{i}/{len(records)}] {slug}: cleared")
                count += 1
            except Exception as e:
                log(f"  ✗ clear {slug}: {e}")
                fail += 1
            continue
        else:
            # Use specific file
            remote = f"{remote_dir}/{mapping}"
            if DRY_RUN:
                log(f"  [{i}/{len(records)}] {slug}: would upload {remote}")
                count += 1
                continue
            try:
                data = ftp_download(remote)
            except Exception as e:
                log(f"  ✗ FTP {slug}: {e}")
                fail += 1
                count += 1
                continue
        
        if data is None:
            if DRY_RUN:
                log(f"  [{i}/{len(records)}] {slug}: no file found")
                cleared += 1
                count += 1
                continue
            try:
                http_json(f"{PB_URL}/api/collections/{collection}/records/{rec['id']}",
                         {field: ""}, headers={"Authorization": token}, method="PATCH")
                cleared += 1
                log(f"  [{i}/{len(records)}] {slug}: no file, cleared")
                count += 1
            except Exception as e:
                fail += 1
            continue
        
        b2_path = f"heal/{remote.lstrip('/')}"
        ct = detect_content_type(remote)
        
        if DRY_RUN:
            log(f"  [{i}/{len(records)}] {slug}: would upload {len(data)//1024}KB to {b2_path}")
            count += 1
            continue
        
        try:
            b2_upload(auth, data, b2_path, ct)
        except Exception as e:
            log(f"  ✗ B2 {slug}: {e}")
            fail += 1
            count += 1
            continue
        
        new_url = f"{NEW_CDN_BASE}/{b2_path}"
        try:
            http_json(f"{PB_URL}/api/collections/{collection}/records/{rec['id']}",
                     {field: new_url}, headers={"Authorization": token}, method="PATCH")
            success += 1
            count += 1
            log(f"  ✓ {slug}: {len(data)//1024}KB")
        except Exception as e:
            log(f"  ✗ PB {slug}: {e}")
            fail += 1
            count += 1
    
    log(f"  Result: success={success} fail={fail} skip={skip} cleared={cleared}")


def main():
    log(f"HEAL CDN Migration")
    log(f"  DRY_RUN={DRY_RUN}, TYPE={TYPE_FILTER}, LIMIT={LIMIT}")
    
    if not DRY_RUN:
        log("Logging in to PB...")
        token = http_json(f"{PB_URL}/api/collections/_superusers/auth-with-password",
                         {"identity": PB_USER, "password": PB_PASS})["token"]
        log("✓ PB logged in")
        
        log("Logging in to B2...")
        auth = b2_auth()
        log("✓ B2 logged in")
    else:
        token = "dummy"
        auth = None
    
    # Determine what to process
    tasks = []
    if TYPE_FILTER in ("audio", "both"):
        tasks.append(("HEAL_meditations", "audio_url", "/heal/audio/meditations"))
        tasks.append(("HEAL_praise", "audio_url", "/heal/audio/praise"))
    if TYPE_FILTER in ("images", "both"):
        tasks.append(("HEAL_meditations", "illustration_url", "/heal/images/meditations"))
        tasks.append(("HEAL_praise", "illustration_url", "/heal/images/praise"))
        tasks.append(("HEAL_prayers", "illustration_url", "/heal/images/prayers"))
        tasks.append(("HEAL_breathwork", "illustration_url", "/heal/images/breath"))
        tasks.append(("HEAL_essays", "illustration_url", "/heal/images/essays"))
    
    for collection, field, remote_dir in tasks:
        if ONLY_COLLECTION and collection != ONLY_COLLECTION:
            continue
        process_field(token, auth, collection, field, remote_dir)
    
    log("\n=== DONE ===")


if __name__ == "__main__":
    main()
