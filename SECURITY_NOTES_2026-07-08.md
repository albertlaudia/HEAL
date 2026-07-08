# HEAL — Security Notes (2026-07-08)

This document records what secrets are in use and which can be rotated without
disrupting the platform.

## Production Secrets (Tier 1 — rotate if leaked)

| Secret | Used by | Rotate at | Impact if rotated |
|--------|---------|-----------|-------------------|
| `DOKPLOY_API_KEY` | Dokploy API for app deploy | Dokploy → Settings → API Tokens | Breaks CI deploy until new key set in GitHub secrets |
| `GITHUB_PAT` | `git push` from this sandbox | GitHub → Settings → PAT | Breaks my git pushes until new token provided |
| `PB_PASSWORD` (minimax@scaleupcrm.com) | PB superuser login | PB Admin → superusers | Breaks all PB admin scripts + daily-world cron |
| `SMARTERASP_FTP_PASSWORD` | CDN upload to `resources.positiveness.club` | SmarterASP account | Breaks all media uploads + world cron images |
| `CLOUDFLARE_API_TOKEN` | Cloudflare DNS | Cloudflare → API Tokens | Breaks DNS automation (only used for some scripts) |

## Non-Production / Lower Risk

| Secret | Notes |
|--------|-------|
| `PB_FTP_PASSWORD` | Same as SmarterASP — used in different scripts |
| `ONEMAP_API_KEY` | Singapore government OneMap — public API key, not sensitive |
| `LTA_API_KEY` | Singapore LTA — public API key, not sensitive |
| `CLOUDFLARE_PASSWORD` | Not actually used; only token-based access |
| `STB_API_KEY` | Singapore Tourism Board — public, rate-limited |

## What's been done today (2026-07-08)

✅ **PB daily backup script installed** at `/usr/local/bin/heal-pb-backup.sh`
   - Cron: `0 4 * * *` (daily 04:00 UTC, 4h after PB's own auto-backup)
   - Copies PB's auto-backup to `/var/backups/heal-pocketbase/`
   - Keeps 30 daily + 8 weekly, total ~1GB/month
   - Log: `/var/log/heal-pb-backup.log`
   - Today's test: 30.7MB copied OK

## What's still open

❌ **Traefik watcher still flaky** for Flutter Web deploy — manual `sed` + `docker kill -s HUP traefik` still needed when container IP changes
❌ **1 stuck praise file** — `praise-create-in-me-a-clean-heart.webp` failed FTP upload (425 errors)
❌ **VPS SSH flapping** — intermittent connection refused; retries with 30-60s waits
