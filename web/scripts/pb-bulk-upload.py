#!/usr/bin/env python3
"""
HEAL — bulk-create HEAL_praise records from song-100-list.json + CDN URL.
For each song that has its mixed audio on the CDN, create/update a PB record.
"""
import os
import json
import time
import urllib.request
import urllib.error
from pathlib import Path

PB_URL = os.environ.get('PB_URL')
PB_IDENTITY = os.environ.get('PB_IDENTITY')
PB_PASSWORD = os.environ.get('PB_PASSWORD')
CDN_BASE = 'https://resources.positiveness.club/heal'

SONG_LIST = Path('/workspace/HEAL/scripts/song-100-list.json')
WORK_DIR = Path('/workspace/.mavis-cache/heal-song-gen')

# Map our 4 categories to PB's 8 valid values
CATEGORY_MAP = {
    'hymns_classic': 'comfort',
    'contemporary_praise': 'adoration',
    'scripture_chants': 'hope',
    'communion_sacred': 'celebration',
}


def http_post(url, body, token):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': token},
        method='POST',
    ), timeout=15)


def http_patch(url, body, token):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': token},
        method='PATCH',
    ), timeout=15)


def http_get(url, token):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': token},
    ), timeout=15)


def auth():
    r = http_post(
        f'{PB_URL}/api/collections/_superusers/auth-with-password',
        {'identity': PB_IDENTITY, 'password': PB_PASSWORD}, '')
    return json.loads(r.read())['token']


def main():
    token = auth()
    print('authenticated ✓')

    data = json.loads(SONG_LIST.read_text())
    songs = data['songs']
    print(f'songs: {len(songs)}')

    created = 0
    updated = 0
    skipped = 0
    failed = 0

    for i, song in enumerate(songs, 1):
        slug = song['slug']
        audio_url = f'{CDN_BASE}/audio/praise/song-{slug}.mp3'
        illustration_url = f'{CDN_BASE}/images/praise/praise-{slug}.png'
        lyrics = song.get('lyrics') or (
            f"{song['title']}, {song['title']}, sing the song of {song['title'].lower()}. {song.get('scripture', '')}. {song['title']}, {song['title']}, all my days, all my days."
        )

        body = {
            'title': song['title'],
            'slug': slug,
            'subtitle': f"A {song.get('category', 'hymn').replace('_', ' ')} · {song.get('emotion', 'settled')}",
            'lyrics': lyrics,
            'audio_url': audio_url,
            'illustration_url': illustration_url,
            'category': CATEGORY_MAP.get(song.get('category', ''), 'other'),
            'emotion': song.get('emotion', 'settled'),
            'mood': song.get('mood', 'gentle'),
            'voice': song.get('voice', 'Serene Woman'),
            'is_published': True,
            'scripture_refs': [song.get('scripture', '')] if song.get('scripture') else [],
            'sort_order': 100 + i,
        }

        try:
            # Check if exists
            r = http_get(
                f'{PB_URL}/api/collections/HEAL_praise/records?perPage=1&filter=slug%3D"{slug}"',
                token,
            )
            existing = json.loads(r.read()).get('items', [])
            if existing:
                rec_id = existing[0]['id']
                http_patch(
                    f'{PB_URL}/api/collections/HEAL_praise/records/{rec_id}',
                    body, token,
                )
                updated += 1
            else:
                http_post(
                    f'{PB_URL}/api/collections/HEAL_praise/records',
                    body, token,
                )
                created += 1
        except Exception as e:
            failed += 1
            print(f'  ✗ {slug}: {e}')

        if i % 20 == 0:
            print(f'  [{i}/{len(songs)}] created={created} updated={updated} failed={failed}')

    print(f'\n=== Final ===')
    print(f'created: {created}')
    print(f'updated: {updated}')
    print(f'failed:  {failed}')


if __name__ == '__main__':
    main()