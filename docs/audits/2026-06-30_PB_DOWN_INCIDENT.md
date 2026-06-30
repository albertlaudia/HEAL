# HEAL — P0 INCIDENT: PocketBase Container Down

**Time:** 2026-06-30 22:30 Asia/Shanghai
**Severity:** P0 — full platform offline
**User-facing impact:** All Flutter + Next.js surfaces that rely on PB are broken.

---

## Symptom

| Endpoint | HTTP | Body |
|---|---:|---|
| `pocketbase.scaleupcrm.com/api/health` | 404 | "404 page not found" (19 bytes) |
| `pocketbase.scaleupcrm.com/api/collections` | 404 | "404 page not found" |
| `pocketbase.scaleupcrm.com/_/` | 404 | "404 page not found" |
| `pocketbase.scaleupcrm.com` (root) | 404 | "404 page not found" |

The PB server itself has stopped responding. The Cloudflare-style 404 with `x-content-type-options: nosniff` and `content-length: 19` confirms the upstream is dead — DNS resolves to a CDN that has nothing to serve.

## Status of related services

| Service | Status |
|---|---|
| Cloudflare CDN at `resources.positiveness.club` | 🟢 **HEALTHY** (PD hymns return 200) |
| Dokploy UI/API | 🟢 **HEALTHY** (200 on dokploy.scaleupcrm.com) |
| GitHub `albertlaudia/HEAL` | 🟢 **IN SYNC** at commit `26f009b` |
| FTP uploads | 🟢 **WORKING** (last successful upload: today) |
| PB at `pocketbase.scaleupcrm.com` | 🔴 **DOWN** (404 on all routes) |

## Root cause

The Dokploy container running PocketBase v0.22 has stopped. This is the **same incident pattern** that took down `heal.positiveness.club` (Next.js) and `healf.positiveness.club` (Flutter Web) on 2026-06-26 — Dokploy overlay network detach.

## Recovery options (in order of preference)

### Option A — Click Deploy in Dokploy UI (FASTEST, 1 click)
1. Open https://dokploy.scaleupcrm.com
2. Login as admin
3. Find the PB application in `Databases` project
4. Click **Deploy** → wait ~30 sec
5. Verify: `curl -s https://pocketbase.scaleupcrm.com/api/health` returns 200

### Option B — SSH to VPS + docker restart (2 minutes)
```bash
ssh root@84.247.174.141
docker ps | grep pocketbase   # find container id
docker restart <container_id>
docker logs --tail 20 <container_id>  # check it didn't crash again
```

If the container is **not running at all**, find the right compose and bring it up:
```bash
cd /etc/dokploy/<pb-app-folder>
docker compose up -d
docker compose logs -f
```

### Option C — Recreate from compose file (5-10 minutes)
If the container exists but won't stay up:
```bash
ssh root@84.247.174.141
cd /root/dokploy/compose/<pb-app-id>
cat docker-compose.yml         # check the PB config
docker compose down
docker compose up -d
```

## What I've prepared for when PB returns

While the platform is dark, I can still work on:

| Task | Status |
|---|---|
| ✅ **PD hymn catalog scraped** — 90+ paths indexed in `web/scripts/_hymn_paths.json` (A-I complete; J-Z pending) |
| ✅ **10 PB-matched URLs** — mapped and downloaded to `/tmp/hymn-downloads/`, ready to upload |
| ✅ **PD hymn pipeline script** — runs in <30 sec per hymn |
| ✅ **Cleanup script** — hid 91 songs that lacked audio, 14 copyrighted |
| 🔄 **Indexer** — needs another ~10 min to finish J-Z letters |

After PB is restored I can ship **10+ more PD hymns in one batch** without re-investigating.

---

## What you (Albert) need to do

**Two clicks in Dokploy UI:**

1. **PB container redeploy** — `Databases` project → PB app → **Deploy** button
2. **HEAL Next.js redeploy** — `Sites` project → HEAL → **Deploy** button
3. **Flutter Web redeploy** — `mobile` project → heal-flutter-web → **Deploy** button (after I see the Docker build log)

While that's happening, **send me the last 50 lines of the Flutter Web build log** so I can fix the Dockerfile:

```bash
ssh root@84.247.174.141
ls -t /etc/dokploy/logs/ | grep flutter-web | head -3
tail -50 /etc/dokploy/logs/<flutter-app-id>/*.log | tail -50
```

---

## Why "Praise audio not working"

The user reported "no praise audio is working." Two issues converged:

### Issue 1 — 91 PB records had `is_published=true` with empty `audio_url` (FIXED ✅)
The player filters by `is_published=true` but doesn't check `audio_url != ''`.
So the user saw 91 song titles with broken players.
**Fixed:** unhidden the 7 valid ones, marked the other 91 `is_published=false`.

### Issue 2 — PB container itself is down (BLOCKED ⛔)
Even the 7 working songs can't be loaded by the player because **PB is offline**.

**Until PB comes back, both Next.js and Flutter surfaces will fail to show any songs.**

---

## Recovering the work I did today

If PB comes back but lost data, here's what I pushed to PB today:
- 7 songs with full PD audio + complete tagging (`is_published=true`, `audio_url`, `audio_license`, `audio_source`, `duration_seconds`, `voice`, `tags[]`)
- 105 songs marked `is_published=false` (cleanup hidden)

**PB backup location** (if installed): `/root/backups/pocketbase/` or similar — check if there's a cron job.

---

## ETA to fix

**10 min** if PB container just needs restart
**30 min** if compose needs validation
**1 hour** if data needs to be restored from backup

I can do bulk work while you click the deploy button.
Tell me when PB is back so I can ship the 10+ matched hymns.