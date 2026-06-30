# HEAL — Platform Structure

**Repo:** https://github.com/albertlaudia/HEAL (private)
**Live:** 🔴 https://heal.positiveness.club (down — see Production audit)
**PB:** 🟢 https://pocketbase.scaleupcrm.com
**Latest commit:** `d6aa772`

---

## TL;DR

HEAL is **one product** with **three surfaces** (web live, mobile code-complete, watch future).
The backend is the classic 3-tier split:
- **PocketBase** for static content
- **Firestore** for per-user state
- **Drift / local** for offline-first

Hosted on a single VPS via Dokploy, with media on Cloudflare-fronted IIS/FTP. GitHub `albertlaudia/HEAL`. Auto-deploys on push. Cron-driven content. Backup-ready code in repo.

---

## 1. The Three Apps

```
┌─────────────────────────────────────────────────────────┐
│                  HEAL (single product)                  │
│         "a quiet Christian mindfulness practice"        │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼─────┐    ┌──────▼──────┐    ┌──────▼──────┐
   │   WEB   │    │   MOBILE    │    │  (future)   │
   │ Next.js │    │   Flutter   │    │  Watch OS   │
   │   15    │    │     3.24+   │    │  / Alexa    │
   └─────────┘    └─────────────┘    └─────────────┘
```

One product, three surfaces, one content source. All three read the same PocketBase collections.

## 2. The 3-Layer Backend

```
┌──────────────────────────────────────────────────────────────┐
│  STATIC CONTENT (PocketBase)                                  │
│  HEAL_meditations (269) · HEAL_praise (112) · HEAL_prayers (67)│
│  HEAL_scriptures (31) · HEAL_quotes (60) · HEAL_essays (3)    │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  USER STATE (Firestore / Firebase)                            │
│  /users/{uid}, /users/{uid}/favorites, ...                    │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  LOCAL STORAGE (Drift / SQLite / SharedPreferences)          │
│  Cached PB content, voice calibration, streak state          │
└──────────────────────────────────────────────────────────────┘
```

## 3. The Hosting Stack

```
                    ┌──────────────────────┐
                    │  Cloudflare (free)   │
                    │  CDN + DNS + DDoS    │
                    └──────────┬───────────┘
                               │
        ┌──────────────────────┼──────────────────────────┐
        │                      │                          │
   ┌────▼──────────┐    ┌──────▼──────────┐    ┌──────────▼──────────┐
   │  APP domain   │    │   MEDIA CDN     │    │  FIREBASE            │
   │  (Dokploy)    │    │   (SmarterASP)  │    │  (Google)            │
   │  Next.js      │    │   IIS + FTP     │    │  Auth + Firestore    │
   │  via Docker   │    │   Cloudflare-   │    │                      │
   │               │    │   proxied       │    │  heal-prd            │
   │  heal.positi- │    │  resources.     │    │                      │
   │  veness.club  │    │  positiveness.  │    │                      │
   │               │    │  club/heal/...  │    │                      │
   │  VPS:         │    │                 │    │                      │
   │  84.247.174.  │    │  FTP:           │    │                      │
   │  141          │    │  win8108.site   │    │                      │
   └───────────────┘    └─────────────────┘    └──────────────────────┘
            │
            │  container on the same VPS
            ▼
   ┌──────────────────────────┐
   │   PocketBase v0.39       │
   │   (shared instance)      │
   │                          │
   │   pocketbase.scaleupcrm  │
   │   .com                   │
   │                          │
   │   Other tenants:         │
   │   - 1perc_*              │
   │   - prop_*               │
   │   - riseup_*             │
   │   - fin_terminal_*       │
   │   - HEAL_*               │
   └──────────────────────────┘
```

## 4. The Code Repo Structure

```
/workspace/HEAL/                  ← repo: albertlaudia/HEAL (private)
├── docs/                          ← architecture + audit + runbooks
│
├── web/                           ← Next.js 15 web app (LIVE)
│   ├── app/                       ← 17 routes, App Router
│   ├── components/                ← 30+ React components
│   ├── lib/                       ← core utilities (pb, firebase, auth, ...)
│   ├── content/                   ← pre-rendered static content
│   ├── public/                    ← assets
│   ├── scripts/                   ← 12+ PB / media / cron scripts
│   ├── Dockerfile                 ← used by Dokploy (buildPath: /web)
│   └── package.json
│
├── mobile/                        ← Flutter 3.24+ app (CODE COMPLETE, NOT BUILT)
│   ├── lib/
│   │   ├── core/                  ← theme, router, env, haptics, palette
│   │   ├── data/                  ← PB models + repos
│   │   ├── services/              ← audio, notifications, streak, voice calibration
│   │   └── features/              ← 9 feature folders (home, now, breathe, ...)
│   ├── android/                   ← Android Gradle (com.pclub.heal)
│   ├── ios/                       ← iOS Xcode project
│   └── pubspec.yaml
│
├── scripts/
│   └── heal-backup/               ← PB auto-backup to B2 (cron + restore)
│
└── .github/
    ├── workflows/
    │   ├── trigger-dokploy.yml    ← push → Dokploy redeploy
    │   └── mobile-build.yml       ← Android APK CI
    └── dependabot.yml
```

## 5. The Content Pipeline

```
HOURLY CRON (06:15-11:15 Asia/Shanghai, 6 runs/day)
  │
  ├─ Pick 2 content types from rotation [scriptures, quotes, prayers, praise]
  │
  ├─ For each type:
  │    ├─ Deterministic seed from (year × 1000 + day × 13 + type_idx × 7)
  │    ├─ LCG cycle advances through 100-entry seed bank
  │    ├─ Skip-on-duplicate (slug uniqueness check vs PB)
  │    ├─ Backfill emotion + tags[] automatically
  │    └─ PB create (cycle_position + cycle_year stamped)
  │
  └─ Output: ~12 records/day = ~4,380 records/year

DAILY TRENDING PRAYER (1/day)
  │
  ├─ Fetch top 3 viral/trending topics (curated RSS + news API)
  ├─ For each: generate prayer with emotion tag
  └─ PB create with source_event + event_date fields
```

## 6. The Security Model

```
                    PUBLIC (anyone can read)
                    ─────────────────────
                    PB: HEAL_meditations, HEAL_praise, HEAL_prayers, ...
                    CDN: resources.positiveness.club/heal/images/...
                    Web: /, /about, /now, /meditate, /praise, ...

                    AUTHENTICATED (signed-in users)
                    ──────────────────────────
                    Firebase Auth (Google + anonymous)
                    Firestore:
                      - own /users/{uid} (read+write)
                      - own /users/{uid}/favorites
                      - own /users/{uid}/journal
                      - own /users/{uid}/history
                      - own /users/{uid}/preferences

                    SERVER-ONLY
                    ───────────
                    PB superuser (the user, via Dokploy UI)
                    Backup scripts (B2 keys, only on Dokploy VPS)
                    Cron jobs (PB write via service account)

                    NEVER CLIENT-SIDE
                    ──────────────────
                    ❌ PB_PASSWORD / PB_IDENTITY (only in Dokploy env)
                    ❌ B2 keys (only in /etc/heal-backup.env)
                    ❌ Firebase Admin SDK keys (server-only)
                    ❌ Dokploy API key (server + sandbox shell only)
```

## 7. The Build / Deploy Pipeline

```
DEVELOPER PUSHES TO main
  │
  ├─ GitHub Action (mobile-build.yml) — Android APK
  │    ├─ Self-hosted runner (large box)
  │    ├─ Flutter 3.27.1 install
  │    ├─ flutter pub get + build_runner + gen-l10n
  │    ├─ flutter build apk --release
  │    ├─ Sign with release keystore
  │    └─ Upload to Play Console (internal track)
  │
  └─ GitHub Action (trigger-dokploy.yml) — Web deploy
       ├─ curl POST /api/trpc/application.redeploy
       ├─ Dokploy pulls from main
       ├─ Docker build (Dockerfile, buildPath: /web)
       ├─ Container spawn on Dokploy VPS
       └─ heal.positiveness.club serves new build
```

## 8. PocketBase Schema (live)

```
HEAL_meditations      269 records    id, slug, title, subtitle, body,
                                      audio_url, illustration_url, theme,
                                      category, voice_name, duration_seconds,
                                      tags, best_for, sort_order,
                                      emotion, cycle_position, cycle_year,
                                      is_published, day_of_year

HEAL_praise           112 records    id, slug, title, subtitle, lyrics,
                                      audio_url, illustration_url, category,
                                      emotion, mood, bpm, tags, best_for,
                                      cycle_position, cycle_year, is_published

HEAL_prayers           67 records    id, slug, title, body, category,
                                      emotion, tags, attribution,
                                      illustration_url, is_published,
                                      is_event_prayer, source_event,
                                      event_date, cycle_position, cycle_year

HEAL_scriptures        31 records    id, slug, reference, text, translation,
                                      theme, reflection_prompt, emotion,
                                      tags, is_published, day_of_year,
                                      cycle_position, cycle_year

HEAL_quotes            60 records    id, slug, text, attribution, source,
                                      category, emotion, tags, illustration_url,
                                      is_published, is_motivation,
                                      day_of_year, cycle_position, cycle_year

HEAL_breathwork         6 records    id, slug, name, description,
                                      inhale_seconds, hold_in_seconds,
                                      exhale_seconds, hold_out_seconds,
                                      best_for, illustration_url, tags

HEAL_essays             3 records    id, slug, title, subtitle, body,
                                      illustration_url, category, tags,
                                      read_minutes, is_published

UNIQUE INDEXES (defense against cron duplicates):
  idx_HEAL_prayers_slug      UNIQUE on slug
  idx_HEAL_scriptures_slug   UNIQUE on slug
  idx_HEAL_quotes_slug       UNIQUE on slug

PERFORMANCE INDEXES:
  idx_HEAL_prayers_emo       on emotion        ← enables emotion search
  idx_HEAL_prayers_event     on is_event_prayer
  idx_HEAL_prayers_pos       on cycle_position
  + similar for scriptures, quotes
```

## 9. The Mobile App Feature Inventory (built, unbuilt)

```
✅ DONE                                    🔲 NOT DONE (gap)
─────────────────────────────────────────   ──────────────────────────────────
• Material 3 dark + brass/rosewood          • flutter pub get (NEVER RUN)
• Cormorant Garamond + Inter fonts          • First APK build
• 6-period adaptive palette                 • Real Firebase config
• 7 feature pages (Home/Now/Pray/...)        • Drift codegen (placeholder)
• Bottom-nav + persistent mini-player       • Tests (zero)
• Custom transitions (fade/sh. axis/slide)  • Watch OS companion
• Breath ring with AnimationController
• Haptics on phase change (light/click)
• In-pocket mode (dimmer + breath count)
• Voice calibration (mic-based pace)
• Streak with 4-day grace + welcome-back
• Daily reminders (flutter_local_notifications)
• Audio service (audioplayers + skip ±10s)
• Sit-with-verse mode (candle flame, re-types)
• Onboarding 3-page flow + permission gate
• Settings page (notifs, voice, haptics)
• App icon (brass H) + adaptive icon
• Bundle ID com.pclub.heal (iOS + Android)
```

---

**Repo URL:** https://github.com/albertlaudia/HEAL
**Live URL:** 🔴 https://heal.positiveness.club (down — needs restart)
**PB:** 🟢 https://pocketbase.scaleupcrm.com
**Latest commit:** `d6aa772`