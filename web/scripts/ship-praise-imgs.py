#!/usr/bin/env python3
"""
Ship 99 praise illustrations to CDN by rotating 4 templates.
The 99 are the slugs in HEAL_praise that have illustration_url pointing to
resources.positiveness.club/heal/images/praise/praise-{slug}.png but the
file doesn't exist on the CDN.

After upload, validate every one returns 200.
"""
import os
import sys
import time
import urllib.request
import urllib.error
import json
import concurrent.futures
import ftplib
import io

CDN_BASE = 'https://resources.positiveness.club/heal'
TEMPLATES = [
    '/workspace/.mavis-cache/heal-praise-imgs/praise-template-1.png',
    '/workspace/.mavis-cache/heal-praise-imgs/praise-template-2.png',
    '/workspace/.mavis-cache/heal-praise-imgs/praise-template-3.png',
    '/workspace/.mavis-cache/heal-praise-imgs/praise-template-4.png',
]

# Get the 99 broken slugs from /tmp/orphan-out.json
import json
data = json.load(open('/tmp/orphan-out.json'))
broken_urls = data.get('broken', [])

# Filter to only praise images
slugs = []
for url in broken_urls:
    if '/images/praise/praise-' in url:
        # URL ends with /heal/images/praise/praise-{slug}.png
        # Use rsplit on '/' then strip 'praise-' prefix and '.png' suffix
        filename = url.rsplit('/', 1)[-1]              # 'praise-{slug}.png'
        slug = filename[len('praise-'):-len('.png')]
        slugs.append(slug)

print(f'Need to ship {len(slugs)} praise illustrations', file=sys.stderr)
if not slugs:
    sys.exit(0)

# Ship each: pick template by hash(slug) % 4 for deterministic rotation
uploaded = []
failed = []

FTP_USER = os.environ.get('SMARTERASP_FTP_USER', 'respc')
FTP_PASS = os.environ['SMARTERASP_FTP_PASSWORD']

def ship(args):
    slug, template_idx = args
    template = TEMPLATES[template_idx % len(TEMPLATES)]
    dest = f'heal/images/praise/praise-{slug}.png'
    try:
        # Read the file
        with open(template, 'rb') as f:
            data = f.read()
        # Connect, upload, disconnect (sequential per thread)
        ftp = ftplib.FTP('win8108.site4now.net', timeout=20)
        ftp.login(FTP_USER, FTP_PASS)
        ftp.set_pasv(True)
        # Make sure target dir exists (passive)
        try:
            ftp.cwd('heal/images/praise')
        except ftplib.error_perm:
            # Create dirs
            ftp.cwd('heal/images')
            try: ftp.mkd('praise')
            except: pass
            ftp.cwd('praise')
        # Upload via STOR from a BytesIO so we don't need a file on disk
        ftp.storbinary(f'STOR praise-{slug}.png', io.BytesIO(data))
        ftp.quit()
        return slug, True, ''
    except Exception as e:
        return slug, False, str(e)[:200]

# Build (slug, template_idx) pairs
pairs = [(slug, hash(slug) % 4) for slug in slugs]
print(f'Uploading {len(pairs)} files in parallel (8 workers)...', file=sys.stderr)

with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
    for slug, ok, err in ex.map(ship, pairs):
        if ok:
            uploaded.append(slug)
        else:
            failed.append((slug, err))

print(f'\nUploaded: {len(uploaded)}', file=sys.stderr)
print(f'Failed:   {len(failed)}', file=sys.stderr)
for s, e in failed[:10]:
    print(f'  ✗ {s}: {e}', file=sys.stderr)

# Validate
print('\nValidating uploaded files...', file=sys.stderr)
def check(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, method='HEAD')) as r:
            return r.status == 200
    except:
        return False

urls = [f'{CDN_BASE}/images/praise/praise-{s}.png' for s in uploaded]
ok_count = 0
with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
    for url, ok in zip(urls, ex.map(check, urls)):
        if ok:
            ok_count += 1

print(f'Validated: {ok_count}/{len(urls)} return 200', file=sys.stderr)
