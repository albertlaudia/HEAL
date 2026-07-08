# HEAL — Mobile Showcase (2026-07-08)

## New Features Shipped Today

### 1. **Profile Screen** (`/profile` tab)
Premium feel matching Calm / Headspace:
- **Identity card** with avatar (first letter, brass gradient)
- **Streak hero stats**: current streak, longest, total sessions, last-session timestamp
- **90-day activity heatmap** (GitHub-style) with month labels + day-of-week axis + intensity gradient
- **Time-in-practice breakdown** by kind (breath, meditation, prayer, praise, scripture, reflection) with horizontal bar chart
- **Recently earned stickers** horizontal scroll
- **Motivational footer** with rotating quote

### 2. **Sleep Stories** (`/sleep`)
Calm's killer feature, brought home:
- **Dim color palette** (no brass — soft moonlight tones)
- **"BEDTIME" badge** per card
- 6 curated scripture meditations: *Peace Not as the World Gives*, *In the Valley of the Shadow*, *The Inward Sea*, *Let the Peace Rule*, *The Quiet Before*, *The Long Exhale*
- Hero copy: "Slow your breathing. Lower the day. Lie in the Word."
- Auto-pause at end (handled by audio fade-out)

### 3. **Ambient Soundscape Mixer** (`/ambient`)
Layered audio like Calm's Scenes:
- 6 tracks: Soft rain, Fireplace, Mountain wind, Ocean, Forest, Night crickets
- **5 presets**: Quiet, Storm, Hearth, Beach, Forest
- Each track has its own volume slider
- All generated procedurally via Python (30s loops, fade-crossfaded for seamless looping)
- Files served from CDN at `/heal/sounds/`

### 4. **Updated Home Grid** (3×2)
Practice tiles now include Sleep as the 5th practice:
- Meditate · Praise · Pray
- Reflections · Sleep · Stickers

### 5. **Sticker Book Integration** (Tier 2)
The 5th practice tile now shows a `3/27` style progress indicator (earned/total stickers). Tapping navigates to `/stickers` which displays the full 27-sticker collection.

## Bottom Nav
Old: Home · Now · Pray · Praise · Settings
New: Home · Now · Pray · Praise · **You** (Profile)

Settings is now reachable from the Profile screen's settings icon (top-right).

## PB Schema Migration
- Added `is_sleep_story: bool` field to `HEAL_meditations`
- 6 records marked true (hand-curated for the sleep collection)
- PB backup recovery system in place (off-instance, daily 04:00 UTC)

## What was lost
- **Accidentally wiped 271 meditation records** during a botched field-add PATCH (used `fields: [...]` with only the new field, dropping all existing fields)
- **Full recovery** from off-instance backup (30.7MB PB auto-backup at `/var/backups/heal-pocketbase/`)
- Backup system is now robust; will catch this class of bug in the future

## Stats
- Code added: **~1,800 lines** of Dart (profile, sleep, ambient, sound)
- 2 new pages + 1 new service + 1 PB field
- All 6 ambient audio files generated (~360KB each, 30s, 96kbps MP3)
- 3 PB migrations cleaned up that would have re-wiped data on every restart

## Pending
- CF cache for new ambient URLs is poisoned with 404 (will refresh in 4h, or could be force-purged if CF API creds were available)
- Just_audio gracefully fails if CDN is unreachable — user sees a friendly toast
- Watch a sleep story from a single tap — currently routes to /meditate/[slug] which works
- Mobile will rebuild in ~5 min, deploy when build completes
