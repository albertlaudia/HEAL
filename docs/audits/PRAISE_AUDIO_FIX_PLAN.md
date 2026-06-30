# HEAL — Praise Audio Fix Plan
**Date:** 2026-06-30
**Problem:** Praise songs sound like "voice reading lyrics + faint background music," not real worship songs.

## What users are hearing today
- File size: 170-310 KB per "song" → ~1-2 minutes
- Format: TTS voice (monaural, 32kHz) reading the song's lyrics, over a 30s AI instrumental that loops
- Source: `cron-hourly.py` + `bulk-generate-praise.mjs` pipeline that was meant to mix AI music + TTS vocal, but the upload step only sent the bare vocal track to CDN

## What users want
Real worship songs. Either:
1. Public-domain hymns they recognize (Amazing Grace, Be Still My Soul, etc.)
2. Original songs that sound like they were sung by a real worship band
3. Instrumental only + lyrics on screen (sing-along)

## Root cause (full forensics)
- The `bulk-generate-praise.mjs` script generated 100 AI music + TTS vocal + ffmpeg mixes into `/workspace/.mavis-cache/heal-song-gen/song-*.mp3` 
- These 100 mixes (10-34 seconds each, 44.1kHz stereo, 128kbps) are **local only** — never uploaded to CDN
- Meanwhile, `cron-hourly.py` kept uploading the **TTS vocal-only** files as the "song" audio_url
- So users got TTS reading lyrics on every praise record

## Recommended fix (in priority order)

### PATH A — License real public-domain hymns (BEST)
**Why:** Real hymns people know. 200-400 CC0 / public-domain hymns exist. 2-4 minutes each. Real instruments, real singers.

**Sources (verified, all legal):**
- `hymnstogod.org` — CC3/CC4 licensed, instrumental + some vocal
- `timeforworship.com` — Christopher Tan MP4 hymn recordings
- `archive.org/details/publicdomainhymns_01_1110_librivox` — LibriVox vocal recordings
- `sarah-bereza.com/hymn-accompaniments` — 57 instrumental accompaniments, free for online services
- `hymnserve.com` — Free hymn accompaniments
- `publicdomainaudiobibles.com/Hymns.html` — hymns + worship songs
- `smallchurchmusic.com` — organ + piano public-domain recordings

**Effort:** 2-3 days
- Day 1: Download 50-100 best hymns from the above sources (curl / wget), tag with our schema
- Day 2: Upload to CDN, batch PB backfill of audio_url + duration_seconds
- Day 3: Verify all URLs return 200, deprecate the AI-generated vocals

**Cost:** $0 (all CC0 / public domain)

**Quality:** Real singers, real instruments, real worship songs people know. This is what the audience expects.

### PATH B — Generate with Suno v4 (REALISTIC AI MUSIC)
**Why:** If user wants "exclusive" songs and is OK with AI.
**Cost:** 112 songs × 3 credits each × $0.10 = **$33.60**
**Effort:** 2-3 days (Suno API integration + per-song prompt engineering + upload)
**Quality:** Sounds like a real worship song, but AI-generated. Some Christian users object.
**Risk:** Vocal cloning quality varies per song; some won't pass quality bar.

### PATH C — Strip vocal, ship instrumental-only with on-screen lyrics
**Why:** Fastest, cheapest, some users prefer singing themselves.
**Effort:** 2 hours
- Extend the existing 100 instrumental files (loop to 2-3 min)
- Add `lyrics` text field to PB HEAL_praise
- Update web/Flutter player to show lyrics panel below the audio
- Remove the AI vocal track entirely

**Cost:** $0

**Quality:** Acceptable. Many Christian worship apps do this.

## Recommended hybrid
**PATH A primary** — get the famous hymns up first (the 20-30 most-recognized: Amazing Grace, How Great Thou Art, Be Still My Soul, It Is Well, etc.)
**PATH C secondary** — for the rest of the 100 catalog, ship instrumental + lyrics
**PATH B future** — once we have revenue, generate 50-100 original worship songs via Suno for the "HEAL Originals" premium tier

## Execution plan (this week)
1. **Tomorrow**: Build `praise-audio-pipeline.mjs` that:
   - Downloads 50 hymns from `hymnstogod.org` (or sourced individually)
   - Tags each with title/author/year/CC license
   - Uploads to `resources.positiveness.club/heal/audio/praise/` via FTP
   - Backfills `audio_url` + `duration_seconds` on matching PB records
2. **Day 2**: Add `lyrics` field to HEAL_praise schema (or text already exists — verify)
3. **Day 2**: Build `praise-instrumental-only.mjs` for the other 62 songs (extend existing AI instrumentals, add lyrics panel UI)
4. **Day 3**: Verify all 112 praise records have either: (a) a real hymn, (b) instrumental + lyrics, OR (c) marked `is_published=false` and hidden from library
5. **Day 3**: Remove the vocal.mp3 files from CDN that we already know are bad
6. **Day 4**: Player UI update — show lyrics when present, hide old "voice reading" UI

## Code changes needed
- `web/scripts/PRAISE_DOWNLOAD.sh` — new download script
- `web/scripts/PRAISE_UPLOAD.mjs` — new upload + PB backfill
- `web/scripts/PRAISE_DEPRECATE.mjs` — mark bad records unpublished
- `web/components/praise/Player.tsx` (or wherever the player lives) — add lyrics panel
- `mobile/lib/features/praise/praise_library_page.dart` — show lyrics

## Budget
- Download + CDN: $0
- FTP upload (existing): $0
- Suno for premium originals (future): $33.60
- **This week: $0**

## Risk
- Copyright: only use CC0 / public-domain sources. List license + source URL in PB record.
- "I recognize this song" complaints: positive (people love classics)
- "Where's the contemporary praise?" complaints: addressed in PATH B (premium tier)
