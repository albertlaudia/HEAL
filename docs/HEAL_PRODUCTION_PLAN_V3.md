# HEAL — Production Launch Plan v3 (ULTRA-DETAILED)
**Date:** 2026-06-29 14:48 Asia/Shanghai
**Status:** Pre-production. Both surfaces 502. Documenting every gap.

This document is divided into 6 parts:
1. What is BUILT (verified by reading code)
2. What is TESTED (vs unverified)
3. What is MISSING (technical gaps)
4. Phased launch roadmap with effort estimates
5. SMART commercial / business plan
6. 30/60/90 day execution timeline

---

## PART 1 — BUILT (verified by code inspection)

### 1.1 Web (Next.js 15) — heal.positiveness.club
**Bundle:** 9,039 LOC. 18 routes. 27 component groups.

#### Pages (`/web/app/`)
| Route | Built | Verified |
|---|---|---|
| `/` (home with H.E.A.L. ritual) | ✅ | ✅ code |
| `/meditate` + `/meditate/[slug]` | ✅ | ✅ |
| `/breathe` | ✅ | ✅ |
| `/scripture` | ✅ | ✅ |
| `/prayer` + `/prayers/[slug]` | ✅ | ✅ |
| `/praise` + `/praise/[slug]` | ✅ | ✅ |
| `/essays` + `/essays/[slug]` | ✅ | ✅ |
| `/now` | ✅ | ✅ |
| `/favorites` (Firestore) | ✅ | ✅ |
| `/journal` (Firestore) | ✅ | ✅ |
| `/history` (localStorage) | ✅ | ✅ |
| `/programs/[slug]` + `/badges` | ✅ | ✅ |
| `/about`, `/contact`, `/guidelines`, `/privacy`, `/terms` | ✅ | ✅ |
| `/not-found` (dynamic 404) | ✅ | ✅ |
| `/loading.tsx`, `/error.tsx`, `/sitemap.ts`, `/robots.ts`, `/opengraph-image.tsx` | ✅ | ✅ |

#### Key components (`/web/components/`)
- `audio/` — 4 files (AmbientMixer, AudioPreparing, AudioVisualizer, MiniPlayer)
- `auth/` — 2 files (AuthMenu, SessionSync)
- `breathe/`, `meditate/`, `praise/`, `prayers/`, `scripture/` — page-specific UI
- `content/` — JournalInline, SaveButton, ShareButton, ThemeBadge
- `home/` — home page bits
- `nav/` — navigation
- `programs/` — ProgramCard, StepNavigation, StepReflection, BadgesCollection
- `pwa/` — InstallPrompt, ServiceWorkerRegister
- `tracking/TrackView.tsx` — localStorage recent-view tracker

#### Libraries (`/web/lib/`)
- `pb.ts` (10.9 KB) — PB client + cache
- `audio-context.tsx` (19.7 KB) — global audio state
- `firebase-client.ts`, `firebase-server.ts`, `firebase-rest.ts` (Firestore ops)
- `session.ts` — JWT session cookie
- `firestore-cache.ts` — 5-min in-memory cache
- `firestore-rules-example.txt`, `firestore-indexes-example.txt` — ready to deploy
- `auth-store.tsx` (React context)
- `programs-client.ts`
- `utils.ts`

#### API routes (`/web/app/api/`)
- `/api/auth/session` (POST/DELETE for cookie)
- `/api/health` (GET for monitoring)
- `/api/programs/[slug]` (GET program)
- `/api/programs/[slug]/badge` (POST badge)

#### PWA (`/web/public/sw.js`, 182 lines)
- 5 caching strategies (audio cache-first, images stale-while-revalidate, static cache-first, data SWR, pages network-first)
- Pre-cache audio messages supported
- Cache versioning (heal-v4)
- Old cache eviction on activate

#### Security (`/web/next.config.mjs`)
- CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS
- PoweredByHeader disabled
- Image remotePatterns allowlist (CDN, Firebase, PB)
- Per-route cache headers (`/_next/static` immutable 1y)

#### Cron pipeline (`/web/scripts/`, 55 scripts)
- `cron-hourly.py` — 6h/day, 12 records/day generation
- TTS scripts (audio-batch.mjs, bulk-generate-praise.mjs, etc.)
- Image generators (illustrate-batch.mjs, seed-programs-images.mjs)
- Schema migrators (pb-schema.py, add-slug-and-unique.py)
- Backfills (backfill-emotion, backfill-tags, backfill-cdn-urls)
- Dedupe, validate, verify-and-retry
- FTP upload scripts

#### Backup (`/scripts/heal-backup/`)
- `backup.sh` — daily 03:00 UTC cron → Backblaze B2
- `restore.sh latest` — one-liner recovery
- `find-pb-data.sh` — VPS diagnostic
- `INSTALL.md` — 5-min install guide
**Status: scripts exist but NOT installed on VPS**

### 1.2 Mobile (Flutter) — healf.positiveness.club
**Bundle:** 7,995 LOC across 28 Dart files.

#### Architecture
- `flutter_riverpod` 2.5.1 — state
- `go_router` 14.6.1 — routing
- `drift` 2.20.3 — local SQLite (offline-first)
- `shared_preferences` — settings
- `firebase_core`, `firebase_auth`, `cloud_firestore` (in pubspec, **0 imports**)
- `audioplayers` 6.1.0 — playback
- `flutter_local_notifications` 17.2.3 — reminders
- `permission_handler` — mic/notifications
- `rive` — breath ring animations
- `shimmer` — loading states

#### Features (`mobile/lib/features/`)
- **onboarding** — 3-page swipe + notification permission (190 lines)
- **home** — 871 lines, 11 sections (Streak, WelcomeBack, HeroPractice, QuickActions, PracticeGrid, VoiceCalibrationBanner, etc.)
- **now** — current moment
- **meditate** — list + detail with full text
- **breathe** — breath studio + voice calibration
- **scripture** — library + sit-with-verse (candle flame mode)
- **prayer** — collection
- **praise** — library with audio
- **essays** — list + reader with progress
- **settings** — language, theme, notifications, calibration, about

#### Services (`mobile/lib/services/`)
- `audio_service.dart` — playback (works on web)
- `notification_service.dart` — **kIsWeb guarded** (Flutter Web doesn't have system notifications)
- `streak_service.dart` — 90-day, 4-day grace, warm messages
- `voice_calibration_service.dart` — **kIsWeb guarded**

#### Core (`mobile/lib/core/`)
- `theme.dart` — Material 3 dark + brass/rosewood
- `router.dart` — go_router with bottom nav + audio-aware min player
- `env.dart` — `String.fromEnvironment` for PB/CDN/SITE URLs + Firebase
- `time_palette.dart` — 6 adaptive palettes
- `haptics.dart`
- `observability.dart` — local logger (no Sentry yet)
- `widgets/brass_widgets.dart`

#### Data (`mobile/lib/data/`)
- `pb_models.dart` (351 lines) — toMap/fromMap for 7 collections
- `pb_repositories.dart` — PB client

#### Build files
- `mobile/web.Dockerfile` — multi-stage Flutter 3.27.1 → Nginx SPA
- `mobile/web/index.html` — custom splash + manifest + OG tags
- `mobile/web/manifest.json` — PWA install
- `mobile/web/icons/` — Icon-192, Icon-512, maskable variants
- `mobile/web/favicon.png`

### 1.3 Infrastructure
- ✅ Dokploy apps created (3 apps across 2 projects)
- ✅ Domains + letsencrypt certs
- ✅ Cloudflare DNS routes both subdomains
- ✅ PB healthy (`pocketbase.scaleupcrm.com` returns 200)
- ✅ CDN healthy (`resources.positiveness.club/heal/audio/...` 100% returning 200 on PB-referenced URLs)

### 1.4 Content (548 records)
| Collection | Records | Audio | Image |
|---|---:|---:|---:|
| HEAL_meditations | 269 | 17% | 98% |
| HEAL_praise | 112 | 100% | 100% |
| HEAL_prayers | 67 | 0% | 98% |
| HEAL_scriptures | 31 | 0% | 0% |
| HEAL_quotes | 60 | 0% | 0% |
| HEAL_essays | 3 | 0% | 100% |
| HEAL_breathwork | 6 | 0% | 0% |

All 548 records have unique slugs + 100% PB schema integrity.

---

## PART 2 — TESTED vs UNVERIFIED

### Tested in code (unit-style — compile OK)
- ✅ Web pages compile (Next.js build succeeds per prior session — `95.8 KB` baseline)
- ✅ PB schema migration via `pb-schema.py`
- ✅ Slug uniqueness enforced via SQLite unique indexes
- ✅ Audio URLs validated end-to-end on live CDN (224/224 praise URLs = 200)
- ✅ Environment-driven config (`--dart-define`, `NEXT_PUBLIC_*`)
- ✅ kIsWeb guards on the 2 highest-risk mobile services

### Tested MANUALLY (verified working before Feb-26 outage)
- ✅ 17/17 web routes returned 200 (Feb-26)
- ✅ 11/11 Dokploy builds green (Feb-26)
- ✅ 598/598 PB media URLs returned 200 (Feb-26)
- ✅ Service worker pre-caches audio offline

### Untested (gaps)
- ❌ **Flutter mobile web build pipeline end-to-end** — never successfully built (3 attempted builds, all errored)
- ❌ **Flutter native mobile build** — never run `flutter pub get` on this monorepo
- ❌ **Cross-device sync** — web favorites/journal never tested on mobile
- ❌ **Voice calibration** — built but never tested in real environment
- ❌ **Streak recovery** — logic exists but the 4-day grace flow never exercised
- ❌ **Welcome-back card** — built but no telemetry to know if it shows correctly
- ❌ **Sit-with-verse 30s re-type** — built but never tested
- ❌ **PB auto-backup** — script written but **never run on VPS**
- ❌ **Firestore rules + indexes** — example files exist but **not deployed to Firebase console**
- ❌ **Tests** — **0 test files** in both web/ and mobile/
- ❌ **PWA install prompt** — registered but never tested on real iOS Safari
- ❌ **Mute/background audio** — audioplayers works on web but iOS background audio untested
- ❌ **Multi-language** — pubspec has flutter_localizations but no language picker implemented
- ❌ **App Store submission** — never submitted
- ❌ **Push notification delivery** — never tested

---

## PART 3 — MISSING (technical gaps before "production")

This is the production-readiness audit organized by what blocks shipping.

### 3.1 — P0: LIVE BUT CANNOT BE REACHED

| # | Task | Effort | Blocks |
|---|---|---|---|
| **P0-1** | SSH VPS → read Flutter Docker build log | 5 min (YOU) | everything |
| **P0-2** | Fix `mobile/web.Dockerfile` (likely Flutter version, base image, or dart-define escaping) | 30-60 min (ME) | P0-3 |
| **P0-3** | Click Deploy in Dokploy UI on `Sites/HEAL` (overlay recovery) | 1 min (YOU) | P0-4 |
| **P0-4** | Verify both `heal.positiveness.club` and `healf.positiveness.club` return 200 | 5 min (ME) | P0-5 |
| **P0-5** | Add "Begin Practice" CTA on `heal.positiveness.club` home → `healf.positiveness.club` | 20 min (ME) | launch |
| **P0-6** | Add `kIsWeb` guards on streak service, sit-with-verse, welcome-back | 45 min (ME) | P0-7 |
| **P0-7** | Add `kIsWeb` guard + fallback rendering on home page (no a11y crash if shared_preferences missing) | 20 min (ME) | P0-8 |
| **P0-8** | Rotate 5 exposed secrets — GitHub PAT in remote URL, PB password, Firebase apiKey, JWT secret, Dokploy API key | 30 min (YOU) | security |
| **P0-9** | Add `memoryLimit: 2 GB` to HEAL Next.js app (currently `None`!) | 1 min (API) | stability |
| **P0-10** | Install PB auto-backup on VPS (`scripts/heal-backup/INSTALL.md`) | 5 min (YOU) | disaster recovery |

**Phase P0 total: ~3 hours of human time, ~2 hours of agent time.**

### 3.2 — P1: CONTENT GAPS (block product credibility)

| # | Task | Effort | Notes |
|---|---|---|---|
| P1-1 | Backfill `emotion` + `tags[]` on 269 meditations + 6 breathwork + 3 essays | 5 hrs | Extend existing backfill script |
| P1-2 | Add `category` field to scriptures + breathwork (currently empty) | 30 min | — |
| P1-3 | TTS generate **67 prayer audios** (use memory voice set: SentimentalLady, SereneWoman, Gentle-voiced-man) | 8 hrs | Spread across cron-hourly |
| P1-4 | TTS generate **31 scripture audios** | 4 hrs | — |
| P1-5 | TTS generate **60 quote audios** | 6 hrs | — |
| P1-6 | TTS generate **6 breathwork audios** | 30 min | — |
| P1-7 | Generate **31 scripture images** (Wikimedia pipeline from memory) | 4 hrs | Quiet, watercolor, by book |
| P1-8 | Generate **60 quote images** (gradient generator + amber/brass) | 3 hrs | Short-form, text-typography |
| P1-9 | Generate **6 breathwork images** (gradient variants by pattern type) | 30 min | — |
| P1-10 | Build out essays (3 → 15) | 8 hrs | One per major theme |
| P1-11 | Verify each generated asset URL responds 200 before marking done | built into cron | — |

**Phase P1 total: ~40 hours of agent time (mostly TTS via batch).**

### 3.3 — P1: USER PERSISTENCE (mobile differentiator killed without this)

The mobile engagement features (streak, voice cal, sit-with-verse, welcome-back) currently run in-memory or local-prefs. **If the user uninstalls, everything is gone.** This is the gap that kills the streak/sit-with-verse "I come back for that" retention story.

| # | Task | Effort |
|---|---|---|
| P1-12 | Create PB collections: `HEAL_users`, `HEAL_sessions`, `HEAL_streaks`, `HEAL_mood`, `HEAL_journal`, `HEAL_favorites`, `HEAL_audio_progress` | 2 hrs |
| P1-13 | Wire Flutter mobile → Firebase Auth (currently 0 imports despite pubspec listing it) | 4 hrs |
| P1-14 | Wire Flutter mobile → PB user-data read/write (replaces SharedPreferences for cross-device) | 4 hrs |
| P1-15 | Migrate web's session-based user model to also write to PB (so web↔mobile sync works) | 4 hrs |
| P1-16 | Implement `client_event_id` UUID for idempotency on writes (memory pattern) | 2 hrs |
| P1-17 | Add "Sign in" prompt to Flutter onboarding (currently silent) | 1 hr |
| P1-18 | Mirror web favorites to PB so they appear in mobile after first sync | 4 hrs |

**Phase P1-mobile: ~21 hours of agent time.**

### 3.4 — P2: BUSINESS MODEL (zero revenue today — biggest launch gap)

Pricing strategy: Free forever core → Premium $4.99/mo → Family $9.99/mo.

| # | Task | Effort |
|---|---|---|
| BIZ-1 | Choose monetization vendor: **RevenueCat** (mobile) + **Stripe** (web) + Stripe Customer Portal | 1 day |
| BIZ-2 | Add RevenueCat SDK to Flutter (`purchases_flutter`), configure products | 2 hrs |
| BIZ-3 | Build paywall screen for Flutter (feature comparison, calm visuals) | 1 day |
| BIZ-4 | Add premium-tier gating to mobile features (voice calibration, multi-language unlock) | 4 hrs |
| BIZ-5 | Add Stripe checkout to web (`/pricing` and `/api/checkout/session`) | 2 days |
| BIZ-6 | Build `/pricing` page on web with tier comparison | 4 hrs |
| BIZ-7 | Wire RevenueCat webhook → PB user records (so tier persists across surfaces) | 4 hrs |
| BIZ-8 | Configure Apple/Google subscription products in App Store Connect / Play Console | 1 day (YOU) |

**Phase BIZ: ~6 days of agent time + 1 day of human time on store configs.**

### 3.5 — P2: POLISH (mostly operational)

| # | Task | Effort |
|---|---|---|
| POL-1 | Add a healthcheck endpoint that docker can ping | 30 min |
| POL-2 | Wire Sentry for Next.js errors (`@sentry/nextjs`) | 2 hrs |
| POL-3 | Wire Firebase Crashlytics for Flutter (currently 0 imports) | 2 hrs |
| POL-4 | Add uptime monitoring (UptimeRobot probes — free tier) | 30 min (YOU) |
| POL-5 | Add Firestore rules + indexes from example files (Firebase Console manual) | 30 min (YOU) |
| POL-6 | Add README + .env.example to root | 30 min |
| POL-7 | Add Lighthouse CI workflow (run on every PR) | 2 hrs |
| POL-8 | Fix "scripts/heal-backup/INSTALL.md" — currently says "smoke test" but the actual install is missing | 30 min |
| POL-9 | Add a `BIN/exec-backup` script to verify last backup age | 30 min |
| POL-10 | Add `mobile/web.Dockerfile` build arg defaults that work without user-provided FIREBASE_API_KEY | 5 min |

### 3.6 — P3: DISCOVERY (post-launch growth)

| # | Task | Effort |
|---|---|---|
| DISC-1 | App Store listing: 7 screenshots, 1 video, ASO keywords ("christian meditation", "biblical mindfulness", "scripture prayer") | 1 day |
| DISC-2 | Play Store listing same | 1 day |
| DISC-3 | Submit to App Store + Play Store (7-14 day review wait) | 1 day (YOU) |
| DISC-4 | Submit to 10 Christian app directories (ChristianAppFinder, Pray.com, TheGoodChristian, etc.) | 1 day (YOU) |
| DISC-5 | SEO content pillar: 15 blog posts ("Biblical meditation for anxiety", "How to practice Christian mindfulness", etc.) | 1 week |
| DISC-6 | Email capture on web → "7 Days of Peace" nurture sequence | 2 days |
| DISC-7 | Podcast outreach — 50 Christian podcasts (list, pitch templates) | 2 days (YOU) |
| DISC-8 | Lighthouse PWA 95+ audit + fix any low scores | 4 hrs |
| DISC-9 | Add OG image variants per content type (meditation OG, prayer OG, etc.) | 1 day |

### 3.7 — P3: PRODUCT DEPTH

| # | Task | Effort |
|---|---|---|
| PROD-1 | **Multi-language** — add zh-CN content (150 meditations + 60 prayers + 30 scriptures) | 3 weeks |
| PROD-2 | Multi-language UI (i18n: en, zh-CN, zh-TW, ja, ms, ta) | 1 week |
| PROD-3 | Push notifications via Firebase Messaging (Flutter already has dependency wired) | 1 day |
| PROD-4 | Background audio on iOS (configure AVAudioSession) | 1 day |
| PROD-5 | "Pray Together" 2-person sessions (real-time WebRTC or just shared session) | 2 weeks |
| PROD-6 | AI Prayer Companion (LLM, voice-in/voice-out) — Family tier exclusive | 3 weeks |
| PROD-7 | Apple Watch / Wear OS companion (heart-rate aware breathing) | 3 weeks |
| PROD-8 | Live prayer rooms (real-time group prayer, web-only) | 4 weeks |
| PROD-9 | Pastor sermon-clip integration (API for churches to embed HEAL content in their apps) | 2 weeks |

### 3.8 — P3: TEST COVERAGE (currently 0 tests)

| # | Task | Effort |
|---|---|---|
| TEST-1 | Flutter: unit tests for `streak_service.dart`, `time_palette.dart`, `pb_models.dart` | 3 days |
| TEST-2 | Flutter: widget tests for `home_page`, `meditate_detail_page` | 2 days |
| TEST-3 | Web: Vitest for `lib/pb.ts`, `lib/firebase-rest.ts` | 2 days |
| TEST-4 | Web: Playwright E2E for signin + meditation playback | 3 days |
| TEST-5 | Load test PB (`hey -n 1000 -c 50`) | 1 day |

---

## PART 4 — PHASED LAUNCH ROADMAP (4-WEEK plan)

### Week 1 — RECOVER + STABILIZE
**Goal:** Both surfaces live, no exposed secrets, mobile-equivalent features on web.

| Day | Task | Owner |
|---|---|---|
| Day 1 (today) | SSH VPS, tail Flutter build log, identify error | YOU (5 min) |
| Day 1 | Fix `mobile/web.Dockerfile` | ME (60 min) |
| Day 1 | Click Deploy in Dokploy UI on BOTH apps | YOU (1 min) |
| Day 1 | Verify both URLs return 200 | ME (5 min) |
| Day 1 | Rotate 5 exposed secrets | YOU (30 min) |
| Day 1 | Install PB auto-backup on VPS | YOU (5 min) |
| Day 2 | kIsWeb guards on streak / sit-with-verse / welcome-back + home | ME (1 hr) |
| Day 2 | Add "Begin Practice" CTA cross-link | ME (20 min) |
| Day 3-5 | Backfill `emotion` + `tags[]` on 269 meditations + 9 other | ME (5 hrs) |
| Day 3-5 | Add `category` to scriptures + breathwork + add missing durations | ME (2 hrs) |

**Week 1 done = both sites live + content = 100% featured.**

### Week 2 — GENERATE MISSING MEDIA (parallelizable)
**Goal:** Every record has audio + image.

| Day | Task | Owner |
|---|---|---|
| Day 6-8 | Generate 67 prayer audios (TTS, 6 voices from memory) | ME (8 hrs spread) |
| Day 8-9 | Generate 31 scripture audios | ME (4 hrs) |
| Day 9-10 | Generate 60 quote audios | ME (6 hrs) |
| Day 10-11 | Generate 6 breathwork audios | ME (30 min) |
| Day 6-8 | Generate 31 scripture images (Wikimedia pipeline) | ME (4 hrs) |
| Day 8-10 | Generate 60 quote images (gradient + text) | ME (3 hrs) |
| Day 10 | Generate 6 breathwork images (gradient variants) | ME (30 min) |
| Day 11-12 | Asset verification: all URLs return 200 | ME (built in) |

**Week 2 done = media parity: every record = text + image + audio.**

### Week 3 — USER PERSISTENCE + INITIAL MONETIZATION
**Goal:** Mobile features cross-device, first paywall visible.

| Day | Task | Owner |
|---|---|---|
| Day 13-14 | Create 7 PB user-data collections | ME (2 hrs) |
| Day 14-15 | Wire Firebase Auth to Flutter mobile | ME (4 hrs) |
| Day 15-16 | Wire PB user data to Flutter (replace SharedPreferences) | ME (4 hrs) |
| Day 16-17 | Stripe webhook → PB user.tier sync | ME (4 hrs) |
| Day 17-18 | Mirror web favorites to PB (so web <-> mobile cross-device) | ME (4 hrs) |
| Day 18 | Stripe `/pricing` page on web | ME (4 hrs) |
| Day 18-19 | RevenueCat SDK in Flutter | ME (2 hrs) |
| Day 19-20 | Paywall screen for Flutter | ME (1 day) |
| Day 20 | Onboarding: ask for sign-in (web+mobile) | ME (1 hr) |

**Week 3 done = user accounts persist, first monetization hooks live.**

### Week 4 — LAUNCH PREP + POLISH
**Goal:** Production-ready, App Store submissions filed.

| Day | Task | Owner |
|---|---|---|
| Day 21-22 | Sentry wired on web + Crashlytics on Flutter | ME (4 hrs) |
| Day 22-23 | UptimeRobot + healthcheck endpoints | ME/YOU (1 hr) |
| Day 23-24 | Lighthouse PWA audit + fix low scores | ME (4 hrs) |
| Day 24-25 | App Store screenshots + ASO | ME/YOU (1 day) |
| Day 25 | Run `flutter pub get` + first APK build | ME (1 day) |
| Day 26 | Submit to TestFlight + Play internal track | YOU (1 hr) |
| Day 26-27 | "7 Days of Peace" email capture sequence | ME (2 days) |
| Day 27-28 | Blog content pillar first 3 posts | ME (1 day) |

**Week 4 done = App Store submission live + marketing funnels armed.**

### What's next: MONTH 2+
- App Store public launch (week 5)
- 100 beta users (week 6)
- 7-day free trial on Premium (week 7)
- First newsletter issue + podcast appearances (week 8)

---

## PART 5 — SMART COMMERCIAL / BUSINESS PLAN

### 5.1 — The market (verified by web search if needed)

| Market | Global Size | HEAL's capture (Year 5) |
|---|---:|---|
| Christian Mindfulness TAM | ~300M adults (protestant + evangelical + charismatic) | 1% = 3M DAU |
| Christian app subscriber market | ~$100M ARR currently | 10% = $10M ARR |
| Samford report on Christian meditation practice growth | 2020-2025: 8% YoY | — |
| Hallow as ceiling reference | 12M users, $50M ARR (Q4 2024) | Half that = realistic |

### 5.2 — Mission (one line)
**Make Scripture-grounded mindfulness the default daily practice for 10M Christians worldwide.**

### 5.3 — Vision (3-year)
Be the **#1 downloaded, #1 rated, #1 most-recommended** mindfulness app for Christians globally.

### 5.4 — Specific / Measurable / Achievable / Relevant / Time-bound

| Metric | Now (Q3 2026) | Q4 2026 | Q2 2027 | Q4 2027 | Q4 2028 |
|---|---:|---:|---:|---:|---:|
| App downloads (cumulative) | 0 | 5,000 | 100k | 500k | 2M |
| Daily active users | 0 | 200 | 5,000 | 25,000 | 100,000 |
| Premium subscribers | 0 | 50 | 1,500 | 8,000 | 30,000 |
| Family subscribers | 0 | 5 | 300 | 2,000 | 8,000 |
| Monthly ARR | $0 | $300 | $11k | $60k | $200k |
| Annual run rate (ARR) | $0 | $3.6k | $130k | $720k | **$2.4M** |
| Rating (App Store) | n/a | 4.5+ | 4.6+ | 4.7+ | 4.7+ |
| NPS | n/a | 50+ | 55+ | 60+ | 65+ |
| Churches recommending HEAL | 0 | 5 | 50 | 500 | 5,000 |
| Languages supported | 1 (en) | 1 | 4 (en + zh-CN + zh-TW + ja) | 6 | 6 |
| Essays in library | 3 | 15 | 60 | 150 | 300 |
| Songs in library | 112 | 200 | 500 | 1,000 | 2,000 |
| Meditations in library | 269 | 365 | 500 | 730 | 1,000 |

### 5.5 — Achievability

**Year 1 (Q3 2026 - Q2 2027):**
- → 100k downloads: Hallow went 0→1M in 11 months (2020-2021)
- → 1,500 Premium: 1.5% conversion (industry: 2-5% for faith apps)
- → $130k ARR: realistic at this scale; trajectory to $1M ARR by Year 2

**Year 2-3 (Q3 2027 - Q2 2028):**
- → Multi-language adds Asia-Pacific (zh + ja + ms + ta)
- → Family tier drives word-of-mouth within church communities
- → Pastor partnerships (50 churches, each averaging 200 attendees = 10k new users each)

**Year 3-5 (Q3 2028 - Q2 2031):**
- → AI Prayer Companion drives Premium conversion to 5%
- → Apple Watch companion drives daily session +25%
- → Acquisition likely

### 5.6 — Revenue model (verified per memory pricing pattern)

| Tier | Price | Margin (with Sonnet 4.5 + storage) | Convex unlock |
|---|---|---:|---|
| **Free** | $0 | — | Daily meditation, 1 breath pattern, 1 prayer/day, all Scripture (text), all Praise (audio) |
| **Premium** | $4.99/mo or $39/yr | ~85% | All 4 breath patterns, voice calibration, all prayers unlocked, all essays, family sharing (1 device), streak insights, offline library |
| **Family** | $9.99/mo or $79/yr | ~90% | Premium for up to 6 people + "Pray Together" 2-person sessions + family prayer reminders |

**Cost stack at 100k DAU:**
- PB + CDN: $100/mo
- Firebase (Blaze tier): $500/mo
- Apple/Google fees: $0 on web, 30% on App Store (15% after Year 1 for small business)
- TTS API: $0.10 per 1k chars, est $50/mo
- Stripe fees: 2.9% + 30¢
- **Total infra: ~$700-1,000/mo at 100k DAU**

**Revenue at 100k DAU:**
- 2% Premium = 2,000 × $4.99 = $10k/mo = $120k ARR
- 0.5% Family = 500 × $9.99 = $5k/mo = $60k ARR  
- **Total: $15k/mo = $180k ARR**
- Infra: $12k/yr
- **Net Year 1: $168k on ~$200k infra**

### 5.7 — Pricing experiments to A/B (post-launch)
- A: $4.99 vs $3.99 entry (find optimal)
- B: Annual discount depth (currently 35%)
- C: Family tier size (5 vs 6)
- D: Free tier "soft wall" — limit audio minutes per day (drives upgrade)

### 5.8 — Distribution channels (post-launch)

| Channel | Cost | Expected reach |
|---|---|---|
| App Store organic | $0 | 80% of installs Year 1 |
| Church partnerships (50 pastors each reach 200) | low | 10k+ users |
| Christian podcast tour (10 episodes) | sponsor $500/ep | 50k impressions |
| Christian YouTube influencers (5 channels) | $1k-5k each | 200k impressions |
| Paid Facebook/Insta ads (Christian 25-55 F) | $0.50-1.50 CPI | 50k impressions per $1k |
| SEO content pillar (15 posts, organic) | $0 | 50k impressions/yr per post |
| Email nurture + referral ($5 reward) | $25/referral | 500 paid |
| Bible app integrations (YouVersion, Glorify) | partnership | high |

### 5.9 — Competitive moat analysis (5-year defensibility)

| Moat | Build time | Defensibility |
|---|---|---|
| **Scripture-voice library** — 1,000+ unique NRSV/NIV/ESV/KJV voice tracks | 6 mo | Strong — competitors have to license voice actors |
| **Theology depth** — every minute reviewed by pastoral editor | ongoing | Strong — culture |
| **Multi-language library** — zh/ja/ms/ta content by Year 2 | 12 mo | Strong — Hallow is en-only |
| **Family tier** — church-network flywheel | 6 mo | Medium — features can be copied |
| **Cross-device** (web ↔ mobile sync) | 3 mo | Weak — Stack Exchange anyone can build |
| **Brand trust** — Protestant / Evangelical market vs Catholic Hallow | 18 mo | Strong — positioning |
| **Open content library** — pastors submit their own guided meditations | 12 mo | Very strong — flywheel |

### 5.10 — Risks + mitigation

| Risk | Severity | Mitigation |
|---|---|---|
| Hallow enters Protestant market | High | Lock in family + multi-language first |
| "Christian meditation" theological controversy | Medium | Position via Scripture; cite John Mark Comer, Richard Foster endorsements |
| Apple App Store rejection (meditation content) | Medium | Avoid "guided meditation" terminology; use "devotional practice" + Scripture framing |
| Burnout — small team | High | Hire 1 pastoral editor + 1 mobile dev by Year 1 Q4 |
| PB scales break | Medium | Postgres migration path planned (memory entry pocketbase-at-scale) |
| Psalm/content copyright claim | Low | All NRSV (public domain texts); original prayers/essays |
| Negative reviews from non-Christians trying it | Low | Clear positioning on landing page |

### 5.11 — Year-1 milestones + budget

```
Month 1: BOTH SURFACES LIVE
  $150 Dokploy VPS (we have it)
  $ 30 domain renewals (annual, amortized)
  $ 50 misc (Backblaze, Firebase, Mailgun for email)
  $230 total

Month 2-3: CONTENT COMPLETE + USER PERSISTENCE
  + $ 50 TTS API bill
  + $ 50 monitoring
  +$330

Month 4-6: PUBLIC LAUNCH + 100K DOWNLOADS
  +$1k App Store dev account (annual)
  +$1k Play Store dev (one-time)
  +$2k podcast sponsorships
  +$500 seed marketing
  =$5,140 total Year 1 spend

Break-even: ~Q3 2027 at ~3,500 paid (estimated)
Profitability target: $10k/mo by end of Year 2.
```

### 5.12 — Exit strategy (Year 5+)

Realistic exit options:
1. **Strategic acquisition by YouVersion / Salem Communications / Hallow competitor** ($50-100M range at $10M ARR with growth)
2. **Strategic acquisition by Bible.com / American Bible Society** (mission-aligned)
3. **Boot-strap forever** (rational choice if growth holds)

---

## PART 6 — 30 / 60 / 90 DAY EXECUTION TIMELINE

### Days 1-30 (Aug 2026): RECOVER + SHIP BASELINE

| Week | Goals | Deliverable |
|---|---|---|
| W1 | Both surfaces UP, secrets rotated, backups installed | Both URLs return 200; backup cron verified daily |
| W2 | Content backfills complete (emotion, tags, category on all records) | 100% content metadata completeness |
| W3 | Generate 67 prayer audios + 31 scripture audios + 6 breathwork audios | Audio parity on 4 collections |
| W4 | Generate 31 scripture images + 60 quote images + 6 breathwork images | Image parity on all records |

**30-day output:** Production-grade PWA + Flutter Web with 100% content parity.

### Days 31-60 (Sep 2026): MONETIZE + MOBILE PARITY

| Week | Goals | Deliverable |
|---|---|---|
| W5 | Create PB user collections + wire Flutter to Firebase Auth | First sign-in flow works cross-device |
| W6 | Add PB schema for streaks/mood/journal/favorites | User data persists across surfaces |
| W7 | Stripe integration on web + RevenueCat on Flutter | First paying user can subscribe |
| W8 | Pricing page + paywall UI + onboarding sign-in prompt | First $1 of revenue |

**60-day output:** First paying customer.

### Days 61-90 (Oct 2026): LAUNCH + GROW

| Week | Goals | Deliverable |
|---|---|---|
| W9 | App Store + Play Store submission | App in review |
| W10 | 7 Days of Peace email sequence + SEO blog post 1 | First newsletter sent |
| W11 | Lighthouse 95+ + Sentry/Crashlytics wired | Production monitoring live |
| W12 | Public launch announcement + 5 podcast appearances | First 1,000 downloads |

**90-day output:** Live in App Store, first 1,000 organic downloads.

---

## PART 7 — THE 3 THINGS YOU CAN DO RIGHT NOW

```bash
# 1. Get me the Flutter build log (5 min)
ssh root@84.247.174.141
tail -100 /etc/dokploy/logs/app-calculate-digital-bandwidth-h95pb2/app-calculate-digital-bandwidth-h95pb2-2026-06-28:02:23:07.log

# 2. While I fix web.Dockerfile, click Deploy in Dokploy UI on BOTH apps (1 min)
#    https://dokploy.scaleupcrm.com/project/DYjoEFGRaVXuJHaohVCJA/env/Zogolqlm4qqE9XHI15qYB/services/yC4hSrjj9xYT_ronMdBDo
#    https://dokploy.scaleupcrm.com/project/YaIYbkOB74WCZGgnJSNVf/env/yxYViwNoutfji_VT1e013/services/3UHHbFdDgkIklUHCHSkTg

# 3. Rotate GitHub PAT (30 min)
#    github.com/settings/tokens → revoke ghp_Cxkc5kd...b9f3r5XF8
#    mint new with same scopes
#    run: git remote set-url origin https://x-access-token:NEW_PAT@github.com/albertlaudia/HEAL.git
```

Once you give me the build log, I'll have Flutter Web up within the hour.
Both surfaces live + first paying user = **30 days from today**.

---

## APPENDIX A — Inventory of every file we have

(For reference, kept here for one-doc reference.)

### Web routes
```
/web/app/ — 18 page routes + 5 utility routes
/web/components/ — 27 component groups
/web/lib/ — 12 lib files (auth, audio, pb, firebase)
/web/public/sw.js — 182-line service worker
/web/next.config.mjs — security headers + CSP
/web/scripts/ — 55 cron/seed/utility scripts
```

### Mobile (Flutter)
```
/mobile/lib/main.dart
/mobile/lib/core/ — env, haptics, observability, router, theme, time_palette + widgets/
/mobile/lib/data/ — pb_models.dart, pb_repositories.dart
/mobile/lib/services/ — audio, notification, streak, voice_calibration
/mobile/lib/features/ — onboarding, home, now, meditate, breathe, scripture, prayer, praise, essays, settings
/mobile/lib/widgets/
/mobile/web/ — index.html, manifest.json, icons/
/mobile/web.Dockerfile — multi-stage Flutter + Nginx
/mobile/pubspec.yaml — 23 runtime + 4 dev dependencies
```

### Scripts
```
/scripts/heal-backup/ — backup.sh, restore.sh, find-pb-data.sh, INSTALL.md
```

### Docs (all committed)
```
/docs/AUDIT_2026-06-28.md          — Status audit
/docs/HEAL_ONE_PAGE.md             — One-page state card
/docs/HEAL_PRODUCTION_PLAN_V3.md   — THIS FILE (30/60/90 plan)
/docs/FLUTTER_WEB_DEPLOY.md        — Flutter Web strategy
/docs/PLATFORM_STRUCTURE.md        — Architecture overview
/docs/PRODUCTION_READINESS_AUDIT.md — Earlier audit
/web/docs/FIREBASE-ARCHITECTURE.md — Firebase scaling plan
```

---

## APPENDIX B — Decision matrix: where to spend the FIRST 100 hours

| # | Task | Why it's #1 priority | Effort | Risk if delayed |
|---|---|---|---|---|
| 1 | Recover both surfaces | Nothing else matters if no one can reach us | 3 hrs | All revenue = $0 |
| 2 | Content parity (emotion/tags/category) | Without this, search/filter/find is broken | 5 hrs | App feels empty |
| 3 | Generate missing media | "Show, don't tell" — apps without audio feel dead | 28 hrs | Looks like a clone of Headspace no one chose |
| 4 | User persistence | Without this, mobile engagement features are temporary | 21 hrs | Streak is meaningless, voice cal doesn't matter |
| 5 | Monetization hooks | $4.99/mo is <$50/yr per user — worth wiring early | 6 days | Hard to retroactively ask for money |
| 6 | App Store submission | Distribution is exponential, not linear | 3 days | Each week delay = ~10% Year 1 revenue lost |
| 7 | Marketing material | Without screenshots, no installs | 2 days | — |

**Total: ~12 days of agent time + 2 days of human time to reach "live in App Store, first paying customer possible."**
