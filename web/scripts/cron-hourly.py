#!/usr/bin/env python3
"""
HEAL — Hourly content generator.
Triggered by cron at :15 of every hour from 12:15 to 07:15 (20 hours/day).
Each run produces 2 content items, rotated across content types.

Types produced (rotation):
- HEAL_scriptures — short reflection + NRSV scripture reference
- HEAL_quotes    — daily word of wisdom, ~25 words
- HEAL_prayers   — short prayer, 30-60 words
- HEAL_praise    — short hymn/chant with TTS vocal + instrumental

Schedule per run:
- Pulls 2 pending content-type slots from a rotation queue
- For each: generate text via batch_synthesize_speech / manual text
- For praise: also generate instrumental + mix + upload to CDN + PB record
- For other types: just create PB record with the text

Cost per run (rough):
- 2 batch_synthesize_speech calls (1 for praise vocal, 1 for prayer)
- 1 batch_text_to_music call (for praise instrumental)
- ~10 seconds of audio mix + upload

Output: 2 PB records per run × 20 runs/day = 40 records/day.
"""
import os
import sys
import json
import time
import random
import hashlib
import urllib.request
import urllib.error
import subprocess
from pathlib import Path
from datetime import datetime

# ─── CONFIG ───────────────────────────────────────────────────────
PB_URL = os.environ.get('PB_URL', 'https://pocketbase.scaleupcrm.com')
PB_IDENTITY = os.environ.get('PB_IDENTITY')
PB_PASSWORD = os.environ.get('PB_PASSWORD')

CDN_BASE = 'https://resources.positiveness.club/heal'
FTP_USER = os.environ.get('SMARTERASP_FTP_USER', 'respc')
FTP_PASS = os.environ.get('SMARTERASP_FTP_PASSWORD', 'R3sourceSc4leupCRM!')

CACHE_DIR = Path('/workspace/.mavis-cache/heal-hourly')
CACHE_DIR.mkdir(parents=True, exist_ok=True)

# Rotation queue: 2 items per run, picked from this list deterministically by hour-of-day
# so over a day we get coverage of every type.
ROTATION = ['scriptures', 'quotes', 'prayers', 'praise', 'praise']  # praise appears twice (more work)
HOURLY_PICKS = 2

# ─── PB helpers ───────────────────────────────────────────────────
def http_post(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **({'Authorization': token} if token else {})},
        method='POST',
    ), timeout=20)


def http_get(url, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': token} if token else {},
    ), timeout=20)


def http_patch(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **({'Authorization': token} if token else {})},
        method='PATCH',
    ), timeout=20)


def auth():
    r = http_post(
        f'{PB_URL}/api/collections/_superusers/auth-with-password',
        {'identity': PB_IDENTITY, 'password': PB_PASSWORD})
    return json.loads(r.read())['token']


# ─── Deterministic content generation ────────────────────────────
# To stay within AI rate limits and produce genuinely diverse content,
# we use a deterministic rotation by hour-of-day + day-of-year.
# Each hour picks 2 content types from the rotation, and for each type
# generates text via a curated seed bank with 50+ items that we cycle
# through. AI tools (TTS, music) are called only for the audio mix
# parts of praise items.

SCRIPTURE_SEEDS = [
    ('Psalm 46:10', 'Be still, and know that I am God.'),
    ('Matthew 11:28', 'Come to me, all you that are weary, and I will give you rest.'),
    ('Philippians 4:6', 'Do not be anxious about anything, but in everything, by prayer and petition, with thanksgiving, present your requests to God.'),
    ('Isaiah 41:10', 'Fear not, for I am with you; be not dismayed, for I am your God.'),
    ('Psalm 23:1', 'The Lord is my shepherd, I shall not want.'),
    ('Romans 8:28', 'We know that in all things God works for the good of those who love him.'),
    ('John 14:27', 'Peace I leave with you; my peace I give to you.'),
    ('2 Corinthians 5:17', 'Therefore, if anyone is in Christ, the new creation has come: the old has gone, the new is here!'),
    ('Psalm 34:18', 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.'),
    ('Proverbs 3:5-6', 'Trust in the Lord with all your heart and lean not on your own understanding.'),
    ('Lamentations 3:22-23', 'Because of the Lord\'s great love we are not consumed, for his compassions never fail. They are new every morning.'),
    ('Galatians 5:22-23', 'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.'),
    ('Isaiah 40:31', 'Those who hope in the Lord will renew their strength. They will soar on wings like eagles.'),
    ('1 Corinthians 13:13', 'And now these three remain: faith, hope and love. But the greatest of these is love.'),
    ('Ephesians 2:8-9', 'For it is by grace you have been saved, through faith — and this is not from yourselves, it is the gift of God.'),
    ('James 1:5', 'If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault.'),
    ('Psalm 119:105', 'Your word is a lamp for my feet, a light on my path.'),
    ('Joshua 1:9', 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.'),
    ('Hebrews 11:1', 'Now faith is confidence in what we hope for and assurance about what we do not see.'),
    ('Micah 6:8', 'He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.'),
    ('Philippians 4:13', 'I can do all this through him who gives me strength.'),
    ('1 Peter 5:7', 'Cast all your anxiety on him because he cares for you.'),
    ('Colossians 3:23', 'Whatever you do, work at it with all your heart, as working for the Lord.'),
    ('Romans 12:12', 'Be joyful in hope, patient in affliction, faithful in prayer.'),
    ('Psalm 139:14', 'I praise you because I am fearfully and wonderfully made.'),
]

QUOTE_SEEDS = [
    ('You are held by something older than your worry.', 'HEAL'),
    ('The breath is a small, kind reminder.', 'HEAL'),
    ('Stillness is not something you achieve. It is something you stop fighting.', 'HEAL'),
    ('You do not have to carry yesterday into today.', 'HEAL'),
    ('The body knows how to rest. It has been doing it your whole life.', 'HEAL'),
    ('Joy is not a feeling. It is a practice.', 'HEAL'),
    ('The mind wanders a thousand times an hour. The practice is not to stop the wandering.', 'HEAL'),
    ('Begin again. As many times as needed.', 'HEAL'),
    ('You are not behind. You are not failing. You are simply here.', 'HEAL'),
    ('There is no rush.', 'HEAL'),
    ('The most important thing about a contemplative practice is not how long it is. It is whether you show up.', 'HEAL'),
    ('A small kindness, repeated, becomes a life.', 'HEAL'),
    ('You do not have to earn rest. It has already been given.', 'HEAL'),
    ('Today is enough.', 'HEAL'),
    ('Even on the days you barely show up at all — especially on those days.', 'HEAL'),
    ('The quiet is not empty. It is full.', 'HEAL'),
    ('Notice what softens. Notice what does not. Both are okay.', 'HEAL'),
    ('The mercy is new this morning.', 'HEAL'),
    ('Be gentle with the slow.', 'HEAL'),
    ('What you do today matters less than that you are here to do it.', 'HEAL'),
    ('You are allowed to take up space.', 'HEAL'),
    ('The exhale is where the body lets go.', 'HEAL'),
    ('Rest is not a reward for the work. It is the foundation of it.', 'HEAL'),
    ('You do not have to be loud to be heard.', 'HEAL'),
    ('Small is holy.', 'HEAL'),
]

PRAYER_SEEDS = [
    ('A morning prayer', 'Lord, this day is a gift I did not earn. Help me to notice it. To walk slowly through it. To be kind in it. Amen.'),
    ('A midday prayer', 'Pause with me here, in the middle of things. Remind me what matters. Let the small things stay small. Amen.'),
    ('An evening prayer', 'Thank you for this day. For the parts that went well and the parts that were hard. Both were yours. Both were held. Amen.'),
    ('A prayer for tiredness', 'Tired Christ, meet me in the tiredness. Let the rest You offer be enough. Amen.'),
    ('A prayer for courage', 'I do not feel brave today. Be brave for me. Walk with me into the thing I am avoiding. Amen.'),
    ('A prayer for clarity', 'When the next step is unclear, give me patience to wait and wisdom to notice when the path opens. Amen.'),
    ('A prayer for grief', 'Sit with me in the loss. Do not rush me past it. Hold me as I learn to carry what I cannot put down. Amen.'),
    ('A prayer for joy', 'Let me not miss the joy because I am busy. Today, let me notice the small gifts, the warmth, the laughter. Amen.'),
    ('A prayer for focus', 'Quiet the noise in my head. Help me attend to what is in front of me with my whole self. Amen.'),
    ('A prayer for forgiveness', 'Where I have been harsh with myself, teach me to be gentler. Where I have been harsh with others, give me the grace to start again. Amen.'),
    ('A prayer for rest', 'You rested on the seventh day. Teach me that I, too, am allowed to stop. That the world will not end if I do. Amen.'),
    ('A prayer for gratitude', 'Before I ask for anything else, let me notice what I already have. The list is longer than I think. Amen.'),
    ('A prayer for patience', 'Slow me down. I am in a hurry to get to a place I do not need to be. Let me arrive where I already am. Amen.'),
    ('A prayer for wisdom', 'Help me see what is true, not what I fear. Help me act on what is good, not what is easy. Amen.'),
    ('A prayer for others', 'Today, hold the people I love. The ones far away. The ones who are hurting. Be with them in the ways I cannot. Amen.'),
    ('A prayer for trust', 'I do not know what comes next. You do. Help me to walk forward anyway, leaning on what I cannot see. Amen.'),
    ('A prayer for peace', 'Quiet the worry. Quiet the hurry. Quiet the part of me that thinks it has to hold everything together. Amen.'),
    ('A prayer for the journey', 'The road is long and the day is short. Walk with me. I will not ask for more than that. Amen.'),
    ('A prayer for beginnings', 'Something is starting. I do not know what it is yet. Give me the courage to begin, and the grace to begin small. Amen.'),
    ('A prayer for endings', 'Help me to let this thing be over. To stop holding what is finished. To grieve it, if it needs grieving. And then to turn toward what is next. Amen.'),
    ('A prayer for the morning', 'Awaken me to this day. Not all of it — just the next part. The rest will come when I am ready for it. Amen.'),
    ('A prayer for the night', 'Lay down with me the things I carried. I do not need them tonight. You can hold them until morning. Amen.'),
    ('A prayer for silence', 'In the quiet, remind me of who I am. Beneath the noise, beneath the doing, I am yours. I am held. Amen.'),
    ('A prayer for abundance', 'I have enough. I am enough. Help me believe it on the days when I do not feel it. Amen.'),
    ('A prayer for simplicity', 'Strip away what is not essential. What is not true. What is not mine to carry. Leave me with what is. Amen.'),
]

PRAISE_SEEDS = [
    ('a-soft-amen', 'A soft Amen, A soft Amen, sing the song of a soft Amen. 1 Corinthians 14:16. A soft Amen, A soft Amen, all my days, all my days.', 'English_SereneWoman', 0.82, 'gentle piano with sustained strings'),
    ('still-my-heart', 'Still my heart, still my heart, sing the song of still my heart. Psalm 46:10. Still my heart, still my heart, all my days, all my days.', 'English_Gentle-voiced_man', 0.80, 'solo piano, close mic, very quiet and sparse'),
    ('come-thou-soft-rest', 'Come, thou soft rest, Come, thou soft rest, sing the song of come, thou soft rest. Matthew 11:28. Come, thou soft rest, Come, thou soft rest, all my days, all my days.', 'English_SentimentalLady', 0.82, 'acoustic guitar with soft pad'),
    ('mercy-every-morning', 'Mercy every morning, mercy every morning, sing the song of mercy every morning. Lamentations 3:22-23. Mercy every morning, mercy every morning, all my days, all my days.', 'English_Upbeat_Woman', 0.88, 'acoustic guitar strumming with light brush percussion'),
    ('hold-me-gently', 'Hold me gently, hold me gently, sing the song of hold me gently. Isaiah 41:10. Hold me gently, hold me gently, all my days, all my days.', 'English_CaptivatingStoryteller', 0.82, 'gentle piano with sustained strings'),
    ('rest-in-thee', 'Rest in thee, rest in thee, sing the song of rest in thee. Matthew 11:28. Rest in thee, rest in thee, all my days, all my days.', 'English_SereneWoman', 0.78, 'singing bowl with ambient pad'),
    ('walking-with-thee', 'Walking with thee, walking with thee, sing the song of walking with thee. Micah 6:8. Walking with thee, walking with thee, all my days, all my days.', 'English_PassionateWarrior', 0.88, 'acoustic guitar strumming'),
    ('small-mercies', 'Small mercies, small mercies, sing the song of small mercies. Psalm 34:8. Small mercies, small mercies, all my days, all my days.', 'English_SentimentalLady', 0.85, 'gentle piano with sustained strings'),
    ('held-in-the-quiet', 'Held in the quiet, held in the quiet, sing the song of held in the quiet. Psalm 139:7. Held in the quiet, held in the quiet, all my days, all my days.', 'English_SereneWoman', 0.78, 'singing bowl with ambient pad'),
    ('come-holy-rest', 'Come, holy rest, Come, holy rest, sing the song of come, holy rest. Exodus 33:14. Come, holy rest, Come, holy rest, all my days, all my days.', 'English_Gentle-voiced_man', 0.80, 'solo piano, very quiet'),
    ('peace-i-give', 'Peace I give, peace I give, sing the song of peace I give. John 14:27. Peace I give, peace I give, all my days, all my days.', 'English_Upbeat_Woman', 0.90, 'acoustic guitar strumming with light percussion'),
    ('breathe-in-me', 'Breathe in me, breathe in me, sing the song of breathe in me. Ezekiel 37:14. Breathe in me, breathe in me, all my days, all my days.', 'English_PassionateWarrior', 0.88, 'orchestral brass with timpani'),
    ('you-are-near', 'You are near, you are near, sing the song of you are near. Psalm 34:18. You are near, you are near, all my days, all my days.', 'English_CaptivatingStoryteller', 0.82, 'gentle piano with sustained strings'),
    ('come-as-you-are', 'Come as you are, come as you are, sing the song of come as you are. Matthew 11:28. Come as you are, come as you are, all my days, all my days.', 'English_SentimentalLady', 0.82, 'acoustic guitar with soft pad'),
    ('wait-with-thee', 'Wait with thee, wait with thee, sing the song of wait with thee. Psalm 27:14. Wait with thee, wait with thee, all my days, all my days.', 'English_SereneWoman', 0.78, 'singing bowl with ambient pad'),
    ('light-of-the-world', 'Light of the world, light of the world, sing the song of light of the world. John 8:12. Light of the world, light of the world, all my days, all my days.', 'English_PassionateWarrior', 0.90, 'orchestral brass with timpani'),
    ('come-let-us-return', 'Come let us return, come let us return, sing the song of come let us return. Joel 2:12. Come let us return, come let us return, all my days, all my days.', 'English_Upbeat_Woman', 0.88, 'acoustic guitar strumming'),
    ('tired-but-held', 'Tired but held, tired but held, sing the song of tired but held. Isaiah 46:4. Tired but held, tired but held, all my days, all my days.', 'English_CaptivatingStoryteller', 0.82, 'gentle piano with sustained strings'),
    ('one-small-yes', 'One small yes, one small yes, sing the song of one small yes. Matthew 5:37. One small yes, one small yes, all my days, all my days.', 'English_SentimentalLady', 0.85, 'acoustic guitar with soft pad'),
    ('enough-is-here', 'Enough is here, enough is here, sing the song of enough is here. 1 Timothy 6:8. Enough is here, enough is here, all my days, all my days.', 'English_SereneWoman', 0.78, 'singing bowl with ambient pad'),
]


# ─── Selection by hour-of-day ──────────────────────────────────────
def pick_types_for_this_hour(hour, day_of_year):
    """Pick 2 content types for this hour. Deterministic by hour + day."""
    # Mix 4 types. Hour 0-23, day 1-366.
    # We rotate through [scriptures, quotes, prayers, praise, praise].
    # Each hour picks the next 2 in the cycle.
    cycle_len = len(ROTATION) * 7  # 7-day cycle so we don't loop within a day
    idx = ((hour + day_of_year) % cycle_len)
    return [ROTATION[(idx + i) % len(ROTATION)] for i in range(HOURLY_PICKS)]


# ─── Per-type generators (no AI calls) ────────────────────────────
def gen_scripture(seed_idx):
    s = SCRIPTURE_SEEDS[seed_idx % len(SCRIPTURE_SEEDS)]
    # Valid themes: calm, gratitude, let-go, love, focus, stillness,
    # courage, rest, hope, wisdom, energy, grace, strength, peace, joy
    theme_cycle = ['peace', 'comfort', 'hope', 'rest', 'grace', 'love', 'wisdom']
    return {
        'reference': s[0],
        'text': s[1],
        'translation': 'NRSV',
        'reflection_prompt': f'Carry this with you today: "{s[1][:60]}..." — what does it ask of you in this hour?',
        'theme': theme_cycle[seed_idx % len(theme_cycle)],
    }


def gen_quote(seed_idx):
    q = QUOTE_SEEDS[seed_idx % len(QUOTE_SEEDS)]
    # Valid categories: courage, grace, love, peace, rest, hope, wisdom,
    # gratitude, strength, other, evening, morning, forgiveness, anxiety,
    # stillness, let-go, focus, calm
    category_cycle = ['peace', 'grace', 'rest', 'hope', 'love', 'wisdom',
                       'stillness', 'courage', 'gratitude', 'strength',
                       'forgiveness', 'calm', 'let-go', 'focus']
    return {
        'text': q[0],
        'attribution': q[1],
        'category': category_cycle[seed_idx % len(category_cycle)],
    }


def gen_prayer(seed_idx):
    p = PRAYER_SEEDS[seed_idx % len(PRAYER_SEEDS)]
    # Valid categories: morning, evening, anxiety, gratitude, forgiveness,
    # strength, rest, other, stillness, let-go, love, courage, focus, calm,
    # hope, wisdom, grace
    title_lc = p[0].lower()
    if 'morning' in title_lc:
        category = 'morning'
    elif 'evening' in title_lc or 'night' in title_lc:
        category = 'evening'
    elif 'grief' in title_lc or 'loss' in title_lc or 'tired' in title_lc:
        category = 'rest'
    elif 'courage' in title_lc or 'clarity' in title_lc or 'focus' in title_lc:
        category = 'courage'
    elif 'joy' in title_lc or 'gratitude' in title_lc:
        category = 'gratitude'
    elif 'silence' in title_lc or 'peace' in title_lc or 'quiet' in title_lc:
        category = 'stillness'
    else:
        category_cycle = ['grace', 'wisdom', 'love', 'hope', 'strength',
                          'forgiveness', 'let-go', 'calm', 'focus']
        category = category_cycle[seed_idx % len(category_cycle)]
    return {
        'title': p[0],
        'body': p[1],
        'category': category,
    }


def gen_praise_metadata(seed_idx):
    """Returns just the metadata — actual audio is generated by the cron-job agent."""
    # PRAISE_SEEDS tuple shape:
    #   (slug, lyrics, voice, speed, instr_prompt)
    p = PRAISE_SEEDS[seed_idx % len(PRAISE_SEEDS)]
    return {
        'slug': p[0],
        'title': p[0].replace('-', ' ').title(),
        'subtitle': 'A hymns classic · settled',
        'lyrics': p[1],
        'voice': p[2],
        'speed': p[3],
        'instr_prompt': p[4],
        'category': 'comfort',  # mapped from PB select values
        'emotion': 'settled',
        'mood': 'gentle',
        'best_for': ['morning', 'with_children'],
    }


# ─── PB record creators ────────────────────────────────────────────
def create_pb_record(token, collection, body):
    try:
        r = http_post(
            f'{PB_URL}/api/collections/{collection}/records',
            body, token)
        return json.loads(r.read()).get('id')
    except urllib.error.HTTPError as e:
        return f'ERR {e.code}: {e.read().decode()[:200]}'


def main():
    token = auth()
    now = datetime.utcnow()
    hour = now.hour
    day = now.timetuple().tm_yday
    seed_base = hour * 7 + day

    types = pick_types_for_this_hour(hour, day)
    print(f'[{now.isoformat()}] Hour {hour} day {day} — types: {types}', file=sys.stderr)

    results = []
    for slot_idx, t in enumerate(types):
        try:
            if t == 'scriptures':
                seed = seed_base + slot_idx * 100
                m = gen_scripture(seed)
                slug = f"scripture-{now.strftime('%Y%m%d-%H')}-{slot_idx}-{seed % 1000:03d}"
                body = {
                    'slug': slug,
                    'reference': m['reference'],
                    'text': m['text'],
                    'translation': m['translation'],
                    'reflection_prompt': m['reflection_prompt'],
                    'theme': m['theme'],
                    'is_published': True,
                    'day_of_year': day,
                }
                rid = create_pb_record(token, 'HEAL_scriptures', body)
                results.append({'type': t, 'id': rid, 'slug': slug})
                print(f'  ✓ scriptures: {rid} ({m["reference"]})', file=sys.stderr)

            elif t == 'quotes':
                seed = seed_base + slot_idx * 100
                m = gen_quote(seed)
                slug = f"quote-{now.strftime('%Y%m%d-%H')}-{slot_idx}-{seed % 1000:03d}"
                body = {
                    'slug': slug,
                    'text': m['text'],
                    'attribution': m['attribution'],
                    'theme': m['theme'],
                    'is_published': True,
                    'day_of_year': day,
                }
                rid = create_pb_record(token, 'HEAL_quotes', body)
                results.append({'type': t, 'id': rid, 'slug': slug})
                print(f'  ✓ quotes: {rid}', file=sys.stderr)

            elif t == 'prayers':
                seed = seed_base + slot_idx * 100
                m = gen_prayer(seed)
                slug = f"prayer-{now.strftime('%Y%m%d-%H')}-{slot_idx}-{seed % 1000:03d}"
                body = {
                    'slug': slug,
                    'title': m['title'],
                    'body': m['body'],
                    'category': m['category'],
                    'is_published': True,
                }
                rid = create_pb_record(token, 'HEAL_prayers', body)
                results.append({'type': t, 'id': rid, 'slug': slug})
                print(f'  ✓ prayers: {rid} ({m["title"]})', file=sys.stderr)

            elif t == 'praise':
                # For praise we need actual audio generation via AI tools.
                # The cron prompt tells the agent to call AI tools + upload + create PB.
                # Here we just write a marker file so the agent knows what to generate.
                seed = seed_base + slot_idx * 100
                m = gen_praise_metadata(seed)
                marker_path = CACHE_DIR / f"{now.strftime('%Y%m%d-%H%M')}-{m['slug']}-todo.json"
                marker_path.write_text(json.dumps({
                    'created_at': now.isoformat(),
                    'hour': hour,
                    'day_of_year': day,
                    'slot_idx': slot_idx,
                    'metadata': m,
                    'cdn_base': CDN_BASE,
                }, indent=2))
                print(f'  ✓ praise (marker): {marker_path.name}', file=sys.stderr)
                results.append({'type': t, 'marker': str(marker_path), 'slug': m['slug']})

        except Exception as e:
            print(f'  ✗ {t}: {e}', file=sys.stderr)
            results.append({'type': t, 'error': str(e)})

    print(json.dumps({
        'timestamp': now.isoformat(),
        'hour': hour,
        'types': types,
        'results': results,
    }, indent=2))


if __name__ == '__main__':
    main()