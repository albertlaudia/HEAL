#!/usr/bin/env python3
"""
HEAL — Backfill the new `emotion` field on existing records.

Deterministic mapping from existing category/theme values to emotion:
  - 'morning', 'dawn' → 'hope'
  - 'evening', 'night' → 'rest'
  - 'gratitude', 'praise' → 'gratitude'
  - 'let-go', 'forgiveness' → 'forgiveness'
  - 'calm', 'peace', 'stillness' → 'peace'
  - 'anxiety', 'fear' → 'anxiety'
  - 'courage', 'strength' → 'courage'
  - 'rest', 'tired' → 'rest'
  - 'focus', 'wisdom' → 'wonder'
  - 'love' → 'love'
  - 'joy' → 'joy'
  - 'grief', 'sorrow' → 'grief'
  - default → 'comfort' (catch-all)
"""
import os, json, urllib.request, urllib.error, hashlib

PB_URL = os.environ['PB_URL']
PB_IDENTITY = os.environ['PB_IDENTITY']
PB_PASSWORD = os.environ['PB_PASSWORD']

# Category → emotion mapping
CAT_TO_EMOTION = {
    # Prayer
    'morning': 'hope', 'evening': 'rest', 'anxiety': 'anxiety',
    'gratitude': 'gratitude', 'forgiveness': 'forgiveness', 'strength': 'courage',
    'rest': 'rest', 'stillness': 'peace', 'let-go': 'forgiveness',
    'love': 'love', 'courage': 'courage', 'focus': 'wonder',
    'calm': 'peace', 'hope': 'hope', 'wisdom': 'wonder', 'grace': 'love',
    # Quote
    'evening': 'rest', 'morning': 'hope', 'forgiveness': 'forgiveness',
    'anxiety': 'anxiety', 'stillness': 'peace', 'let-go': 'forgiveness',
    'focus': 'wonder', 'calm': 'peace',
    # Scripture theme
    'calm': 'peace', 'gratitude': 'gratitude', 'let-go': 'forgiveness',
    'love': 'love', 'focus': 'wonder', 'stillness': 'peace', 'courage': 'courage',
    'rest': 'rest', 'hope': 'hope', 'wisdom': 'wonder', 'energy': 'joy',
    'grace': 'love', 'strength': 'courage', 'peace': 'peace', 'joy': 'joy',
}

VALID_EMOTIONS = ['joy','sorrow','fear','peace','anxiety','gratitude','grief','anger','hope','longing','comfort','courage','love','rest','stillness','forgiveness','wonder','tender','weary','steady']


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


def map_emotion(category):
    return CAT_TO_EMOTION.get(category, 'comfort')


def backfill_collection(token, col, category_field):
    items = []
    page = 1
    while True:
        d = json.loads(get(f'{PB_URL}/api/collections/{col}/records?perPage=500&page={page}&fields=id,{category_field},emotion', token).read())
        items.extend(d.get('items', []))
        if len(d.get('items', [])) < 500:
            break
        page += 1

    needs_update = [it for it in items if not it.get('emotion')]
    print(f'  {col}: {len(items)} total, {len(needs_update)} need emotion set')

    updated = 0
    for it in needs_update:
        cat = it.get(category_field) or ''
        emotion = map_emotion(cat)
        if emotion not in VALID_EMOTIONS:
            emotion = 'comfort'
        try:
            patch(f'{PB_URL}/api/collections/{col}/records/{it["id"]}',
                  {'emotion': emotion}, token)
            updated += 1
        except Exception as e:
            print(f'  ✗ {it["id"]}: {e}')
    print(f'  ✓ Updated {updated}')


def main():
    token = json.loads(post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
                             {'identity': PB_IDENTITY, 'password': PB_PASSWORD}).read())['token']

    print('=== HEAL_prayers (category → emotion) ===')
    backfill_collection(token, 'HEAL_prayers', 'category')

    print('\n=== HEAL_quotes (category → emotion) ===')
    backfill_collection(token, 'HEAL_quotes', 'category')

    print('\n=== HEAL_scriptures (theme → emotion) ===')
    backfill_collection(token, 'HEAL_scriptures', 'theme')

    print('\n=== HEAL_praise (use deterministic from slug) ===')
    backfill_collection(token, 'HEAL_praise', 'category')

    print('\n=== Done ===')


if __name__ == '__main__':
    main()