#!/usr/bin/env python3
"""
HEAL — Backfill the new `tags` JSON field on existing records.

Each record gets a tags array built from:
  - Its category/theme (as-is)
  - A few derived tags (morning/evening/short/long/contemplative/seasonal)
  - Slug-based keywords (e.g. "morning" from slug-morning-prayer)
"""
import os, json, urllib.request, re

PB_URL = os.environ['PB_URL']
PB_IDENTITY = os.environ['PB_IDENTITY']
PB_PASSWORD = os.environ['PB_PASSWORD']


def post(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **({'Authorization': token} if token else {})},
        method='POST'), timeout=15)


def get(url, token):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': token}), timeout=15)


def patch(url, body, token):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': token},
        method='PATCH'), timeout=15)


def slug_keywords(slug, text):
    """Extract tags from slug + text content."""
    s = (slug or '').lower()
    t = (text or '').lower()
    kws = set()

    for word in ['morning', 'evening', 'night', 'dawn', 'sunset', 'sunrise']:
        if word in s or word in t:
            kws.add(word)

    for word in ['gratitude', 'forgiveness', 'rest', 'courage', 'love', 'joy',
                 'peace', 'hope', 'grief', 'sorrow', 'fear', 'anxiety',
                 'tired', 'weary', 'strength', 'wisdom', 'patience', 'stillness']:
        if word in s or word in t:
            kws.add(word)

    for word in ['prayer', 'scripture', 'meditation', 'breath', 'praise', 'quote']:
        if word in s or word in t:
            kws.add(word)

    return list(kws)


def derive_tags(record, col, category_field):
    """Build a meaningful tags array."""
    cat = record.get(category_field) or ''
    text = record.get('text') or record.get('body') or record.get('lyrics') or ''
    title = record.get('title') or ''
    slug = record.get('slug') or ''

    # Start with category
    tags = []
    if cat:
        tags.append(cat)

    # Add slug-derived keywords
    keywords = slug_keywords(slug, f"{title} {text}")
    tags.extend(keywords)

    # Add structural tags based on col
    if col == 'HEAL_prayers':
        tags.append('prayer')
        # Length tag
        wc = len(text.split()) if text else 0
        if wc < 40:
            tags.append('short')
        elif wc < 100:
            tags.append('medium')
        else:
            tags.append('long')
    elif col == 'HEAL_scriptures':
        tags.append('scripture')
    elif col == 'HEAL_quotes':
        tags.append('quote')
        if len(text) < 100:
            tags.append('short')

    # Dedupe
    seen = set()
    out = []
    for t in tags:
        if t and t not in seen:
            seen.add(t)
            out.append(t)
    return out


def backfill(token, col, category_field):
    items = []
    page = 1
    while True:
        d = json.loads(get(f'{PB_URL}/api/collections/{col}/records?perPage=500&page={page}&fields=id,slug,title,text,body,lyrics,{category_field},tags', token).read())
        items.extend(d.get('items', []))
        if len(d.get('items', [])) < 500:
            break
        page += 1
    needs_update = [it for it in items if not it.get('tags') or not isinstance(it.get('tags'), list) or len(it['tags']) == 0]
    print(f'  {col}: {len(items)} total, {len(needs_update)} need tags set')

    updated = 0
    for it in needs_update:
        tags = derive_tags(it, col, category_field)
        try:
            patch(f'{PB_URL}/api/collections/{col}/records/{it["id"]}',
                  {'tags': tags}, token)
            updated += 1
        except Exception as e:
            print(f'  ✗ {it["id"]}: {e}')
    print(f'  ✓ Updated {updated}')


def main():
    token = json.loads(post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
                             {'identity': PB_IDENTITY, 'password': PB_PASSWORD}).read())['token']

    print('=== HEAL_prayers ===')
    backfill(token, 'HEAL_prayers', 'category')
    print('\n=== HEAL_quotes ===')
    backfill(token, 'HEAL_quotes', 'category')
    print('\n=== HEAL_scriptures ===')
    backfill(token, 'HEAL_scriptures', 'theme')
    print('\n=== Done ===')


if __name__ == '__main__':
    main()