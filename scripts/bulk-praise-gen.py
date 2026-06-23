#!/usr/bin/env python3
"""
HEAL — bulk-generate 100 praise songs in batches of 4.
Pipeline per song:
  1. AI instrumental (text-to-music) — 30-60s of music
  2. TTS vocal lead (text-to-speech) — slow, emotional
  3. ffmpeg amix — voice 1.2x + instrumental 0.55x → -10dB peak
  4. Upload to CDN via FTP (via lftp)
  5. Backfill PB HEAL_praise record with audio_url

Concurrency: 4 parallel songs. Expected wall time: ~4-6 hours for 100.
"""
import os
import sys
import json
import time
import subprocess
import urllib.request
import urllib.error
import shutil
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

WORK_DIR = Path('/workspace/.mavis-cache/heal-song-gen')
SONG_LIST = Path('/workspace/HEAL/scripts/song-100-list.json')
PB_URL = os.environ.get('PB_URL')
PB_IDENTITY = os.environ.get('PB_IDENTITY')
PB_PASSWORD = os.environ.get('PB_PASSWORD')
CDN_BASE = 'https://resources.positiveness.club/heal'

VOICE_MAP = {
    'Serene Woman': 'English_SereneWoman',
    'Sentimental Lady': 'English_SentimentalLady',
    'Captivating Storyteller': 'English_CaptivatingStoryteller',
    'Upbeat Woman': 'English_Upbeat_Woman',
    'Passionate Warrior': 'English_PassionateWarrior',
    'Friendly Guy': 'English_FriendlyPerson',
    'Gentle-voiced Man': 'English_Gentle-voiced_man',
}

# Instrumental prompt templates by mood
INSTR_PROMPTS = {
    'reverent': 'gentle piano with sustained strings, sacred and contemplative, soft dynamics, minor key, no vocals, 45 seconds, single take',
    'gentle': 'acoustic guitar with soft pad, warm and tender, folk feel, mid-tempo, no vocals, 45 seconds',
    'intimate': 'solo piano, close mic, very quiet and sparse, breath between notes, no vocals, 45 seconds',
    'joyful': 'acoustic guitar strumming with light brush percussion, major key, celebratory, no vocals, 45 seconds',
    'classic_warm': 'hymn piano with soft organ pad, 4-part harmony feel, traditional, mid-tempo, no vocals, 45 seconds',
    'triumphant': 'orchestral brass with timpani and full strings, grand and victorious, major key, no vocals, 45 seconds',
    'stately': 'pipe organ with brass choir, regal, slow, formal, no vocals, 45 seconds',
    'bittersweet': 'solo cello with piano accompaniment, melancholy then hope, slow, emotional arc, no vocals, 45 seconds',
    'yearning': 'solo violin sustained, emotional, slow, minor key, no vocals, 45 seconds',
    'contemplative': 'singing bowl with ambient pad and gentle drone, very slow, meditative, no vocals, 45 seconds',
    'mournful_to_hopeful': 'piano and strings, lamenting then lifting, slow, emotional arc, no vocals, 45 seconds',
    'declarative': 'mid-tempo piano, steady rhythm, confident, present, no vocals, 45 seconds',
    'lamentful': 'solo piano, slow, in minor key, with sighing phrases, no vocals, 45 seconds',
}

# Speed by mood
SPEED_BY_MOOD = {
    'intimate': 0.78,
    'contemplative': 0.78,
    'reverent': 0.82,
    'gentle': 0.85,
    'bittersweet': 0.85,
    'lamentful': 0.82,
    'yearning': 0.85,
    'mournful_to_hopeful': 0.88,
    'classic_warm': 0.88,
    'declarative': 0.90,
    'stately': 0.88,
    'joyful': 0.95,
    'triumphant': 0.92,
}

# Emotion for TTS
EMOTION_BY_CATEGORY = {
    'hymns_classic': 'neutral',
    'contemporary_praise': 'happy',
    'scripture_chants': 'neutral',
    'communion_sacred': 'neutral',
}


def make_lyrics(song):
    """Build a singable text passage for the song. Real lyrics get added
    to PB later by the user. This generates a short passage that the
    TTS voice can sing with the title as anchor."""
    title = song['title']
    scripture = song.get('scripture', '')
    cat = song.get('category', 'hymns_classic')

    if cat == 'scripture_chants':
        return f"{title}... {scripture}... {title}... {scripture}... {title}..."
    if cat == 'communion_sacred':
        return f"{title}. {scripture}. In the bread, in the cup, You are here. {title}."
    if cat == 'contemporary_praise':
        return f"{title}. {scripture}. {title}. {title}. {scripture}. {title}."

    return f"{title}, {title}, sing the song of {title.lower()}. {scripture}. {title}, {title}, all my days, all my days."


def get_instr_prompt(song):
    mood = song.get('mood', 'gentle')
    base = INSTR_PROMPTS.get(mood, INSTR_PROMPTS['gentle'])
    key = song.get('key', 'D major')
    tempo = song.get('tempo', 'slow')
    return f"{base}, in {key}, {tempo} tempo"


def stage1_instr(song, slug):
    """Generate instrumental. Returns path to the generated mp3."""
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    out = WORK_DIR / f'{slug}-instr.mp3'
    if out.exists() and out.stat().st_size > 5000:
        return out
    prompt = get_instr_prompt(song)
    # Write prompt file so the tool can be invoked separately
    (WORK_DIR / f'{slug}-instr-prompt.txt').write_text(prompt)
    return None  # actual gen happens outside this script via the tool


def stage2_vocal(song, slug):
    """Build vocal text. Returns text + voice + speed + emotion."""
    voice = VOICE_MAP.get(song.get('voice', 'Serene Woman'), 'English_SereneWoman')
    speed = SPEED_BY_MOOD.get(song.get('mood', 'gentle'), 0.85)
    emotion = EMOTION_BY_CATEGORY.get(song.get('category'), 'neutral')
    text = song.get('lyrics') or make_lyrics(song)
    return text, voice, speed, emotion


def stage3_mix(slug):
    """ffmpeg mix: vocal + instrumental → -10 dB peak."""
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    vocal = WORK_DIR / f'{slug}-vocal.mp3'
    instr = WORK_DIR / f'{slug}-instr.mp3'
    final = WORK_DIR / f'song-{slug}.mp3'
    if final.exists() and final.stat().st_size > 5000:
        return final
    if not (vocal.exists() and instr.exists()):
        return None
    # 1.5s fade in, 2s fade out, amix voice 1.2x + instr 0.55x
    cmd = [
        'ffmpeg', '-y',
        '-i', str(vocal),
        '-i', str(instr),
        '-filter_complex',
        f'[0:a]volume=1.2,afade=t=in:st=0:d=1.5,afade=t=out:st=58:d=2[v];'
        f'[1:a]volume=0.55,afade=t=in:st=0:d=1.5,afade=t=out:st=58:d=2[i];'
        f'[v][i]amix=inputs=2:duration=first,alimiter=limit=0.95,dynaudnorm=p=0.95[a]',
        '-map', '[a]',
        '-ac', '2', '-ar', '44100', '-b:a', '128k',
        str(final)
    ]
    try:
        subprocess.run(cmd, capture_output=True, timeout=120, check=True)
        return final if final.exists() else None
    except Exception as e:
        print(f'  mix error {slug}: {e}')
        return None


def stage4_upload(slug):
    """Upload to CDN via FTP."""
    final = WORK_DIR / f'song-{slug}.mp3'
    if not final.exists():
        return None
    user = os.environ.get('SMARTERASP_FTP_USER', 'respc')
    pw = os.environ.get('SMARTERASP_FTP_PASSWORD', 'R3sourceSc4leupCRM!')
    # Use lftp single-file put
    cmd = [
        'lftp', '-u', f'{user},{pw}', f'ftp://win8108.site4now.net',
        '-e',
        f'set ftp:passive-mode true; set net:connection-limit 1; set net:timeout 30; put {final} -o heal/audio/praise/song-{slug}.mp3; quit'
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            return f'{CDN_BASE}/audio/praise/song-{slug}.mp3'
        else:
            print(f'  upload error {slug}: {result.stderr[:200]}')
            return None
    except Exception as e:
        print(f'  upload error {slug}: {e}')
        return None


def stage5_pb(song, slug, audio_url):
    """Create or update HEAL_praise record."""
    if not audio_url:
        return False
    # Auth
    r = urllib.request.urlopen(urllib.request.Request(
        f'{PB_URL}/api/collections/_superusers/auth-with-password',
        data=json.dumps({'identity': PB_IDENTITY, 'password': PB_PASSWORD}).encode(),
        headers={'Content-Type': 'application/json'},
        method='POST',
    ), timeout=15)
    token = json.loads(r.read())['token']

    # Check if record exists by slug
    r = urllib.request.urlopen(urllib.request.Request(
        f'{PB_URL}/api/collections/HEAL_praise/records?perPage=1&filter=slug%3D"{slug}"',
        headers={'Authorization': token},
    ), timeout=15)
    data = json.loads(r.read())
    items = data.get('items', [])

    body = {
        'title': song['title'],
        'slug': slug,
        'subtitle': f"A {song.get('category', 'hymn').replace('_', ' ')} · {song.get('emotion', 'settled')}",
        'lyrics': song.get('lyrics') or make_lyrics(song),
        'audio_url': audio_url,
        'illustration_url': f'{CDN_BASE}/images/praise/praise-{slug}.png',
        'category': song.get('category', '').replace('_', ' '),
        'emotion': song.get('emotion', 'settled'),
        'mood': song.get('mood', 'gentle'),
        'voice': song.get('voice', 'Serene Woman'),
        'is_published': True,
        'scripture_refs': [song.get('scripture', '')] if song.get('scripture') else [],
    }
    if items:
        rec_id = items[0]['id']
        r = urllib.request.urlopen(urllib.request.Request(
            f'{PB_URL}/api/collections/HEAL_praise/records/{rec_id}',
            data=json.dumps(body).encode(),
            headers={'Content-Type': 'application/json', 'Authorization': token},
            method='PATCH',
        ), timeout=15)
    else:
        r = urllib.request.urlopen(urllib.request.Request(
            f'{PB_URL}/api/collections/HEAL_praise/records',
            data=json.dumps(body).encode(),
            headers={'Content-Type': 'application/json', 'Authorization': token},
            method='POST',
        ), timeout=15)
    return r.status in (200, 201)


def prepare(song, idx):
    slug = song['slug']
    instr = stage1_instr(song, slug)
    vocal_text, voice, speed, emotion = stage2_vocal(song, slug)
    (WORK_DIR / f'{slug}-info.json').write_text(json.dumps({
        'slug': slug,
        'title': song['title'],
        'category': song.get('category'),
        'voice': voice,
        'speed': speed,
        'emotion': emotion,
        'vocal_text': vocal_text,
        'instr_prompt': get_instr_prompt(song),
    }, indent=2))
    print(f'  [{idx}] prepared: {slug} (voice={voice}, speed={speed})')
    return slug


def main():
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    data = json.loads(SONG_LIST.read_text())
    songs = data['songs']
    print(f'=== HEAL bulk praise: {len(songs)} songs ===')
    print(f'Categories: {dict((c, sum(1 for s in songs if s.get("category")==c)) for c in set(s.get("category","") for s in songs))}')

    # Stage 1: Prepare prompts + texts for all songs
    for i, s in enumerate(songs, 1):
        prepare(s, i)

    print(f'\n=== {len(songs)} songs prepared. Prompt files in {WORK_DIR}/ ===')
    print('Use the mavis batch_text_to_music and batch_synthesize_speech tools to actually generate audio, then run stage3 (mix), stage4 (upload), stage5 (PB).')


if __name__ == '__main__':
    main()