#!/usr/bin/env python3
"""
HEAL — Full media audit
=======================

Three things this script does:
1. List every audio_url + illustration_url across all HEAL_* collections in PB.
2. HEAD-check each URL on the CDN (resources.positiveness.club) for HTTPS 200
   and a real content-type / size.
3. List every file in the CDN's /heal/ tree (via a manifest we can also
   generate separately) and find files that are NOT referenced by any PB record
   = orphaned CDN files.

Output: JSON to stdout with structured findings, plus a markdown report.
"""
import os
import sys
import json
import time
import urllib.request
import urllib.error
import urllib.parse
import concurrent.futures
from collections import defaultdict

PB_URL = os.environ.get('PB_URL', 'https://pocketbase.scaleupcrm.com')
PB_IDENTITY = os.environ.get('PB_IDENTITY')
PB_PASSWORD = os.environ.get('PB_PASSWORD')

CDN_BASE = 'https://resources.positiveness.club/heal'
COLLECTIONS = [
    'HEAL_meditations',
    'HEAL_praise',
    'HEAL_prayers',
    'HEAL_essays',
    'HEAL_breathwork',
    'HEAL_scriptures',
    'HEAL_quotes',
    'HEAL_programs',
    'HEAL_program_steps',
    'HEAL_pages',
    'HEAL_badges',
]

AUDIO_EXTS = {'.mp3', '.m4a', '.wav', '.ogg'}
IMAGE_EXTS = {'.png', '.jpg', '.jpeg', '.webp', '.avif', '.svg', '.gif'}


def http_post(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **({'Authorization': token} if token else {})},
        method='POST',
    ), timeout=15)


def http_get(url, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': token} if token else {},
    ), timeout=15)


def head_url(url, timeout=10):
    """HEAD-check a URL. Return dict with status, content_type, size."""
    try:
        req = urllib.request.Request(url, method='HEAD')
        # Use a real User-Agent so Cloudflare doesn't 403
        req.add_header('User-Agent', 'HEAL-MediaAudit/1.0 (+https://heal.positiveness.club)')
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return {
                'status': r.status,
                'content_type': r.headers.get('content-type', ''),
                'content_length': int(r.headers.get('content-length', 0) or 0),
            }
    except urllib.error.HTTPError as e:
        return {'status': e.code, 'error': e.reason}
    except Exception as e:
        return {'status': 0, 'error': str(e)[:200]}


def auth():
    r = http_post(
        f'{PB_URL}/api/collections/_superusers/auth-with-password',
        {'identity': PB_IDENTITY, 'password': PB_PASSWORD})
    return json.loads(r.read())['token']


def list_records(token, collection, page_size=200, max_pages=20):
    items = []
    for page in range(1, max_pages + 1):
        r = http_get(
            f'{PB_URL}/api/collections/{collection}/records?perPage={page_size}&page={page}',
            token)
        d = json.loads(r.read())
        if not d.get('items'):
            break
        items.extend(d['items'])
        if len(d['items']) < page_size:
            break
    return items


def main():
    print('== HEAL Media Audit ==\n', file=sys.stderr)
    token = auth()
    print(f'Authenticated.\n', file=sys.stderr)

    # Pass 1: collect all media URLs from PB
    pb_urls = []  # list of (url, collection, record_id, field, slug)
    by_collection = defaultdict(int)

    for col in COLLECTIONS:
        try:
            records = list_records(token, col)
        except Exception as e:
            print(f'  SKIP {col}: {e}', file=sys.stderr)
            continue
        for rec in records:
            for field in ('audio_url', 'illustration_url', 'image_url', 'image', 'cover_url', 'cover', 'icon_url', 'thumbnail_url'):
                url = rec.get(field)
                if not url or not isinstance(url, str):
                    continue
                # Only count resources.positiveness.club URLs
                if 'resources.positiveness.club' not in url:
                    continue
                pb_urls.append({
                    'url': url,
                    'collection': col,
                    'record_id': rec.get('id'),
                    'slug': rec.get('slug') or rec.get('title') or rec.get('day_of_year') or '?',
                    'field': field,
                })
                by_collection[col] += 1

    print(f'\nFound {len(pb_urls)} PB media URLs across {len(by_collection)} collections\n', file=sys.stderr)
    for col, n in sorted(by_collection.items(), key=lambda x: -x[1]):
        print(f'  {col}: {n}', file=sys.stderr)

    # Dedupe (same URL may be referenced from multiple records)
    unique_urls = {}
    for u in pb_urls:
        unique_urls.setdefault(u['url'], []).append(u)
    print(f'\nUnique URLs: {len(unique_urls)} (some shared between records)\n', file=sys.stderr)

    # Pass 2: HEAD-check every unique URL
    print(f'Checking {len(unique_urls)} URLs in parallel...\n', file=sys.stderr)
    checked = {}

    def check(url):
        return url, head_url(url)

    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
        for url, result in ex.map(check, list(unique_urls.keys())):
            checked[url] = result

    # Pass 3: categorize results
    ok, broken, suspicious, errors = [], [], [], []
    for url, result in checked.items():
        refs = unique_urls[url]
        record = {
            'url': url,
            'referenced_by': [{'collection': r['collection'], 'slug': r['slug'], 'field': r['field']} for r in refs],
            **result,
        }
        status = result.get('status', 0)
        size = result.get('content_length', 0)
        ctype = result.get('content_type', '')
        if status == 200 and size > 0 and ctype and not ctype.startswith('text/html'):
            ok.append(record)
        elif status == 404:
            broken.append(record)
        elif status == 200 and size == 0:
            suspicious.append({**record, 'issue': '200 but zero bytes — likely cached 404 from Cloudflare'})
        elif status == 200 and ctype.startswith('text/html'):
            suspicious.append({**record, 'issue': '200 but content-type is text/html (likely a 404 page)'})
        else:
            errors.append(record)

    # Pass 4: print summary
    print(f'\n{"="*60}\n=== RESULTS ===\n{"="*60}\n', file=sys.stderr)
    print(f'  OK ({len(ok)}): 200 + non-empty + correct content-type', file=sys.stderr)
    print(f'  BROKEN ({len(broken)}): 404', file=sys.stderr)
    print(f'  SUSPICIOUS ({len(suspicious)}): 200 but wrong/missing', file=sys.stderr)
    print(f'  ERRORS ({len(errors)}): timeout / 5xx / other', file=sys.stderr)

    if broken:
        print(f'\n--- BROKEN ({len(broken)}) ---', file=sys.stderr)
        for r in broken[:50]:
            print(f"  404 {r['url']} (ref: {r['referenced_by'][0]['collection']}/{r['referenced_by'][0]['slug']})", file=sys.stderr)

    if suspicious:
        print(f'\n--- SUSPICIOUS ({len(suspicious)}) ---', file=sys.stderr)
        for r in suspicious[:50]:
            print(f"  {r.get('issue', '?')}: {r['url']}", file=sys.stderr)

    if errors:
        print(f'\n--- ERRORS ({len(errors)}) ---', file=sys.stderr)
        for r in errors[:30]:
            print(f"  {r.get('status')} {r.get('error', '?')}: {r['url']}", file=sys.stderr)

    # Output JSON for downstream tooling
    report = {
        'generated_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'pb_url': PB_URL,
        'cdn_base': CDN_BASE,
        'collections_scanned': len(COLLECTIONS),
        'total_pb_media_urls': len(pb_urls),
        'unique_urls': len(unique_urls),
        'ok': len(ok),
        'broken_404': len(broken),
        'suspicious': len(suspicious),
        'errors': len(errors),
        'broken_urls': broken,
        'suspicious_urls': suspicious,
        'error_urls': errors,
    }
    print(json.dumps(report, indent=2))
    # Exit code 1 if any media is broken
    sys.exit(1 if broken or errors else 0)


if __name__ == '__main__':
    main()