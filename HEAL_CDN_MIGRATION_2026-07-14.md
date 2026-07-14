# HEAL CDN Migration — 2026-07-14

## Problem
HEAL mobile app audio playback failing with `AudioService.play error: TimeoutException` and `MEDIA_ERROR_UNKNOWN`.

Root cause: `https://resources.positiveness.club/heal/audio/...` URLs return 404 from Cloudflare edge. Cloudflare was caching 404s after the SmarterASP origin went down. The actual MP3 files were still on the FTP server at `win8108.site4now.net:/heal/audio/...` but unreachable over HTTP.

## Solution
Migrated all HEAL media (audio + illustrations) from SmarterASP FTP to Backblaze B2 public bucket (`GOPResources`), updated PB records, and updated HEAL mobile code to default to the new CDN.

## What was done

### 1. Immediate fix for the specific failing file
- `orig-v2-my-jesus-i-love-thee.mp3` (1.96MB) downloaded from FTP
- Uploaded to B2 at `heal/audio/praise/orig-v2-my-jesus-i-love-thee.mp3`
- PB record `HEAL_praise/rcf5tnkc00mphxd` updated
- Verified: `curl -I https://f004.backblazeb2.com/file/GOPResources/heal/audio/praise/orig-v2-my-jesus-i-love-thee.mp3` → 200

### 2. Code changes (committed b27f21b)
- `mobile/lib/core/env.dart` — default `CDN_URL` changed to B2
- `mobile/lib/data/pb_models.dart` — all 7 fallback URLs changed to B2
- `mobile/lib/features/sleep/ambient_sounds_page.dart` — 6 ambient URLs changed to B2

### 3. Comprehensive migration script
- `scripts/migrate-cdn.py` — handles all HEAL_* collections
- Tries URL-as-is, then variants: `sing-{slug}`, `orig-{slug}`, `orig-v2-{slug}`, `audio-{slug}`, `illustration-{slug}`, `praise-{slug}`, `meditation-{slug}`, `prayer-{slug}`, etc.
- For files with no match, clears the URL in PB
- Re-runnable (skips records already on B2)

### 4. Background migrations running
- HEAL_praise audio: **DONE** — 102/102 on B2, 0 on broken CDN, 22 empty (cleared), 0 failed
- HEAL_praise illustrations: 14/112 in progress (img3 script)
- HEAL_meditations audio: **DONE** — 42/42 on B2, 0 on broken CDN, 229 empty (cleared), 0 failed
- HEAL_meditations illustrations: 106/255 in progress (img1 script)
- HEAL_prayers illustrations: 0/66 queued (img3 script)
- HEAL_essays illustrations: 0/3 queued (img3 script)

## FTP filename patterns discovered

| Collection | URL pattern (PB) | FTP filename pattern | Notes |
|---|---|---|---|
| HEAL_praise audio | `sing-{slug}.mp3` | `orig-{slug}.mp3` | PB has wrong URL pattern, use `orig-` variant |
| HEAL_meditations audio | `audio-{slug}.mp3` | `audio-{slug}.mp3` | Match |
| HEAL_praise illustrations | `{slug}.jpg` (sometimes) | `praise-{slug}.png` | Use `praise-` prefix |
| HEAL_meditations illustrations | `illustration-{slug}.png` | `illustration-{slug}.png` | Match |
| HEAL_prayers illustrations | `{slug}.jpg` | `illustration-{slug}.png` | Use `illustration-` prefix |
| HEAL_essays illustrations | `{slug}.jpg` | `essay-{slug}.png` or similar | TBD |

## Manual mapping (no FTP file exists)

For these praise audio files, no good FTP file matches the PB slug. URL was cleared:

- `come-thou-fount-of-every-blessing`
- `what-a-friend-we-have-in-jesus`
- `rock-of-ages`
- `behold-the-lamb-of-god`
- `come-ye-thankful-people-come`
- `in-the-sweet-by-and-by`
- `silent-night`
- `the-old-rugged-cross`
- `this-is-my-fathers-world`
- `twas-grace-that-taught-my-heart-to-fear`
- `wonderful-words-of-life`
- `yield-not-to-temptation`
- `pass-me-not-o-gentle-savior`

For these, used closest variant:

- `it-is-well-with-my-soul-abridged` → `orig-it-is-well-with-my-soul-full.mp3`
- `amazing-grace-common-meter` → `orig-amazing-grace-full.mp3`
- `joy-to-the-world-edmonds` → `orig-v2-joy-to-the-world.mp3`

## URLs

| Old (broken) | New (working) |
|---|---|
| `https://resources.positiveness.club/heal/audio/{...}.mp3` | `https://f004.backblazeb2.com/file/GOPResources/heal/audio/{...}.mp3` |
| `https://resources.positiveness.club/heal/images/{...}.png` | `https://f004.backblazeb2.com/file/GOPResources/heal/images/{...}.png` |
| `https://resources.positiveness.club/heal/sounds/{...}.mp3` | `https://f004.backblazeb2.com/file/GOPResources/heal/sounds/{...}.mp3` |

## What's still broken (separate issue)

The user's flutter logs also show an `AudioErrorListener` Overlay error:
```
The context from which that widget was searching for an overlay was:
  AudioErrorListener
  package:heal/design/audio_error_banner.dart:55:27
```

This is a widget tree issue in `design/audio_error_banner.dart` — `Overlay.of(context)` is being called from a context that doesn't have an Overlay ancestor. The file is in a flutter package called `heal` (not the HEAL app itself). The fix would need to be made on the user's local checkout since the file is not in this repo.

**Workaround**: the `AudioErrorListener` should be placed BELOW the `MaterialApp` in the widget tree, not above it. Or use `Overlay.of(rootNavigatorKey.currentContext!)` if accessing from outside the MaterialApp.
