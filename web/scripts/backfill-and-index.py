#!/usr/bin/env python3
"""
Backfill slug field with deterministic unique values, then add UNIQUE index.

For each existing record, slug = (key_field-slugified)[:80] + '-' + (8-char hash of id).
This ensures all values are unique, even if the key_field text is identical.
"""
import os, sys, json, urllib.request, hashlib, re

PB_URL = os.environ['PB_URL']
PB_IDENTITY = os.environ['PB_IDENTITY']
PB_PASSWORD = os.environ['PB_PASSWORD']

KEY = {
    'HEAL_scriptures': 'reference',
    'HEAL_quotes': 'text',
    'HEAL_prayers': 'title',
}


def post(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **({'Authorization': token} if token else {})},
        method='POST'), timeout=15)


def get(url, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': token} if token else {},
    ), timeout=15)


def patch(url, body, token):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': token},
        method='PATCH'), timeout=15)


def slugify(s):
    s = re.sub(r'[^a-z0-9\s-]', '', (s or '').lower())
    s = re.sub(r'\s+', '-', s).strip('-')
    return s[:80] or 'unnamed'


def main():
    token = post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
                 {'identity': PB_IDENTITY, 'password': PB_PASSWORD}).read()
    token = json.loads(token)['token']

    for col in ['HEAL_scriptures', 'HEAL_quotes']:
        key = KEY[col]
        # Fetch all with id + key field
        all_items = []
        page = 1
        while True:
            r = get(f'{PB_URL}/api/collections/{col}/records?perPage=500&page={page}&fields=id,{key}', token)
            d = json.loads(r.read())
            all_items.extend(d.get('items', []))
            if len(d.get('items', [])) < 500:
                break
            page += 1
        print(f'\n=== {col} ({len(all_items)} records) ===')

        # Backfill slug on each
        updated = 0
        for it in all_items:
            base = slugify(it.get(key) or '')
            id_hash = hashlib.md5(it['id'].encode()).hexdigest()[:8]
            new_slug = f'{base}-{id_hash}'[:180]
            try:
                patch(f'{PB_URL}/api/collections/{col}/records/{it["id"]}',
                      {'slug': new_slug}, token)
                updated += 1
                if updated % 20 == 0:
                    print(f'  {updated}/{len(all_items)}...')
            except Exception as e:
                print(f'  ✗ {it["id"]}: {e}')
        print(f'  ✓ Backfilled {updated} slugs')

        # Now add the field + unique index
        d = json.loads(get(f'{PB_URL}/api/collections/{col}', token).read())
        fields = d['fields']
        indexes = d['indexes']
        if not any(f['name'] == 'slug' for f in fields):
            fields.append({
                'name': 'slug', 'type': 'text', 'required': False,
                'presentable': False, 'system': False,
                'options': {'min': 0, 'max': 200, 'pattern': ''},
            })
        unique_idx = f'CREATE UNIQUE INDEX idx_{col}_slug ON {col} (slug)'
        if unique_idx not in indexes:
            indexes.append(unique_idx)
        try:
            patch(f'{PB_URL}/api/collections/{col}',
                  {'fields': fields, 'indexes': indexes}, token)
            print(f'  ✓ Added slug field + UNIQUE slug index')
        except Exception as e:
            print(f'  ✗ Index add failed: {e}')


if __name__ == '__main__':
    main()