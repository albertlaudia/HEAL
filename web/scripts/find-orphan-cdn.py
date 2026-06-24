#!/usr/bin/env python3
"""
HEAL — Find orphan CDN files.

Strategy: we know all CDN URLs that PB references (good or broken).
We also know the subdirectories the media lives in. We can:
1. Brute-force HEAD-check a list of plausible filenames per subdirectory
2. Or use a manifest we keep up-to-date

This script walks a directory tree by checking every plausible filename
in the known set of CDN paths and reports which exist on the CDN but are
NOT referenced by any PB record.

Usage: pass a list of slugs (meditations, praise, etc.) and the script
checks the corresponding illustration+audio paths.
"""
import os
import sys
import json
import time
import urllib.request
import urllib.error
import concurrent.futures
from collections import defaultdict

PB_URL = os.environ.get('PB_URL', 'https://pocketbase.scaleupcrm.com')
PB_IDENTITY = os.environ.get('PB_IDENTITY')
PB_PASSWORD = os.environ.get('PB_PASSWORD')

CDN_BASE = 'https://resources.positiveness.club/heal'

# Plausible filenames per category
AUDIO_PATTERNS = ['song-{slug}.mp3', 'audio-{slug}.mp3', 'ambient-{slug}.mp3']
IMAGE_PATTERNS = ['illustration-{slug}.png', 'praise-{slug}.png', 'prayer-{slug}.png',
                  'essay-{slug}.png', 'program-{slug}.png', 'meditation-{slug}.png',
                  'badge-{slug}.webp', 'icon-{slug}.png', 'cover-{slug}.png']


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
    try:
        req = urllib.request.Request(url, method='HEAD')
        req.add_header('User-Agent', 'HEAL-MediaAudit/1.0')
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, int(r.headers.get('content-length', 0) or 0)
    except urllib.error.HTTPError as e:
        return e.code, 0
    except Exception as e:
        return 0, 0


def auth():
    r = http_post(
        f'{PB_URL}/api/collections/_superusers/auth-with-password',
        {'identity': PB_IDENTITY, 'password': PB_PASSWORD})
    return json.loads(r.read())['token']


def list_records(token, collection, page_size=200):
    items = []
    for page in range(1, 50):
        r = http_get(
            f'{PB_URL}/api/collections/{collection}/records?perPage={page_size}&page={page}',
            token)
        d = json.loads(r.read())
        items.extend(d.get('items', []))
        if len(d.get('items', [])) < page_size:
            break
    return items


def main():
    token = auth()

    # Collect all referenced slugs from PB
    slugs = defaultdict(set)  # category -> set of slugs
    all_referenced_urls = set()

    for col in ['HEAL_meditations', 'HEAL_praise', 'HEAL_prayers', 'HEAL_essays', 'HEAL_breathwork', 'HEAL_programs', 'HEAL_program_steps']:
        for rec in list_records(token, col):
            slug = rec.get('slug')
            if not slug:
                continue
            category = col.replace('HEAL_', '')
            slugs[category].add(slug)
            for field in ('audio_url', 'illustration_url'):
                url = rec.get(field)
                if url and 'resources.positiveness.club' in url:
                    all_referenced_urls.add(url)

    print(f'Referenced URLs from PB: {len(all_referenced_urls)}', file=sys.stderr)
    for cat, s in slugs.items():
        print(f'  {cat}: {len(s)} slugs', file=sys.stderr)

    # Build list of candidate URLs to check
    candidate_urls = set()
    for cat, slugset in slugs.items():
        for slug in slugset:
            if cat in ('meditations',):
                candidate_urls.add(f'{CDN_BASE}/images/meditations/illustration-{slug}.png')
                candidate_urls.add(f'{CDN_BASE}/audio/meditations/audio-{slug}.mp3')
            elif cat in ('praise',):
                candidate_urls.add(f'{CDN_BASE}/images/praise/praise-{slug}.png')
                candidate_urls.add(f'{CDN_BASE}/audio/praise/song-{slug}.mp3')
            elif cat in ('prayers',):
                candidate_urls.add(f'{CDN_BASE}/images/prayers/prayer-{slug}.png')
            elif cat in ('essays',):
                candidate_urls.add(f'{CDN_BASE}/images/essays/essay-{slug}.png')
            elif cat in ('breathwork',):
                candidate_urls.add(f'{CDN_BASE}/audio/ambient/ambient-{slug}.mp3')
            elif cat in ('programs',):
                candidate_urls.add(f'{CDN_BASE}/images/programs/program-{slug}.png')

    print(f'\nCandidate URLs to probe: {len(candidate_urls)}', file=sys.stderr)

    # Probe in parallel
    print('Probing CDN...', file=sys.stderr)
    found = {}  # url -> (status, size)
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
        for url, result in zip(candidate_urls, ex.map(head_url, candidate_urls)):
            status, size = result
            if status == 200 and size > 0:
                found[url] = (status, size)

    print(f'CDN files found (probed by name): {len(found)}', file=sys.stderr)

    # Now: orphan = exists on CDN but NOT referenced by PB
    orphans = []
    for url, (s, sz) in found.items():
        if url not in all_referenced_urls:
            orphans.append({'url': url, 'size': sz})

    print(f'\nORPHAN CDN FILES (exist on CDN, not referenced by PB): {len(orphans)}', file=sys.stderr)
    for o in orphans[:50]:
        print(f"  {o['size']:>10} bytes  {o['url']}", file=sys.stderr)

    # Also report referenced-but-broken (URL is in PB but 404s)
    print(f'\nProbing PB-referenced URLs to find broken...', file=sys.stderr)
    broken = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
        for url, result in zip(all_referenced_urls, ex.map(head_url, all_referenced_urls)):
            status, size = result
            if status != 200 or size == 0:
                broken.append(url)

    print(f'BROKEN: {len(broken)}', file=sys.stderr)
    for b in broken[:20]:
        print(f'  {b}', file=sys.stderr)

    report = {
        'generated_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'pb_referenced_urls': len(all_referenced_urls),
        'cdn_files_probed_and_found': len(found),
        'orphan_files': len(orphans),
        'broken_references': len(broken),
        'orphans': orphans,
        'broken': broken,
    }
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()