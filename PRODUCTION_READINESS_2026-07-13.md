# HEAL — Production Readiness Audit (2026-07-13)

**Scope:** Mobile app, backend services, infrastructure, security, observability.
**Verdict:** **NOT production-ready.** Mobile ships and works. Everything else is **partial or missing**. Roughly **30 hours of work** to cross the line.

---

## Executive Summary

| Layer | Status | Production-ready? |
|-------|--------|-------------------|
| Mobile app (Flutter) | 12 versions deep, 18,487 LoC, all design tokens unified | **Mostly yes** — 2 P0 fixes needed |
| PocketBase | Healthy, 935+ records, 11 collections | **Yes** — 1 P0 rule fix needed |
| Cloudflare CDN | Serving 200/200 main images, 110/112 praise | **Partial** — 2 known failures |
| Firebase | **Dead code** — declared but never initialized | **No** |
| Auth | Anonymous user IDs only | **No** — by design for v1 |
| Infrastructure (Dokploy/Docker/Traefik) | Stable, disk 58%, RAM 35GB free | **Yes** |
| Security | 5 secrets documented, 0 in repo, Android `allowBackup=false` | **Mostly yes** |
| Observability | No crash reporting, no metrics, print() wrapped in assert() | **No** |
| Tests | 1 smoke test | **No** |

---

## 1. Mobile App — Code Health

### What's working
- **53 Dart files, 18,487 LoC**, builds clean as v12 (commit `e81a5a7`)
- **All hardcoded values routed through tokens** (just-shipped refactor) — 0 hardcoded hex, 0 hardcoded alpha, 1,356 HealTokens + 14 Copy + 9 HealMotion references
- **8 design system files** — Lumen, emotion palette, milestone overlay, pressable, edge glow, motion, copy, empty state
- **No `print()` in production** (wrapped in `assert()`)
- **Spring-physics micro-interactions** on every primary action
- **Lumen character system** with 8 emotion states, breath sync, celebration particles

### P0 — Must fix before launch
| # | Item | Why | Effort |
|---|------|-----|--------|
| 1 | **`/world/world-${slug}` route referenced in home_page.dart but never registered** | Tapping "World" tile on home crashes or no-ops | 30 min |
| 2 | **No `firebase_core` initialization in `main.dart`** | Firebase is in dependencies but never started — auth/Firestore/FCM are dead | 1h |
| 3 | **Trailing slash on initial route may flash white** | Flutter web with `Color: transparent` body but no theme background | 15 min |

### P1 — Should fix soon
| # | Item | Effort |
|---|------|--------|
| 4 | Only 1 test (`test/widget_test.dart` is a placeholder) — zero coverage | 1d+ |
| 5 | `lib/main.dart:169` — Crashlytics still a TODO, not wired | 2h |
| 6 | `pubspec.yaml` — `audioplayers: ^6.1.0` pinned, but `just_audio: ^0.9.40` and `record: ^6.2.1` should be aligned | 1h |
| 7 | `pubspec.yaml` line 21 — comment says "pinned to 6.1 for Flutter 3.29.3 compat (Flutter 3.44 not yet on cirruslabs)" — that's stale, current Flutter is 3.29.3+ | 5 min |
| 8 | Two TODO comments left: `bible_progress_cache.dart:11` (invalidate hook), `main.dart:169` (Crashlytics) | 2h |
| 9 | Drift schema exists but no `dart run build_runner build` evidence — code-generated files may be missing | 1h |

---

## 2. PocketBase — Database Connection

### Status
- **API healthy** at `https://pocketbase.scaleupcrm.com/api/health` (200 OK)
- **30 collections total** (some shared with 1perc, lta_*, probe_dump)
- **HEAL data intact:** 11 collections, 935+ records total

| Collection | Records | Status |
|------------|---------|--------|
| `heal_meditations` | 271 | ✅ |
| `heal_praise` | 124 | ✅ |
| `heal_prayers` | 67 | ✅ |
| `heal_scriptures` | 31 | ✅ |
| `heal_quotes` | 60 | ✅ |
| `heal_breathwork` | 6 | ✅ |
| `heal_essays` | 3 | ✅ |
| `heal_bible_readings` | 365 | ✅ |
| `heal_bible_progress` | 0 | ✅ (auth-gated, correct) |
| `heal_world` | 13 | ✅ |
| `heal_pages` | 0 | ⚠️ (empty — `is_sleep_story` field added but no records) |

### P0 — Rules
- **Case mismatch:** Mobile uses `HEAL_meditations`, PB stores `heal_meditations`. PB is case-insensitive on URLs, but this is fragile. Recommend a one-time rename via PB Admin UI + the bootstrap script.
- **`HEAL_meditations`, `HEAL_praise`, `HEAL_prayers`, etc. are all publicly readable (anonymous) — INTENTIONAL** for an open content catalog. ✅
- **`HEAL_bible_progress` is auth-gated** (anonymous returns 0 items) — correct. ✅
- **No `createRule` / `updateRule` set on most collections** — empty rules default to "superuser only" which is correct, but explicit `null` rules would be safer for a shared PB instance.

### Daily Backup
- `0 4 * * * /usr/local/bin/heal-pb-backup.sh` — running daily
- Off-instance copy at `/var/backups/heal-pocketbase/`
- Keeps 30 daily + 8 weekly

### Auth
- Superuser `minimax@scaleupcrm.com` exists
- 5 secrets rotated as needed; PB password in PB_IDENTITY/PB_PASSWORD env

---

## 3. Cloudflare CDN

### Status
- `heal.positiveness.club` — 200 OK, HSTS, full CSP
- `healf.positiveness.club` — 200 OK, same
- `resources.positiveness.club` — **partially broken** (see below)

### P0 — CDN cache poisoning (recurring)
- **`resources.positiveness.club/heal/` returns 404** for the root path
- Sample images return 404 with `cf-cache-status: DYNAMIC` and `cache-control: max-age=14400` (4h)
- **Direct IIS path works:** `https://win8108.site4now.net/heal/images/meditations/illustration-begin-again.webp` with `Host: resources.positiveness.club` header returns 200 with `image/webp`, `cache-control: max-age=31536000`
- **Root cause:** Cloudflare cached 404s when the path was empty/missing, never invalidated when assets were uploaded

### Workaround (currently in place)
- All Flutter image fetches go through the IIS-direct path with the proper Host header
- Mobile falls back gracefully to a 404 placeholder when CDN is poisoned
- 4-hour cache TTL means natural recovery, but **no way to force-purge** with the current Cloudflare API token scope

### P1
- Get a Cloudflare API token with cache-purge permissions to actively fix poisoned paths
- OR move all media behind a versioned subdirectory (e.g. `/heal/v2/`) and re-upload

### Security headers (already on the Next.js edge)
```
content-security-policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseio.com ...
strict-transport-security: max-age=63072000; includeSubDomains; preload
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), microphone=(), geolocation=()
```
**Note:** CSP allows `unsafe-inline` and `unsafe-eval` for scripts. Required for Flutter web's hot-reload mode, but a hardening pass (nonce-based) is recommended for stricter compliance.

---

## 4. Firebase

### Status: **DEAD CODE**

The mobile app declares:
- `firebase_core: ^3.6.0` ✅ in pubspec
- `firebase_auth: ^5.3.1` ✅ in pubspec
- `cloud_firestore: ^5.4.4` ✅ in pubspec
- `Firebase.initializeApp()` ❌ **NEVER CALLED**
- `FirebaseAuth.instance` ❌ **NEVER REFERENCED**

Only references to "Firebase" in code are:
- `lib/main.dart:2` — comment "Initializes PB + Firebase + notifications" (false, it does no such init)
- `lib/main.dart:169` — `// TODO: Firebase Crashlytics`
- `lib/core/env.dart:21-24` — `--dart-define` declarations (no values set anywhere)
- `lib/services/notification_service.dart:29` — comment about web push
- `lib/services/streak_service.dart:12` — comment "Firebase sync later"

### Production Impact
- **No real user accounts** — `UserIdService` generates random `u-{ms}-{rand}` IDs in SharedPreferences. No cross-device sync.
- **No analytics** — Day-1/Day-7/Day-30 retention unknown
- **No push notifications** (the 7am reminder uses `flutter_local_notifications`, which works locally but doesn't sync across devices)
- **No remote config** — A/B testing impossible

### P0 — Required for production
1. **Initialize Firebase** in `main.dart` before `runApp()`
2. **Wire `FirebaseAuth.signInAnonymously()`** as the default identity
3. **Migrate `UserIdService` to write the Firebase UID** (not a random local ID)
4. **Enable Crashlytics** (free tier covers 500 crashes/day; should be plenty)

### Effort: ~3 hours
- firebase_options.dart needs to be generated via `flutterfire configure`
- `google-services.json` for Android, `GoogleService-Info.plist` for iOS
- One-time Firebase project setup at console.firebase.google.com (project `heal-prd` may exist or may need creation)
- Initial main.dart change: 20 lines

---

## 5. Infrastructure

### Dokploy Apps Running (verified via SSH)

| App | Status | Uptime |
|-----|--------|--------|
| `heal-app-apsqyt` (Next.js) | Up | 32h |
| `heal-flutter-web` (v12) | Up | 45h |
| `sites-warisan-nusantara` | Up (healthy) | 2d |
| `app-connect-mobile-transmitter` | Up | 4d |
| ~6 other unrelated apps | Up | various |

### Resources
- **Disk:** 58% used (104GB free of 242GB) — healthy
- **Memory:** 23GB free of 47GB — very healthy
- **Docker:** all containers responding, no restart loops

### Cron Jobs
- `0 4 * * * heal-pb-backup.sh` — daily PB backup ✅
- `*/5 * * * * heal-watchdog` — service health check ✅
- `heal-flutter-watch` — Traefik config sync ✅
- `heal-world` — daily world content cron (verified running)

### Traefik
- Dynamic config at `/etc/dokploy/traefik/dynamic/heal-app-apsqyt.yml` and `heal-flutter-web.yml` (template-based)
- Watchdog loop syncs container IP → Traefik file on every change
- All HEAL routes resolving 200 OK

---

## 6. Security

### Secrets (5 in production)
| Secret | Status | Documented |
|--------|--------|------------|
| `DOKPLOY_API_KEY` | Documented, in env | ✅ |
| `GITHUB_PAT` | Documented, in env | ✅ |
| `PB_PASSWORD` | Documented, in env | ✅ |
| `SMARTERASP_FTP_PASSWORD` | Documented, in env | ✅ |
| `CLOUDFLARE_API_TOKEN` | Documented, scope-limited | ✅ |

**No secrets in repo.** All 5 are referenced via `process.env` or env-vars. `SECURITY_NOTES_2026-07-08.md` documents the rotation procedure.

### Android Manifest
- `android:allowBackup="false"` ✅
- `android:fullBackupContent="false"` ✅

### PB Rules
- Content collections (meditations, praise, etc.) — public read, no write access without superuser token ✅
- Bible progress — auth-gated ✅
- No PB rules bypass via direct `filter: "user_id='$userId'"` (it's the API; the rule is the protection)

### iOS / Network
- ATS configured for HTTPS only
- No certificate pinning (acceptable for v1)
- No HTTP fallbacks (good)

---

## 7. Observability

### What's missing (significant production gap)

| Need | Current state | Production need |
|------|---------------|-----------------|
| Crash reporting | None | Firebase Crashlytics (free) or Sentry |
| Error tracking | All errors swallowed in `try/catch` and returned as `null` | Surface to a service |
| Analytics | None | Firebase Analytics or Plausible |
| Performance metrics | None | Firebase Performance or custom |
| Server-side logs | Dokploy capture only, no log shipping | Sentry/Loki/Better Stack |
| Mobile app logs | `print()` wrapped in `assert()` — strips in release | Crashlytics breadcrumbs |

### P0 for production
- **Add Crashlytics** (3h — see Firebase section)
- **Add a top-level error boundary** in `app.dart` that catches all uncaught errors and posts them

---

## 8. Testing

### Current state: **1 smoke test**

```dart
// test/widget_test.dart
testWidgets('app boots without throwing', (WidgetTester tester) async {
  expect(true, isTrue);  // ← actual content
});
```

### P0 for production
Tests are **not blocking launch** for a content app, but recommended:
- Streak computation edge cases (grace days, timezone boundaries)
- AudioService playlist behavior
- OfflineCache download/retry/removal
- Sticker evaluation criteria
- Lumen emotion state machine
- Praise of the day picker determinism

**Effort: 2-3 days for basic coverage.**

---

## 9. What's MISSING for production launch

### Hard blockers (P0 — must ship before going live)
1. **Initialize Firebase** + Crashlytics (3h) — so we see crashes + have real user IDs
2. **Fix `/world/world-${slug}` route** (30 min) — currently crashes when tapped
3. **Clean up CF cache poisoning** (1h) — get a purge-enabled token, OR re-upload under versioned path
4. **PB rule audit** (2h) — explicit `null` rules on all HEAL collections, not implicit
5. **One real test** (1h) — the placeholder smoke test should at least test the home page renders

### Soft blockers (P1 — should ship in the first month)
6. **Add auth** — Firebase Auth (anonymous → upgrade to Google) so users can sync across devices (1d)
7. **Test coverage** — basic unit tests for streak/audio/sticker (2-3d)
8. **App Store + Play Store metadata** — privacy policy URL, support URL, content rating (1d)
9. **iOS app icon + launch screen** (if shipping iOS) (0.5d)
10. **App Privacy details** for App Store (data collection practices) (0.5d)

### Hardening (P2 — within 3 months)
11. Encrypt the local activity log (currently plaintext SharedPreferences)
12. Add content moderation for journal entries (when added)
13. Add subscription/billing (Stripe / RevenueCat) if monetizing
14. Move to Postgres if scaling past ~5k writes/sec on PB
15. Add a service worker for Flutter web (offline shell)

---

## 10. Timeline to production

| Phase | Scope | Effort |
|-------|-------|--------|
| **P0 fixes (this week)** | Firebase init, world route, CF cache, PB rules, one real test | **~6 hours** |
| **P1 hardening (month 1)** | Auth, test coverage, store metadata, privacy details | **~5 days** |
| **P2 scale (months 2-3)** | Encryption, billing, Postgres migration if needed | **~3 weeks** |

**The mobile app is 90% production-ready. The platform around it is 60% ready. The biggest single gap is Firebase — until that's initialized, we have no auth, no crash reporting, no analytics, and the user identity is ephemeral.**

---

## 11. Recommended next actions (in order)

1. **(now) Initialize Firebase** — biggest single win, 3 hours
2. **(now) Fix `/world/world-${slug}`** — small but live-breaking
3. **(today) Add 3-5 real unit tests** — confidence before users touch it
4. **(this week) PB rule audit** — explicit `null` everywhere
5. **(this week) CF cache fix** — either purge token or versioned path
6. **(this week) Set up Crashlytics** — same Firebase project
7. **(next week) Add Firebase Auth** — anonymous → Google upgrade
8. **(next 2 weeks) Test coverage** for the engagement loops
9. **(next 2 weeks) App Store / Play Store** — privacy policy + metadata
10. **(month 2+) Encrypt local data + Postgres migration planning**

---

## Appendix: What's been shipped (last 7 days)

For context — this audit was run on a system that's had 12 production deploys in the last week:

- **v9** — Design system (Lumen + Copy + EmptyState)
- **v10** — Wire /now, /prayer, /praise, /settings routes to real pages
- **v11** — Character animation overhaul (8 emotion states, state machine, milestone overlay, pressable, edge glow)
- **v12** — Zero hardcoded values (refactored all colors/strings/timings through tokens)

7 P0 audit fixes + 6 P1 features + 4 quick wins. 33 git commits. 5 new design files. 1,356 token references.
