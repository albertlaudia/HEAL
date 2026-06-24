#!/usr/bin/env python3
"""
HEAL — Add slug field + UNIQUE slug index to a collection.
- Strips internal id from existing fields before PATCHing (PB quirk: keeps them when sending schema back)
- Backfills slug = slugified(key_field) + '-' + id_hash
- Adds UNIQUE slug index
"""
import os, sys, json, urllib.request, urllib.error, hashlib, re

PB_URL = os.environ['PB_URL']
PB_IDENTITY = os.environ['PB_IDENTITY']
PB_PASSWORD = os.environ['PB_PASSWORD']

KEY_FIELD = {
    'HEAL_scriptures': 'reference',
    'HEAL_quotes': 'text',
    'HEAL_prayers': 'title',
}


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


def slugify(s):
    s = re.sub(r'[^a-z0-9\s-]', '', (s or '').lower())
    s = re.sub(r'\s+', '-', s).strip('-')
    return s[:80] or 'unnamed'


def add_slug_field(token, col):
    """Add slug field to collection. Returns True on success."""
    d = json.loads(get(f'{PB_URL}/api/collections/{col}', token).read())
    if any(f['name'] == 'slug' for f in d['fields']):
        print(f'  - {col} already has slug field', file=sys.stderr)
        return True
    # Strip internal ids, keep all other keys (including `values` for select fields)
    clean = [{k: v for k, v in f.items() if k != 'id'} for f in d['fields'] if not f.get('system') or f.get('name') != 'id']
    # But keep 'id' field in if it has system=true (PB auto-adds it back if missing)
    # Actually, PB requires the system id field present — strip 'id' (internal) but keep system flag
    for f in clean:
        if f.get('name') == 'id':
            f['system'] = True
            f['required'] = True
            f['presentable'] = False
    clean.append({
        'name': 'slug', 'type': 'text', 'required': False,
        'presentable': False, 'system': False,
        'options': {'min': 0, 'max': 200, 'pattern': ''}
    })
    try:
        resp = json.loads(patch(f'{PB_URL}/api/collections/{col}',
                                {'fields': clean}, token).read())
        print(f'  ✓ {col} — added slug field', file=sys.stderr)
        return True
    except urllib.error.HTTPError as e:
        print(f'  ✗ {col} field add failed: {e.read().decode()[:300]}', file=sys.stderr)
        return False


def backfill_slugs(token, col):
    """Backfill slug on every record. Idempotent — overwrites existing slugs."""
    key = KEY_FIELD[col]
    items = []
    page = 1
    while True:
        d = json.loads(get(f'{PB_URL}/api/collections/{col}/records?perPage=500&page={page}&fields=id,{key}', token).read())
        items.extend(d.get('items', []))
        if len(d.get('items', [])) < 500:
            break
        page += 1
    print(f'  Backfilling {len(items)} records...', file=sys.stderr)
    updated = 0
    for it in items:
        base = slugify(it.get(key) or '')
        id_hash = hashlib.md5(it['id'].encode()).hexdigest()[:8]
        slug = f'{base}-{id_hash}'[:180]
        try:
            patch(f'{PB_URL}/api/collections/{col}/records/{it["id"]}', {'slug': slug}, token)
            updated += 1
        except Exception as e:
            print(f'  ✗ {it["id"]}: {e}', file=sys.stderr)
    print(f'  ✓ Backfilled {updated}', file=sys.stderr)
    return updated


def add_unique_index(token, col):
    """Add UNIQUE index on slug column."""
    d = json.loads(get(f'{PB_URL}/api/collections/{col}', token).read())
    unique = f'CREATE UNIQUE INDEX idx_{col}_slug ON {col} (slug)'
    indexes = list(d['indexes'])
    if unique in indexes:
        print(f'  - {col} already has unique slug index', file=sys.stderr)
        return True
    indexes.append(unique)
    try:
        patch(f'{PB_URL}/api/collections/{col}', {'indexes': indexes}, token)
        print(f'  ✓ {col} — added unique slug index', file=sys.stderr)
        return True
    except urllib.error.HTTPError as e:
        print(f'  ✗ {col} index failed: {e.read().decode()[:300]}', file=sys.stderr)
        return False


def main():
    token = json.loads(post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
                             {'identity': PB_IDENTITY, 'password': PB_PASSWORD}).read())['token']

    cols = sys.argv[1:] if len(sys.argv) > 1 else ['HEAL_scriptures', 'HEAL_quotes']
    for col in cols:
        print(f'\n=== {col} ===', file=sys.stderr)
        add_slug_field(token, col)
        backfill_slugs(token, col)
        add_unique_index(token, col)

    print('\n=== Done ===', file=sys.stderr)


if __name__ == '__main__':
    main()