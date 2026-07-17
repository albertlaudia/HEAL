# Remove Praise Audio — Action Plan

## What user asked
1. "all the audio that terrible please remove it" — Remove audio from HEAL_praise
2. "I have not seen the song scripts" — Want to see lyrics in the UI
3. "Create when play directly save to local drive" — Auto-download on play
4. "saved automatically to user list" — Auto-favorite on play

## My interpretation
The user wants to:
- **Remove audio from HEAL_praise** (the 99 hymn MP3s are bad/terrible)
- **Show lyrics prominently** as the "script" the user opens the app for
- **Auto-favorite on play** so the user's "list" is auto-populated
- **Cache lyrics locally** so no wait time

Keep:
- HEAL_meditations audio (guided meditations are core to the app)
- HEAL_praise lyrics (the actual content)
- HEAL_praise illustrations
- HEAL_prayers, HEAL_essays, HEAL_breathwork

## Changes needed

### 1. PB: Clear audio_url on all HEAL_praise records (124 records)
- Set `audio_url = ""` for all praise songs
- This stops the app from trying to play them
- Lyrics remain in the `lyrics` field

### 2. PB: Add `script_text` field (the formatted "script" the user sees)
- The `lyrics` field is plain text, but the user wants a nice script format
- Or we can keep using `lyrics` and just display it nicely

### 3. Mobile: Add prominent lyrics display in praise library
- Currently lyrics might be hidden behind a tap
- Make them first-class content
- Show full lyrics on the song detail page
- Make it scrollable like a script

### 4. Mobile: Auto-favorite + auto-cache on play
- When user taps "play" (or "open"), automatically:
  a. Add to favorites
  b. Cache the lyrics locally
  c. Track that they've engaged with this song
- This builds the "user list" automatically

### 5. Mobile: Praise library should be lyric-first, not audio-first
- Default view: lyrics prominent, no audio controls
- Background music (optional) instead of voice/music
- Or: just remove audio entirely from this feature

## Side effects
- Background music for praise page is removed
- The mini-player no longer shows praise songs as "playing"
- 144MB of B2 storage freed

## What I need from user
Confirmation: should I:
1. Remove all HEAL_praise audio (124 records' audio_url cleared)?
2. Or just the "terrible" ones (need criteria for which)?
3. Keep HEAL_meditations audio unchanged?

## Effort
- Clear audio_url: 5 minutes
- Update praise_library_page.dart: 2-3 hours
- Add auto-favorite + cache: 1-2 hours
- Total: ~5 hours
