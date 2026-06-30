# HEAL — Hourly Content Generator Setup (2026-06-24)

## Goal
Generate 2 new HEAL meditations every hour from 09:05 to 13:05 Asia/Shanghai.
That fires 5 times/day = **10 new meditations/day** = ~70/week.

## Status (today)
- ✅ batch-001 done: 2 meditations live in PB + audio on CDN
  - `when-the-mind-will-not-settle` (stillness, Psalm 46:10, 103s)
  - `for-the-sleepless-hour` (rest, Matthew 11:28, 124s)
- ✅ Pipeline tested end-to-end (POST → FTP → PATCH → verify)
- ✅ Cron `heal-2-content-0905-1305` registered (task `412705724989696`)
- ✅ Schedule `5 9-13 * * *` → fires at 09:05, 10:05, 11:05, 12:05, 13:05 daily

## How the cron works
Each fire:
1. Reads `pipeline/queue/state.json` → next batch number
2. Loads `data/content-batches/batch-NNN.json` (auto-generates if missing)
3. Generates audio for each meditation body via TTS (English_CaptivatingStoryteller, speed=0.9)
4. Runs `scripts/process-content-batch.mjs --batch=N` which:
   - Authenticates with PB
   - POSTs meditation to `HEAL_meditations` collection (or reuses by slug)
   - Uploads audio to `https://resources.positiveness.club/heal/audio/meditations/<slug>.mp3`
   - PATCHes PB record with `audio_url` + `duration_seconds`
5. Verifies CDN audio URL returns 200
6. Commits + pushes to HEAL repo
7. Updates state.json for next fire

## Files
- `data/content-batches/batch-001.json` — first 2 meditations (already published)
- `scripts/process-content-batch.mjs` — pipeline
- `pipeline/queue/state.json` — tracks `next_batch`
- `pipeline/queue/progress.json` — append-only run history

## Theme rotation
Themes are picked to avoid repetition: stillness, rest, courage, love, gratitude, hope, wisdom, focus, grief, calm, joy, forgiveness, let-go, grace, strength.

## Note on existing crons
There was a pre-existing HEAL cron (`heal-content-hourly`, task `412703456026880`) with a broken prompt referencing a non-existent Python script. It's still enabled. The new `heal-2-content-0905-1305` cron does the real work. If the old one misfires, it'll just fail (the script doesn't exist).