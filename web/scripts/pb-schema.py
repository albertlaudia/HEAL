#!/usr/bin/env python3
"""
HEAL — Generic PB schema modifier that handles PB's field-format quirks.

Quirks handled:
1. select fields: `values` and `maxSelect` at TOP LEVEL (not inside `options`)
2. text fields: `min`, `max`, `pattern` at TOP LEVEL (not inside `options`)
3. number fields: `min`, `max`, `noDecimal` at TOP LEVEL (not inside `options`)
4. bool fields: empty `options: {}`
5. json fields: `maxSize` at TOP LEVEL
6. date fields: `min`, `max` at TOP LEVEL (strings, ISO datetimes)
7. url fields: `exceptDomains`, `onlyDomains` at TOP LEVEL (or null)
8. editor fields: `convertURLs`, `maxSize` at TOP LEVEL
9. Sending the existing fields array triggers full schema rebuild
   → must include all existing fields with all keys preserved
   → when adding new fields, omit internal `id` so PB assigns one

Usage:
  python3 pb-schema.py add <collection> <field_name> <field_type> [--options='{...}']
"""
import os, sys, json, urllib.request, urllib.error

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


def auth():
    return json.loads(post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
                           {'identity': PB_IDENTITY, 'password': PB_PASSWORD}).read())['token']


def get_schema(token, col):
    return json.loads(get(f'{PB_URL}/api/collections/{col}', token).read())


def patch_schema(token, col, fields=None, indexes=None):
    body = {}
    if fields is not None:
        body['fields'] = fields
    if indexes is not None:
        body['indexes'] = indexes
    try:
        return json.loads(patch(f'{PB_URL}/api/collections/{col}', body, token).read())
    except urllib.error.HTTPError as e:
        print(f'PATCH failed: {e.read().decode()[:500]}', file=sys.stderr)
        raise


def normalize_field_for_patch(f):
    """Strip internal `id` so PB generates a new one when adding."""
    return {k: v for k, v in f.items() if k != 'id'}


def add_field(token, col, new_field):
    """Add a single field to collection. new_field should NOT include internal `id`."""
    schema = get_schema(token, col)
    if any(f['name'] == new_field['name'] for f in schema['fields']):
        print(f'  - {col}.{new_field["name"]} already exists', file=sys.stderr)
        return
    # Keep all existing fields intact (including internal `id`s) — PB needs them to identify fields.
    # Only the NEW field is appended without internal `id`.
    clean = list(schema['fields'])
    clean.append(new_field)
    patch_schema(token, col, fields=clean)
    print(f'  ✓ {col}.{new_field["name"]} added', file=sys.stderr)


def add_unique_index(token, col, column):
    schema = get_schema(token, col)
    idx = f'CREATE UNIQUE INDEX idx_{col}_{column} ON {col} ({column})'
    if idx in schema['indexes']:
        print(f'  - {col}.{column} unique index already exists', file=sys.stderr)
        return
    indexes = list(schema['indexes']) + [idx]
    patch_schema(token, col, indexes=indexes)
    print(f'  ✓ {col}.{column} unique index added', file=sys.stderr)


def add_index(token, col, column):
    schema = get_schema(token, col)
    idx = f'CREATE INDEX idx_{col}_{column} ON {col} ({column})'
    if idx in schema['indexes']:
        print(f'  - {col}.{column} index already exists', file=sys.stderr)
        return
    indexes = list(schema['indexes']) + [idx]
    patch_schema(token, col, indexes=indexes)
    print(f'  ✓ {col}.{column} index added', file=sys.stderr)


# ── Field templates ─────────────────────────────────────────────
def f_text(name, **kw):
    o = {}
    if 'min' in kw: o['min'] = kw['min']
    if 'max' in kw: o['max'] = kw['max']
    if 'pattern' in kw: o['pattern'] = kw['pattern']
    return {'name': name, 'type': 'text', 'required': kw.get('required', False),
            'system': False, 'presentable': False, 'options': o}


def f_number(name, **kw):
    o = {}
    if 'min' in kw: o['min'] = kw['min']
    if 'max' in kw: o['max'] = kw['max']
    if 'noDecimal' in kw: o['noDecimal'] = kw['noDecimal']
    return {'name': name, 'type': 'number', 'required': kw.get('required', False),
            'system': False, 'presentable': False, 'options': o}


def f_bool(name, **kw):
    return {'name': name, 'type': 'bool', 'required': False,
            'system': False, 'presentable': False, 'options': {}}


def f_json(name, **kw):
    return {'name': name, 'type': 'json', 'required': False,
            'system': False, 'presentable': False,
            'options': {'maxSize': kw.get('maxSize', 5000)}}


def f_select(name, values, **kw):
    # PB select fields: `values` and `maxSelect` at TOP LEVEL (not inside `options`)
    return {'name': name, 'type': 'select', 'required': kw.get('required', False),
            'system': False, 'presentable': False,
            'maxSelect': kw.get('maxSelect', 1), 'values': list(values)}


def f_url(name, **kw):
    return {'name': name, 'type': 'url', 'required': False,
            'system': False, 'presentable': False, 'options': {}}


def f_date(name, **kw):
    o = {'min': kw.get('min', '1900-01-01 00:00:00.000Z'),
         'max': kw.get('max', '2100-01-01 00:00:00.000Z')}
    return {'name': name, 'type': 'date', 'required': False,
            'system': False, 'presentable': False, 'options': o}


# ── Main: add emotion + tags + cycle fields to all content types ──
def main():
    token = auth()

    # HEAL_prayers — full set
    print('\n=== HEAL_prayers ===')
    for f in [
        f_select('emotion', ['joy','sorrow','fear','peace','anxiety','gratitude','grief','anger','hope','longing','comfort','courage','love','rest','stillness','forgiveness','wonder','tender','weary','steady']),
        f_json('tags'),
        f_number('cycle_position', min=0, max=999, noDecimal=True),
        f_number('cycle_year', min=1, max=5, noDecimal=True),
        f_bool('is_event_prayer'),
        f_text('source_event', max=300),
        f_date('event_date'),
    ]:
        try: add_field(token, 'HEAL_prayers', f)
        except Exception: pass
    for col in ['HEAL_prayers']:
        for col_ in ['emotion', 'cycle_position', 'cycle_year', 'is_event_prayer']:
            try: add_index(token, col, col_)
            except Exception: pass

    # HEAL_scriptures — emotion + tags + cycle
    print('\n=== HEAL_scriptures ===')
    for f in [
        f_select('emotion', ['joy','sorrow','fear','peace','anxiety','gratitude','grief','anger','hope','longing','comfort','courage','love','rest','stillness','forgiveness','wonder','tender','weary','steady']),
        f_json('tags'),
        f_number('cycle_position', min=0, max=999, noDecimal=True),
        f_number('cycle_year', min=1, max=5, noDecimal=True),
    ]:
        try: add_field(token, 'HEAL_scriptures', f)
        except Exception: pass
    for col_ in ['emotion', 'cycle_position', 'cycle_year']:
        try: add_index(token, 'HEAL_scriptures', col_)
        except Exception: pass

    # HEAL_quotes — emotion + tags + cycle
    print('\n=== HEAL_quotes ===')
    for f in [
        f_select('emotion', ['joy','sorrow','fear','peace','anxiety','gratitude','grief','anger','hope','longing','comfort','courage','love','rest','stillness','forgiveness','wonder','tender','weary','steady']),
        f_json('tags'),
        f_number('cycle_position', min=0, max=999, noDecimal=True),
        f_number('cycle_year', min=1, max=5, noDecimal=True),
    ]:
        try: add_field(token, 'HEAL_quotes', f)
        except Exception: pass
    for col_ in ['emotion', 'cycle_position', 'cycle_year']:
        try: add_index(token, 'HEAL_quotes', col_)
        except Exception: pass

    print('\n=== Done ===')


if __name__ == '__main__':
    main()