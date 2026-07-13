# HEAL Production Infrastructure

## Live URLs (2026-07-13)

| Domain | Stack | Status | Notes |
|---|---|---|---|
| `heal.positiveness.club` | Next.js 15 (heal-app:v6) | 200 OK | Postgres API gateway |
| `healf.positiveness.club` | Flutter web v13 | 200 OK | Mobile UI |
| `pocketbase.scaleupcrm.com` | PocketBase v0.39 | Healthy | Bridge / fallback |
| `resources.positiveness.club/heal/` | Backblaze B2 + CF | 200 / some 404 | Media CDN |

## Containers

| Name | Image | Network | IP | Notes |
|---|---|---|---|---|
| `heal-app-apsqyt` | `heal-app:v6` | `dokploy-network` | rotates per redeploy | Next.js API |
| `heal-pg` | `postgres:16-alpine` | `dokploy-bridge` + `dokploy-network` | 172.20.0.45 | 940 records |
| `heal-flutter-web` | `heal-flutter-web:v13` | `dokploy-network` | rotates | Web build |

## Postgres (`heal-pg`)

Credentials in env, not repo. Schema: `docs/POSTGRES_SCHEMA.sql`. Migration:
```bash
node scripts/export-pb-to-postgres.js
```
(Idempotent — TRUNCATE+INSERT. Safe to re-run.)

## API Routes (Postgres-backed)

- `GET /api/health` — `{ status, postgres: { ok, latencyMs } }`
- `GET /api/heal/{meditations,praise,prayers,scriptures,quotes,breathwork,essays,bible-readings,world,pages}` — list with `?limit=&offset=&q=&filter=value`
- `GET /api/heal/{collection}/{id}` — single record (TODO)

## Traefik Routing

Config: `/etc/dokploy/traefik/dynamic/heal-app-apsqyt.yml`
Template: `deploy/heal-app-apsqyt.yml.tmpl` (`__IP__` placeholder)
Auto-sync: `/usr/local/bin/heal-app-traefik-watch.sh` (every 5 min via cron)

When the heal-app container redeploys and its IP changes, the watch script
detects the mismatch, rewrites the config from the template, and SIGHUPs Traefik.

## Re-deploy flow

```bash
# 1. Push code
git push origin main

# 2. On server, rebuild
cd /etc/dokploy/applications/app-calculate-digital-bandwidth-h95pb2/code
git pull --rebase origin main
docker build -t heal-app:v7 -f web/Dockerfile web

# 3. Update service
docker service update --image heal-app:v7 --force heal-app-apsqyt

# 4. Watch script will pick up new IP automatically
```

## What's NOT on the new API yet

- Write paths (bible_progress, sticker unlocks) — still on PB
- Mobile app — `api_repositories.dart` exists but not yet active
- Auth — Firebase init TODO
