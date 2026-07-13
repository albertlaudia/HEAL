# HEAL Production Infrastructure (2026-07-13)

## Live URLs

| Domain | Stack | Status | Notes |
|---|---|---|---|
| `heal.positiveness.club` | Next.js 15 (heal-app:v6) | 200 OK | Postgres API gateway |
| `healf.positiveness.club` | Flutter web v14 | 200 OK | Auth + audio UX |
| `pocketbase.scaleupcrm.com` | PocketBase v0.39 | Healthy | Bridge / fallback |
| `resources.positiveness.club/heal/` | Backblaze B2 + CF | 200 / some 404 | Media CDN |

## v14 highlights (2026-07-13)

**Firebase Auth — first time**
- Email + password (sign in / sign up / reset)
- Google (Android / iOS / Web)
- Apple (iOS / macOS / Web only — hidden on Android)
- Routes via `/auth?returnTo=...` from Settings → "Sign in"
- On first sign-in, the local random user ID is copied to a Firestore
  `heal_users` doc as `legacyUserId` so we can stitch local-only data
  when write paths migrate off PB

**Audio UX — friendly errors**
- New `lib/services/audio_error.dart` classifies errors into 5 categories
  (no network, server, decode, session lost, unknown) and produces
  reverent first-person copy
- Errors during setSource() and async `onPlayerError` both flow through
- `_ErrorPill` shows above the mini-player with a Try Again CTA
- `_AudioErrorBanner` slides in from the bottom and auto-dismisses after 8s

## Containers

| Name | Image | Network | Port | Notes |
|---|---|---|---|---|
| `heal-app-apsqyt` | `heal-app:v6` | `dokploy-network` | 3000 | Next.js API |
| `heal-pg` | `postgres:16-alpine` | `dokploy-bridge` + `dokploy-network` | 5432 | 940 records |
| `heal-flutter-web` | `heal-flutter-web:v14` | `dokploy-network` | 80 | Web build |

## Traefik routing + auto-IP-watch

The Flutter web and Next.js services run on the Docker overlay network,
which assigns rotating IPs. Two cron-driven watch scripts keep the
Traefik dynamic configs in sync:

- `/usr/local/bin/flutter-traefik-watch.sh` (every 5 min)
  - Detects heal-flutter-web IP change
  - Template: `/etc/dokploy/traefik/dynamic/heal-flutter-web.yml.tmpl`
  - Service port: 80

- `/usr/local/bin/heal-app-traefik-watch.sh` (every 5 min)
  - Detects heal-app IP change
  - Template: `/etc/dokploy/traefik/dynamic/heal-app-apsqyt.yml.tmpl`
  - Service port: 3000

## Re-deploy flow

```bash
# Flutter web
cd /etc/dokploy/applications/app-calculate-digital-bandwidth-h95pb2/code
git pull --rebase origin main
docker build \
  --build-arg FIREBASE_API_KEY=... \
  --build-arg FIREBASE_PROJECT_ID=heal-prd \
  --build-arg FIREBASE_APP_ID=... \
  --build-arg FIREBASE_MESSAGING_SENDER_ID=355529098583 \
  -t heal-flutter-web:v15 -f mobile/web.Dockerfile mobile
docker service update --image heal-flutter-web:v15 --force heal-flutter-web
# Watch script will pick up new IP within 5 min (or run it manually)

# Next.js
cd /etc/dokploy/applications/app-calculate-digital-bandwidth-h95pb2/code
git pull --rebase origin main
docker build -t heal-app:v7 -f web/Dockerfile web
docker service update --image heal-app:v7 --force heal-app-apsqyt
```

## API Routes (Postgres-backed)

- `GET /api/health` — `{ status, postgres: { ok, latencyMs } }`
- `GET /api/heal/{meditations,praise,prayers,scriptures,quotes,breathwork,essays,bible-readings,world,pages}` — list with `?limit=&offset=&q=&filter=value`
- `GET /api/heal/{collection}/{id}` — single record (TODO)

## What's NOT on the new API yet

- Write paths (bible_progress, sticker unlocks) — still on PB, gated on Firebase auth
- Mobile app — `api_repositories.dart` exists but not yet active
- Auth — Firebase init + auth UI shipped in v14, needs production verification
