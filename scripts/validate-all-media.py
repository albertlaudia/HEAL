#!/usr/bin/env python3
"""
HEAL — validate that every media URL in PocketBase resolves on the CDN
with the right content-type, non-zero size, and no placeholders.
"""
import os
import sys
import time
import json
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

PB_URL = os.environ.get("PB_URL")
PB_IDENTITY = os.environ.get("PB_IDENTITY")
PB_PASSWORD = os.environ.get("PB_PASSWORD")
CDN_BASE = "https://resources.positiveness.club/heal"

LOG = "/tmp/heal-validate.log"
REPORT = "/tmp/heal-validate-report.txt"

# Map: collection -> [(field, kind, filename_template_fn(slug))]
PLAN = {
    "HEAL_meditations": [
        ("illustration_url", "image", lambda s: f"images/meditations/illustration-{s}.png"),
        ("audio_url",       "audio", lambda s: f"audio/meditations/audio-{s}.mp3"),
    ],
    "HEAL_prayers": [
        ("illustration_url", "image", lambda s: f"images/prayers/prayer-{s}.png"),
    ],
    "HEAL_praise": [
        ("illustration_url", "image", lambda s: f"images/praise/praise-{s}.png"),
        ("audio_url",       "audio", lambda s: f"audio/praise/song-{s}.mp3"),
    ],
    "HEAL_essays": [
        ("illustration_url", "image", lambda s: f"images/essays/essay-{s}.png"),
    ],
}

EXPECTED_CONTENT_TYPE = {
    "image": ["image/png", "image/jpeg", "image/webp", "image/svg+xml", "image/avif"],
    "audio": ["audio/mpeg", "audio/mp3", "audio/wav", "audio/m4a", "audio/ogg", "application/ogg"],
}

MIN_SIZE_BYTES = {
    "image": 100,   # smallest PNG is at least 1KB
    "audio": 500,   # smallest valid mp3 frame is ~600B
}

# 1245 bytes is the IIS 404 default page — anything that small that claims to be media is wrong
PLACEHOLDER_SIZE = 2000


def auth():
    r = urllib.request.urlopen(urllib.request.Request(
        f"{PB_URL}/api/collections/_superusers/auth-with-password",
        data=json.dumps({"identity": PB_IDENTITY, "password": PB_PASSWORD}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    ), timeout=15)
    return json.loads(r.read())["token"]


def list_records(token, collection):
    r = urllib.request.urlopen(urllib.request.Request(
        f"{PB_URL}/api/collections/{collection}/records?perPage=500&fields=id,slug,illustration_url,audio_url",
        headers={"Authorization": token},
    ), timeout=30)
    return json.loads(r.read())["items"]


def check_url(url, expected_kind):
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=15) as r:
            status = r.status
            ctype = (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
            try:
                size = int(r.headers.get("Content-Length") or 0)
            except (TypeError, ValueError):
                size = 0
            return {
                "url": url,
                "kind": expected_kind,
                "status": status,
                "content_type": ctype,
                "size": size,
                "error": None,
            }
    except urllib.error.HTTPError as e:
        return {
            "url": url,
            "kind": expected_kind,
            "status": e.code,
            "content_type": (e.headers.get("Content-Type") if e.headers else "") or "",
            "size": 0,
            "error": f"HTTP {e.code}",
        }
    except Exception as e:
        return {
            "url": url,
            "kind": expected_kind,
            "status": 0,
            "content_type": "",
            "size": 0,
            "error": str(e)[:200],
        }


def main():
    log_f = open(LOG, "w")
    report_f = open(REPORT, "w")

    def log(msg, also_report=False):
        line = f"[{time.strftime('%H:%M:%S')}] {msg}"
        log_f.write(line + "\n")
        log_f.flush()
        if also_report:
            report_f.write(line + "\n")
            report_f.flush()
        print(line)

    log(f"=== HEAL media validation starting ===", True)
    log(f"PB URL: {PB_URL}", True)
    log(f"CDN base: {CDN_BASE}", True)
    log("", True)

    token = auth()
    log("authenticated ✓", True)
    log("", True)

    # Collect all URLs to check
    all_checks = []
    for col, fields in PLAN.items():
        items = list_records(token, col)
        log(f"  {col}: {len(items)} records")
        for item in items:
            for field, kind, tpl in fields:
                # Use the actual stored URL (may be empty if we cleared it)
                stored = item.get(field, "") or ""
                if not stored:
                    continue
                # If it's not a CDN URL, skip (some old entries might be local)
                if not stored.startswith(CDN_BASE):
                    continue
                all_checks.append({
                    "collection": col,
                    "slug": item["slug"],
                    "field": field,
                    "kind": kind,
                    "url": stored,
                })

    log(f"\nTotal URLs to check: {len(all_checks)}", True)

    # Run HEAD checks in parallel
    log("\nRunning HEAD checks (parallel, 20 workers)...", True)
    t0 = time.time()
    results = []
    with ThreadPoolExecutor(max_workers=20) as ex:
        futures = {ex.submit(check_url, c["url"], c["kind"]): c for c in all_checks}
        done = 0
        for fut in as_completed(futures):
            r = fut.result()
            meta = futures[fut]
            r.update(meta)
            results.append(r)
            done += 1
            if done % 50 == 0:
                log(f"  {done}/{len(all_checks)} checked ({time.time()-t0:.0f}s elapsed)", True)
    elapsed = time.time() - t0
    log(f"  done in {elapsed:.1f}s", True)
    log("", True)

    # Categorize
    ok = []
    bad_status = []
    bad_type = []
    bad_size = []
    errors = []

    for r in results:
        if r["error"] or r["status"] != 200:
            bad_status.append(r)
        elif r["content_type"] not in EXPECTED_CONTENT_TYPE.get(r["kind"], []):
            bad_type.append(r)
        elif r["size"] < MIN_SIZE_BYTES[r["kind"]]:
            bad_size.append(r)
        elif r["size"] < PLACEHOLDER_SIZE:
            # Suspiciously small but technically OK (could be a real tiny file)
            bad_size.append(r)
        else:
            ok.append(r)

    # Per-collection summary
    log("=== PER-COLLECTION SUMMARY ===", True)
    for col in PLAN:
        col_results = [r for r in results if r["collection"] == col]
        col_ok = [r for r in col_results if r in ok]
        log(f"  {col}: {len(col_ok)}/{len(col_results)} OK", True)
    log("", True)

    # Per-kind summary
    log("=== PER-KIND SUMMARY ===", True)
    for kind in ("image", "audio"):
        kind_results = [r for r in results if r["kind"] == kind]
        kind_ok = [r for r in kind_results if r in ok]
        log(f"  {kind}: {len(kind_ok)}/{len(kind_results)} OK", True)
    log("", True)

    # Final tally
    log("=== FINAL TALLY ===", True)
    log(f"  total checked: {len(results)}", True)
    log(f"  OK:            {len(ok)}", True)
    log(f"  bad status:    {len(bad_status)}", True)
    log(f"  bad type:      {len(bad_type)}", True)
    log(f"  bad size:      {len(bad_size)}", True)
    log(f"  errors:        {len(errors)}", True)
    log("", True)

    if bad_status:
        log("=== BAD STATUS (not 200) ===", True)
        for r in bad_status:
            log(f"  [{r['status']}] {r['collection']}/{r['slug']} {r['field']}: {r['url']}", True)
        log("", True)

    if bad_type:
        log("=== BAD CONTENT-TYPE ===", True)
        for r in bad_type:
            log(f"  [{r['content_type']}] {r['collection']}/{r['slug']} {r['field']}: {r['url']}", True)
        log("", True)

    if bad_size:
        log("=== SUSPECT SIZE (looks like placeholder) ===", True)
        for r in bad_size:
            log(f"  [{r['size']}B] {r['collection']}/{r['slug']} {r['field']}: {r['url']}", True)
        log("", True)

    # Sample of OK
    log("=== SAMPLE OF OK URLs (10 random) ===", True)
    import random
    random.seed(42)
    for r in random.sample(ok, min(10, len(ok))):
        log(f"  [{r['status']}, {r['size']}B, {r['content_type']}] {r['url']}", True)
    log("", True)

    log("Done.", True)

    log_f.close()
    report_f.close()


if __name__ == "__main__":
    main()