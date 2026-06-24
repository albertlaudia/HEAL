#!/usr/bin/env python3
"""
HEAL — Deduplicate PB records + add unique slug indexes.

For each of HEAL_scriptures, HEAL_quotes, HEAL_prayers:
- Find groups of records with identical text/title/reference
- Keep the newest (by PB id, which is roughly time-ordered)
- Delete the older duplicates
- Add a `slug` field
- Add a UNIQUE index on slug

Run AFTER backfilling any prior cron-generated records that may have dups.
"""
import os
import sys
import json
import urllib.request
import urllib.error

PB_URL = os.environ.get('PB_URL', 'https://pocketbase.scaleupcrm.com')
PB_IDENTITY = os.environ.get('PB_IDENTITY')
PB_PASSWORD = os.environ.get('PB_PASSWORD')


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


def http_patch(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **({'Authorization': token} if token else {})},
        method='PATCH',
    ), timeout=15)


def http_delete(url, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': token} if token else {},
        method='DELETE',
    ), timeout=15)


def auth():
    r = http_post(
        f'{PB_URL}/api/collections/_superusers/auth-with-password',
        {'identity': PB_IDENTITY, 'password': PB_PASSWORD})
    return json.loads(r.read())['token']


# Map collection to the dedup key field
DEDUP_KEY = {
    'HEAL_scriptures': 'reference',
    'HEAL_quotes': 'text',
    'HEAL_prayers': 'title',
}


def list_all(token, col):
    items = []
    page = 1
    while True:
        r = http_get(
            f'{PB_URL}/api/collections/{col}/records?perPage=500&page={page}',
            token)
        d = json.loads(r.read())
        items.extend(d.get('items', []))
        if len(d.get('items', [])) < 500:
            break
        page += 1
    return items


def main():
    token = auth()
    print(f'Auth OK\n', file=sys.stderr)

    for col in ['HEAL_scriptures', 'HEAL_quotes', 'HEAL_prayers']:
        key_field = DEDUP_KEY[col]
        records = list_all(token, col)
        print(f'\n=== {col} — {len(records)} total ===', file=sys.stderr)

        # Group by key field (text). Keep the record with the longest id (newest in PB).
        groups = {}
        for r in records:
            k = (r.get(key_field) or '').strip().lower()
            if not k:
                continue
            groups.setdefault(k, []).append(r)

        # Find groups with > 1 record
        dupes_deleted = 0
        for key, items in groups.items():
            if len(items) > 1:
                # Sort by id (string-sorted lexicographic == roughly time-ordered for PB)
                items_sorted = sorted(items, key=lambda r: r['id'])
                keep = items_sorted[-1]  # newest = last in lexicographic order
                for dup in items_sorted[:-1]:
                    try:
                        http_delete(
                            f'{PB_URL}/api/collections/{col}/records/{dup["id"]}',
                            token)
                        dupes_deleted += 1
                    except Exception as e:
                        print(f'  ✗ failed to delete {dup["id"]}: {e}', file=sys.stderr)
        print(f'  Deleted {dupes_deleted} duplicate records', file=sys.stderr)

        # Add slug field + unique index
        r = http_get(f'{PB_URL}/api/collections/{col}', token)
        schema = json.loads(r.read())
        existing_field_names = {f['name'] for f in schema.get('fields', [])}
        existing_indexes = schema.get('indexes', [])

        new_fields = list(schema.get('fields', []))
        if 'slug' not in existing_field_names:
            new_fields.append({
                'name': 'slug',
                'type': 'text',
                'required': False,
                'presentable': False,
                'system': False,
                'options': {'min': 0, 'max': 200, 'pattern': ''},
            })

        unique_idx = f'CREATE UNIQUE INDEX idx_{col}_slug ON {col} (slug)'
        new_indexes = list(existing_indexes)
        if unique_idx not in new_indexes:
            new_indexes.append(unique_idx)

        if 'slug' not in existing_field_names or unique_idx not in existing_indexes:
            try:
                http_patch(
                    f'{PB_URL}/api/collections/{col}',
                    {'fields': new_fields, 'indexes': new_indexes},
                    token)
                print(f'  ✓ Added slug field + unique index to {col}', file=sys.stderr)
            except urllib.error.HTTPError as e:
                print(f'  ✗ Failed to update {col}: {e.read().decode()[:200]}', file=sys.stderr)
        else:
            print(f'  - {col} already has slug + index', file=sys.stderr)

    print('\n=== Done ===', file=sys.stderr)


if __name__ == '__main__':
    main()