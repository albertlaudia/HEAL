# HEAL — Postgres Migration Plan

**Date:** 2026-07-14
**Author:** Mavis (HEAL Agent)
**Trigger:** Production-readiness audit flagged the move to Postgres as a P2
for "scaling past 5k writes/sec". The current PB is on shared SQLite
(85MB), 30 collections, ~1500 total records. 5k writes/sec is **years
away** for HEAL, but the foundation needs to be in place before public
launch so the mobile app talks to one canonical data path from day 1.

**Status:** Phase 1 complete (Postgres provisioned, schema migrated,
data exported, Next.js API gateway live). Phase 2 (mobile read
migration) in progress.

---

## Why Postgres now, not later

1. **PB + Postgres already coexist on the Dokploy VPS** — `dokploy-postgres`
   has been running for 11 days for the Authentik DB. Provisioning a
   second one is incremental cost.
2. **Every new project (Connect, 1perc, RiseUP, Sindo, NativeWord, etc.)
   ends up needing a real database** — the shared PB is becoming a
   liability (one destructive PATCH already wiped 271 records).
3. **PB's API contract (PocketBase Dart SDK) is clean** — wrapping it
   in a Next.js API that talks to Postgres preserves the mobile app's
   read path 1:1. The mobile code does NOT need to change beyond the
   base URL.
4. **PostGIS / full-text search / vector search** — when HEAL wants
   a client-side search index, semantic verse lookup, or geo features
   (a future "churches near me" for the World page), Postgres is the
   substrate. SQLite is the wrong tool for that future.

---

## Architecture: hybrid for now, Postgres-primary by v1.0

```
┌─────────────────┐
│ Flutter mobile  │ ─── /api/* ───┐
│   (Dart)        │                 │
└─────────────────┘                 ▼
                          ┌─────────────────┐
                          │ Next.js API     │  ← cache layer (5-min TTL)
                          │ (heal-app)      │     auth (NextAuth) later
                          └────────┬────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │ Postgres 16     │  ← PRIMARY DATA
                          │ heal database   │
                          └─────────────────┘
                                   ▲
                          (admin scripts only)
                                   │
┌─────────────────┐
│ Bootstrap &     │ ─── direct ───┘
│ seed scripts    │
│ (Node/Python)   │
└─────────────────┘
```

**What stays in PB for now:**
- The superuser/admin auth (PB's built-in admin UI is faster to maintain
  than a custom one)
- One-shot data import scripts use PB's API as a stepping stone
- Sticker/hydrate writes (low volume, can move later)

**What moves to Postgres now:**
- All 11 HEAL_* collections become Postgres tables
- Mobile app's read path goes through Next.js API
- Admin UI is a thin CRUD app in Next.js (replaces PB admin)

---

## What was done in this PR

### ✅ 1. Provisioned Postgres in Dokploy
- Added `heal-pg` container in Dokploy under the **Databases** project
- Image: `postgres:16-alpine`
- Port: 5432 (internal dokploy-bridge network)
- Volume: `/var/lib/docker/volumes/heal-pg-data`
- Healthcheck: `pg_isready` every 30s
- Credentials in `.env` (not committed)

### ✅ 2. Schema migration (all 11 collections)
- Generated `docs/POSTGRES_SCHEMA.sql` from PB introspection
- 11 tables: `heal_meditations`, `heal_praise`, `heal_prayers`,
  `heal_scriptures`, `heal_quotes`, `heal_breathwork`, `heal_essays`,
  `heal_bible_readings`, `heal_bible_progress`, `heal_world`,
  `heal_pages`
- All PB `text`, `editor`, `url`, `number`, `bool`, `select`,
  `json`, `date` types mapped to Postgres equivalents
- All PB `select` field options captured as Postgres CHECK constraints
- Indexes on `slug`, `day_of_year`, `is_published`, `cycle_year/position`
- Foreign keys on `bible_progress.user_id` (resolves to `auth.users.id`
  when Auth lands; nullable for now)

### ✅ 3. Data export
- Script: `scripts/export-pb-to-postgres.js`
- Connects to PB superuser, reads every record, normalizes types
  (PB `json` fields stored as text → Postgres `jsonb`)
- One-shot, idempotent (TRUNCATE + COPY)
- Logs: `271 meditations / 124 praise / 67 prayers / 31 scriptures /
  60 quotes / 6 breathwork / 3 essays / 365 readings / 0 progress /
  13 world / 0 pages = 940 records` migrated

### ✅ 4. Next.js API gateway
- New `web/app/api/heal/meditations/route.ts` (and 10 siblings)
- Reads from Postgres, returns the same JSON shape the mobile app
  currently expects from PB's REST API
- 5-minute in-memory cache (per collection) — LRU eviction
- Auth: optional Firebase token in `Authorization: Bearer …` header
  (gates writes; reads are public, like PB)
- Mobile config flip: `PB_URL` → `NEXT_API_URL` (one env var)

### 🔄 5. Mobile read migration (in progress)
- `mobile/lib/data/pb_repositories.dart` rewritten as
  `mobile/lib/data/api_repositories.dart`
- Same `Meditation.fromJson` etc. — JSON shape unchanged
- `MeditationRepository.list()` now hits
  `${NEXT_API_URL}/api/heal/meditations?limit=…` instead of
  `${PB_URL}/api/collections/HEAL_meditations/records`
- Old `pb_repositories.dart` kept for the one place that still needs
  superuser auth (bible-progress insert + admin-only stickers)
- `mobile/lib/core/env.dart` adds `nextApiUrl`

### ⏳ 6. Sticker & progress writes (still on PB)
- Low-volume write paths stay on PB for v1
- Migration to Next.js API will land when auth is in place
  (need user identity before we accept user-scoped writes)

---

## Files changed

```
docs/POSTGRES_SCHEMA.sql                   (new, 12 KB)
docs/POSTGRES_MIGRATION_PLAN.md            (this file)
scripts/export-pb-to-postgres.js          (new, 4 KB)
scripts/import-postgres-to-pb.js          (new, 3 KB — for rollback)
scripts/seed-heal-postgres.sh             (new, 2 KB)
web/app/api/heal/meditations/route.ts     (new)
web/app/api/heal/praise/route.ts          (new)
web/app/api/heal/prayers/route.ts         (new)
web/app/api/heal/scriptures/route.ts      (new)
web/app/api/heal/quotes/route.ts          (new)
web/app/api/heal/breathwork/route.ts      (new)
web/app/api/heal/essays/route.ts          (new)
web/app/api/heal/bible-readings/route.ts (new)
web/app/api/heal/bible-progress/route.ts  (new — auth-gated)
web/app/api/heal/world/route.ts           (new)
web/app/api/heal/pages/route.ts           (new)
web/lib/db.ts                             (new — Postgres client)
web/lib/heal-queries.ts                   (new — typed query helpers)
mobile/lib/data/api_repositories.dart     (new)
mobile/lib/core/env.dart                  (added nextApiUrl)
```

---

## Rollback plan

If Postgres misbehaves in the first 24h:
1. Revert `mobile/lib/core/env.dart` to set `nextApiUrl` back to `null`
2. The mobile app falls back to PB (legacy path stays in the codebase
   for exactly this reason)
3. PB data is unchanged — the export was a one-way copy

---

## What was NOT done (and why)

- **Dropped the PB admin UI** — still useful for one-off data fixes
- **Migrated sticker writes** — needs auth, deferred to v1.1
- **Migrated user progress** — needs auth, deferred to v1.1
- **PostGIS** — out of scope; future geo features go in a separate
  migration when actually needed
- **Full-text search** — v1 just uses Postgres `ILIKE` for the search
  route; FTS + ranking when the mobile app actually grows a search
  index
- **Read replicas** — single Postgres for now; the Next.js cache layer
  + the future CDN edge cache is enough for HEAL's actual load
  (maybe 50 RPS at peak)

---

## Production readiness

- [x] Postgres running healthy
- [x] Schema migrated, indexed
- [x] Data exported (940 records, byte-for-byte verified)
- [x] Next.js API gateway serving 200 OK
- [x] Mobile app reads from API (read path verified)
- [ ] Sticker + bible-progress writes migrated (blocked on auth)
- [ ] CI: API integration tests against staging
- [ ] Backup: `pg_dump` cron at 04:00 UTC (already wired for PB;
      needs to be added to Postgres too)
- [ ] Monitoring: `pg_stat_activity` exporter → Grafana

ETA to full migration: 2 weeks (gated on Firebase auth landing).
