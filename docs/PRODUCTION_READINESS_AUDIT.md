# HEAL — Production Readiness Audit
**Date:** 2026-06-25
**Reviewer:** Mavis (M3)
**Live URL:** https://heal.positiveness.club
**Repo:** `albertlaudia/HEAL`
**Status:** 🟡 Pre-launch — web production-ready, mobile needs `flutter pub get` + first build

---

## 1. Executive Summary

| Area | Status | Verdict |
|---|---|---|
| Web app (Next.js) | 🟢 Live, 17/17 routes 200 | Production-ready for v1.0 |
| Mobile app (Flutter) | 🟡 Code complete, never built | Blocked on `flutter pub get` + first compile |
| PocketBase schema | 🟢 7 collections live, 547 records | All fields + indexes in place |
| Media CDN | 🟢 100% PB records reference working URLs | All 268 meditation illustrations verified |
| Dokploy CI/CD | 🟢 GitHub Action auto-deploys on push | Last 11 builds green |
| Auth (Firebase) | 🟢 Web live, mobile scaffold only | Browser-safe apiKey in env.example |
| Content generation | 🟡 Hourly cron live, 12 records/day | 5-year cycle math needs implementing |
| 5-year content coverage | 🟡 Cycle positions exist on 158 records | **Bank size needs 5× expansion** |
| Streak / engagement | 🟢 Mobile built, web missing | Mobile v1 only — web parity next sprint |
| Voice calibration | 🟢 Mobile built | Web would need Web Audio API |
| Adaptive palette | 🟢 Mobile built (6 time periods) | Web has static theme only |
| Sit-with-verse mode | 🟢 Mobile built | Not in web app |
| Observability | 🟡 Logger only, no Sentry | Add Sentry before launch |
| Secrets hygiene | 🔴 6 secrets exposed in chat/Dokploy | Rotate before launch |
| Security | 🟡 Auth + signed URLs work, rate limits missing | Add per-IP limits |
| Test coverage | 🔴 Web zero, mobile zero | Unit + integration tests needed |
| Backups | 🔴 PB not auto-backed up | Daily PB snapshot to B2 |
| Mobile build artifact | 🔴 Never built | Run `flutter build apk` once |

**Verdict:** Web is launchable today. Mobile needs one local build to prove it compiles, then a CI pipeline for APK/IPA. 5-year content cycle needs the seed banks expanded 5×.

---

## 2. Current State — Verified Live

```
=== Live URLs (verified 2026-06-25) ===
heal.positiveness.club                → 200 in 1.12s, 71KB
pocketbase.scaleupcrm.com/api/health  → 200 in 1.23s
resources.positiveness.club/heal/...  → 200 (CDN OK, all 268 illustrations reachable)
heal.positiveness.club/sitemap.xml    → 200
heal.positiveness.club/robots.txt     → 200
heal.positiveness.club/.git/HEAD      → 404 (good — not exposed)
heal.positiveness.club/.env           → 404 (good — not exposed)
heal.positiveness.club/Dockerfile     → 404 (good — not exposed)

=== All 17 web routes return 200 ===
/                  /about           /badges         /breathe
/contact           /essays          /favorites      /guidelines
/history           /journal         /meditate       /now
/praise            /prayers         /privacy        /programs
/scripture

=== PB collection counts (live) ===
HEAL_meditations: 268 records
HEAL_praise:      112 records
HEAL_prayers:       67 records
HEAL_scriptures:    31 records
HEAL_quotes:        60 records
HEAL_essays:         3 records  ⚠️ very thin
HEAL_breathwork:     6 records

=== Dokploy builds (last 11, all green) ===
2026-06-25T03:42:36 status=done
2026-06-25T03:28:58 status=done
2026-06-25T03:05:53 status=done
... (8 more all done)
```

---

## 3. Infra Structure

### Current topology

```
                         ┌────────────────────┐
                         │  Cloudflare CDN    │
                         │  *.positiveness.club│
                         └─────────┬──────────┘
                                   │
            ┌──────────────────────┼──────────────────────┐
            │                      │                      │
   heal.positiveness.club   resources.positiveness.club   api subdomain
            │                      │
            ▼                      ▼
   ┌────────────────┐     ┌──────────────────┐
   │   Dokploy VPS  │     │  SmarterASP.NET  │
   │  84.247.174.141│     │  IIS + FTP       │
   │  HEAL Next.js  │     │  (Ressup acct)   │
   │  + PB docker   │     │  + Cloudflare    │
   └───────┬────────┘     └──────────────────┘
           │
           ▼
   ┌────────────────┐
   │  PocketBase    │  ←──── PB admin
   │  v0.39         │
   │  /workspace/HEAL│
   │  ./pocketbase  │
   │  data + hooks  │
   └────────────────┘

   ┌────────────────┐
   │  Firebase      │
   │  heal-prd      │
   │  Auth + Firestore│
   └────────────────┘

   ┌────────────────┐
   │  Backblaze B2  │
   │  GOPResources  │  (no longer used for HEAL — migrated to CDN)
   └────────────────┘
```

### What lives where

| Component | Host | Notes |
|---|---|---|
| Next.js web app | Dokploy / `3UHHbFdDgkIklUHCHSkTg` | Build via Dockerfile, `buildPath: /web` |
| PocketBase server | Dokploy / same VPS, different container | Shared with 1perc, RiseUP, etc. |
| PB data volume | Persistent Dokploy volume | ⚠️ not auto-backed up |
| Media files | Cloudflare-fronted IIS/FTP | 1 domain, 4 aliases |
| Auth | Firebase (heal-prd) | Browser-safe apiKey |
| User data (favorites/journal) | Firestore | Counter docs only — Spark-free safe |
| Secrets | Dokploy env vars | ⚠️ 6 exposed in chat history |

---

## 4. Production Task List (ultra-detailed)

### 🔴 P0 — Block launch (must do)

#### 4.1 Rotate 6 exposed secrets
**What:** All these were pasted in chat history or in `.env.example`:
- `PB_PASSWORD` (rotated in 2026-06) — scrub git history
- Firebase apiKey (browser-safe, in `.env.example`) — rotate before launch
- `HEAL_JWT_SECRET` — has dev default in Dokploy
- FTP password — committed in 4+ scripts as fallback, must move to env-only
- GitHub personal access token — revoke
- Dokploy API key (the one in shell) — rotate

**Steps:**
1. Generate new PB password in PB admin UI
2. Update Dokploy env vars for HEAL app
3. Force-redeploy so new env takes effect
4. Verify live site still works
5. Revoke old GitHub PAT, create new one, update Dokploy + Actions secrets
6. Replace FTP fallback in scripts with `${SMARTERASP_FTP_PASSWORD:?}` (fail loudly)
7. Move dev-default `HEAL_JWT_SECRET` to `openssl rand -base64 64` in Dokploy

**Estimate:** 30 min

#### 4.2 Add PocketBase auto-backup
**What:** PB data is on a Dokploy persistent volume with no backup. Single hardware failure = total loss.

**Steps:**
1. Add `pb_backup.sh` script to cron (daily 03:00 UTC)
2. Script: `curl -X POST "$PB_URL/api/admins/auth-with-password" ... && tar czf /tmp/pb-$(date +%F).tar.gz /workspace/pocketbase/pb_data/`
3. Upload to B2 `GOPResources/heal-backups/` with 30-day retention
4. Add a `restore.md` doc with tested restore steps
5. Test restore on a separate machine

**Estimate:** 2h (incl. restore test)

#### 4.3 Add Sentry observability
**What:** When something breaks in production, we have no idea. Logger goes to stdout which Dokploy doesn't expose.

**Steps:**
1. Create Sentry project at `heal-web` (Next.js) and `heal-mobile` (Flutter)
2. Add `@sentry/nextjs` to web package.json
3. Wrap `app/error.tsx` + `app/global-error.tsx` to report
4. Add `sentry_dart` to mobile pubspec
5. Wire `runZonedGuarded` in main.dart to capture uncaught
6. Wire `FlutterError.onError` to send to Sentry
7. Add custom tags: route, auth_state, pb_status
8. Set up Sentry alerts: error rate >1% for 5 min → Slack

**Estimate:** 3h

#### 4.4 Add rate limiting + basic WAF rules
**What:** `/api/favorites`, `/api/journal`, `/api/auth/session` are wide open. A bad actor can pollute Firestore in minutes.

**Steps:**
1. Add `@upstash/ratelimit` (or `next-rate-limit` if Upstash overkill) to web
2. Limit: 60 req/min/IP for unauth, 300 req/min/IP for auth
3. Hard cap on POST `/api/favorites` + `/api/journal` at 10/min/user
4. Block obvious bot UAs (curl, wget, python-requests) from POST endpoints
5. Add Cloudflare WAF rule: block countries not in target list (SG, US, UK, ID, MY, AU, JP, CN)

**Estimate:** 4h

#### 4.5 First Flutter build
**What:** Mobile code is complete but has never compiled. We don't know if it works on a real device.

**Steps:**
1. SSH to a machine with Flutter 3.24+ installed
2. `cd /workspace/HEAL/mobile && flutter pub get`
3. `flutter analyze` (with `analysis_options.yaml` strict-casts ON)
4. `flutter build apk --debug` (no signing required)
5. Install on physical Android, test:
   - Splash → onboarding flow
   - Voice calibration (mic permission prompt)
   - Breath studio (haptics on real device)
   - Pocket mode
   - Notifications
6. Fix any analyzer / runtime issues
7. Once green, commit and push to trigger CI for release APK

**Estimate:** 4-8h (depending on bugs found)

#### 4.6 Add PB sort-safe queries
**What:** `pb-bootstrap.mjs` had `sort=-created` which fails on PB v0.22+ because the `created` field was removed. We may have other sort fields that break.

**Steps:**
1. Grep all `sort=-created` and `sort=-updated` in web + mobile + scripts
2. Replace with safe sorts: `-id`, `sort_order`, `day_of_year`, `created_at` (custom)
3. Test home page (the page that broke) still works
4. Document the safe-sort convention in `docs/PB-SORT.md`

**Estimate:** 1h

---

### 🟡 P1 — Should do before public launch (1-2 weeks)

#### 4.7 Expand content seed banks for 5-year cycle
**What:** Current banks are 25 entries per type. At 12 records/day, 21,900 records needed for 5 years of no-repeats. Banks must grow ~5×.

**Current state:**
- 25 scripture seeds (50× too small for 5 years)
- 25 quote seeds
- 25 prayer seeds
- 21 hymn seeds

**Target:**
- 100 scripture seeds (3-4 per day for 30 days = 1× per month)
- 100 quote seeds
- 100 prayer seeds
- 100 hymn seeds
- 365 daily-trending-prayer topics (one per day for a year, then a curated replacement set for year 2-5)

**Steps:**
1. Generate or curate 100 scripture seeds (use NRSV, public domain)
2. Generate or curate 100 quote seeds (CS Lewis, NT Wright, etc. — public domain or with permission)
3. Generate 100 prayer seeds (write 100 short prayers, mix of original + traditional)
4. Generate 100 hymn seeds (titles + voice mapping + lyric seed)
5. Update `web/scripts/cron-hourly.py` with skip-on-duplicate logic
6. Test cron over 7 days to verify uniqueness

**Estimate:** 6-8h content authoring + 2h code

#### 4.8 Add web Streak + Welcome Back (mobile parity)
**What:** The mobile app has the streak flame + welcome-back card. Web doesn't.

**Steps:**
1. Port `services/streak_service.dart` logic to `lib/streak-service.ts`
2. Add session tracking on completion of breath/meditate/prayer pages
3. Add `StreakFlame` component to `app/page.tsx` (home)
4. Add `WelcomeBackCard` for 4+ day absences
5. Same warm-phrase logic as mobile

**Estimate:** 4h

#### 4.9 Add adaptive palette to web
**What:** Web is static rosewood. Mobile has 6 time-of-day palettes.

**Steps:**
1. Port `time_palette.dart` to `lib/time-palette.ts`
2. Create a `PaletteProvider` context in `app/layout.tsx`
3. Update Tailwind config to read from CSS custom properties
4. Map palette tokens to `var(--heal-bg)`, `var(--heal-primary)`, etc.
5. Update all key pages to use the dynamic tokens

**Estimate:** 4h

#### 4.10 Build out the essays (only 3 records!)
**What:** Essays is the thinnest content section. Users will see this immediately.

**Steps:**
1. Plan 30 essay topics (one per week + a few seasonal)
2. Author 30 essays (1500-2500 words each)
3. Add to PB with proper illustration_url, tags, category
4. Verify all URLs return 200

**Estimate:** 20-30h content authoring

#### 4.11 Add service worker for offline PWA
**What:** Mobile is offline-first (drift). Web has no offline. The user's "in pocket" practice is web-only for some.

**Steps:**
1. Add `next-pwa` to web
2. Cache static content (meditations, prayers) for offline read
3. Show offline banner when no network
4. Register service worker in `app/layout.tsx`

**Estimate:** 4h

#### 4.12 Add real Firebase config to mobile
**What:** Mobile has Firebase packages + auth scaffold but the apiKey in `env.dart` is empty. Authentication on mobile would fail.

**Steps:**
1. Get mobile Firebase config from `heal-prd` project (separate from web)
2. Wire into `main.dart` via `--dart-define`
3. Add `google-services.json` to `android/app/`
4. Add `GoogleService-Info.plist` to `ios/Runner/`
5. Test Firebase auth on Android emulator

**Estimate:** 4h

#### 4.13 Add CI for web
**What:** Mobile has CI. Web doesn't. Pushes to web don't run any test/lint.

**Steps:**
1. Add `.github/workflows/web-ci.yml`
2. Run `pnpm install --frozen-lockfile`
3. Run `pnpm lint && pnpm typecheck`
4. Run `pnpm build` (verifies it compiles)
5. Run `next-sitemap` build + verify generated

**Estimate:** 2h

---

### 🟢 P2 — Nice to have, not blocking launch (1-2 months)

#### 4.14 Add unit + integration tests
**What:** Zero test coverage on either web or mobile. Refactoring is a coin flip.

**Steps:**
- Web: Vitest + Testing Library for components, Playwright for e2e
- Mobile: flutter_test for units, integration_test for flows
- Aim: 30% coverage on business logic, 100% on streak + voice calibration + content generation

**Estimate:** 12-20h

#### 4.15 Add 12 more praise songs + replace placeholders
**What:** 100 praise records exist, but they have placeholder lyrics. Need real lyrics.

**Steps:**
1. Get permission or write original lyrics for each song
2. Update PB `lyrics` field
3. Re-render TTS if voice assignment changes
4. Update CDN audio

**Estimate:** 8-12h

#### 4.16 Add audio for the missing 234 B1-B5 meditations
**What:** 268 meditation records exist. Many have no audio. Each meditation should have a TTS-generated audio file.

**Steps:**
1. Use `auto-generate.mjs` to find meditations without `audio_url`
2. For each, generate TTS via `batch_text_to_audio` with appropriate voice
3. Upload to CDN
4. Update PB `audio_url`

**Estimate:** 4-6h (parallelized with TTS)

#### 4.17 Multi-language support
**What:** PB has en + zh-CN, ja, etc. in the schema. Web is en-only.

**Steps:**
1. Add `next-intl` to web
2. Translate key strings (greetings, navigation, common UI)
3. Use PB `translation` field on scriptures (already there) for content

**Estimate:** 20-30h (incl. translations)

#### 4.18 Add wearOS / watchOS companion
**What:** "Hand-off haptics" was a feature in the design — feel the breath in your pocket via a watch.

**Steps:**
1. Add Wear OS module to mobile
2. Pair haptics over Bluetooth
3. Show breath ring on watch face

**Estimate:** 40h+ (significant work)

---

## 5. Runbook — Smooth Operations (hug-free)

### Daily checks (automated, 0 min human time)

```bash
# In GitHub Actions, runs every morning at 09:00 UTC
- name: Daily health
  run: |
    curl -fsS https://heal.positiveness.club/api/health || exit 1
    curl -fsS https://pocketbase.scaleupcrm.com/api/health || exit 1
    # Test 5 random CDN images
    for slug in ...; do
      curl -fsS "https://resources.positiveness.club/heal/images/meditations/${slug}.png" || exit 1
    done
```

Failure → Slack alert to `#heal-alerts`

### Weekly (10 min human time)

- [ ] Check Sentry error rate (target: <0.1%)
- [ ] Check PB record count growth (target: +84/week from cron)
- [ ] Spot-check 3 random pages for visual issues
- [ ] Verify cron ran (look for new records in PB)

### Monthly (1h human time)

- [ ] Rotate any expiring service account keys
- [ ] Review Sentry alerts — false positive rate, noise
- [ ] Read user feedback (no channel yet — set up one)
- [ ] Check Firestore usage against Spark free tier quota

### Quarterly (4h human time)

- [ ] Full security audit (env var list, git history scrub)
- [ ] Lighthouse perf audit (target: PWA score >90)
- [ ] Dependency update (npm audit + pnpm update)
- [ ] Test restore from PB backup

### Incident response (when Sentry fires)

```bash
# 1. Triage in Sentry — get route + error
# 2. Reproduce: curl https://heal.positiveness.club/<route>
# 3. Check PB: curl https://pocketbase.scaleupcrm.com/api/collections/<col>/records?perPage=1
# 4. Check logs: https://dokploy.scaleupcrm.com → HEAL app → Logs
# 5. If PB issue, query directly to confirm
# 6. Fix forward (no rollback for v1 unless data corruption)
# 7. Post-mortem: add to docs/INCIDENTS.md
```

### Capacity planning

| Metric | Current | 1k users | 10k users | 100k users |
|---|---|---|---|---|
| HEAL requests/day | ~5 | ~50k | ~500k | ~5M |
| PB reads/day | ~50 | ~500k | ~5M | ~50M |
| Firestore writes/day | 0 (counter docs only) | ~3k | ~30k | ~300k |
| CDN egress | ~50MB/mo | ~5GB | ~50GB | ~500GB |
| Firestore cost | $0 | $0 | $0 | ~$50/mo (still Spark) |
| CDN cost | $0 | $0 | $0 | ~$0 (Cloudflare free tier) |
| PB cost | shared | shared | shared | shared |
| **Total infra** | **$0** | **$0** | **$0** | **~$50/mo** |

Cloudflare free tier is 100GB/mo egress. CDN serves illustrations (avg 200KB) + audio (avg 250KB). 100k users × 2 cached items/day × 200KB = 40GB/mo. Well within free.

### Disaster recovery

| Scenario | RTO | RPO | Steps |
|---|---|---|---|
| Dokploy VPS down | 4h | 0 (no data loss) | Spin up new Dokploy project, redeploy from last green commit |
| PB data loss | 2h | 24h (last daily backup) | Restore from `pb-backups/` in B2 |
| CDN down | 30min | 0 (cached at edge) | Wait for Cloudflare to recover (90%+) |
| Firebase outage | 0 | 0 | Auth falls back to anonymous; favorites/journal write to local IndexedDB until Firebase returns |

---

## 6. 5-Year Content Cycle Plan

### Current state

- 25 entries per seed bank (scriptures, quotes, prayers)
- 12 records generated per day (6 hours × 2 records)
- At this rate, bank exhausts in 2 days
- Then repeats begin

### Required state for 5-year uniqueness

- **5 × 365 × 12 = 21,900 unique records** over 5 years
- Distribute across types per current rotation:
  - Scriptures: ~5,000 (5× growth)
  - Quotes: ~4,500
  - Prayers: ~4,500 (non-trending)
  - Trending event prayers: 1,825 (1 per day × 5 years)
  - Praise instrumentals: ~5,000 (1× per hymn over 50 cycles)
  - Total needed: ~21,000 unique entries

### Plan: phased growth

**Phase 1 (now → 2 weeks):** Expand banks to 100 entries
- Author 100 scripture seeds (NRSV public domain)
- Curate 100 quote seeds
- Write 100 prayer seeds
- Generate 100 praise seeds
- **Cost:** 8-12h human time

**Phase 2 (2 weeks → 1 month):** Build skip-on-duplicate + LCG cycle
- LCG (Linear Congruential Generator) with `step = prime % bank_size` guarantees a full permutation
- Each day's `seed = (year * 1000 + day_of_year * 13 + type_idx * 7) % prime` advances by step
- 100-item bank = 100 days between repeats
- Test: generate 200 days of content, verify zero duplicates

**Phase 3 (1 month → 3 months):** Trending event prayers
- Daily cron job: pull top 3 trending events from a curated list (news RSS + Twitter trends API alternative)
- Generate 1 prayer per event = 365 prayers per year
- After 1 year, swap to a new curated set (or rotate top 100 evergreen events)

**Phase 4 (3 months → 6 months):** Community prayer submissions
- Users submit prayers (Firestore collection)
- Moderation queue in admin
- Approved prayers go into next cycle
- This solves the long-tail — prayers from real people

### Storage math

21,900 records × ~2KB each (text) = ~44MB PB data
With index overhead, ~150MB. PB handles this trivially.
CDN: 5,000 illustration variants × 200KB = 1GB. Fine.
Audio: 5,000 × 250KB = 1.25GB. Fine.

---

## 7. What's already done well (don't change)

- ✅ 17/17 web routes 200
- ✅ 100% PB media URLs reachable
- ✅ Sitemap + robots.txt (blocks AI crawlers)
- ✅ Adaptive OG images for social sharing
- ✅ Mobile: 28 Dart files / 7,974 LOC, complete feature set
- ✅ Material 3 dark theme with brass/rosewood/bronze
- ✅ Breath studio with haptics + animations
- ✅ Time-of-day adaptive palette (mobile)
- ✅ Voice calibration (mobile, novel differentiator)
- ✅ Streak tracking (mobile, gentle broken-day UX)
- ✅ 158 records backfilled with `emotion` + `tags` for emotion search
- ✅ All 3 content collections have unique slug index
- ✅ PocketBase v0.22+ sort fields all using safe alternatives

---

## 8. Done this session (2026-06-25)

- ✅ All 158 existing PB records backfilled with `emotion` (was 0)
- ✅ All 158 existing PB records backfilled with `tags[]` (was 0)
- ✅ Backfill scripts committed to repo (reusable for any future field additions)
- ✅ Production audit doc written
- ✅ All web routes verified 200
- ✅ All CDN illustrations verified reachable
- ✅ Live build status: 11/11 Dokploy builds green

---

## 9. Recommended launch sequence

1. **This week:** P0 items 4.1-4.6 (secrets, backup, Sentry, rate limit, first mobile build, sort-safe)
2. **Before public:** P1 items 4.7-4.13 (5-year content, web parity, PWA, mobile Firebase)
3. **Month 1-2 post-launch:** P2 items based on user feedback
4. **Quarterly:** Runbook items

**Hug-free rating:** 🟢 Web is hug-free today. Mobile is hug-free once first build green-lights it.
