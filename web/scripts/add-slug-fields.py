#!/usr/bin/env python3
"""Add slug field + UNIQUE index to HEAL_scriptures and HEAL_quotes."""
import os, json, urllib.request, urllib.error

PB_URL = os.environ['PB_URL']
PB_IDENTITY = os.environ['PB_IDENTITY']
PB_PASSWORD = os.environ['PB_PASSWORD']


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


def auth():
    r = post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
             {'identity': PB_IDENTITY, 'password': PB_PASSWORD})
    return json.loads(r.read())['token']


def main():
    token = auth()
    for col in ['HEAL_scriptures', 'HEAL_quotes']:
        d = json.loads(get(f'{PB_URL}/api/collections/{col}', token).read())
        fields = d['fields']
        indexes = d['indexes']

        # Add slug field if missing
        if not any(f['name'] == 'slug' for f in fields):
            fields.append({
                'name': 'slug', 'type': 'text', 'required': False,
                'presentable': False, 'system': False,
                'options': {'min': 0, 'max': 200, 'pattern': ''},
            })
        # Add unique slug index if missing
        unique_idx = f'CREATE UNIQUE INDEX idx_{col}_slug ON {col} (slug)'
        if unique_idx not in indexes:
            indexes.append(unique_idx)
        try:
            patch(f'{PB_URL}/api/collections/{col}', {'fields': fields, 'indexes': indexes}, token)
            print(f'✓ {col}: added slug + unique index')
        except urllib.error.HTTPError as e:
            print(f'✗ {col}: {e.read().decode()[:300]}')


if __name__ == '__main__':
    main()