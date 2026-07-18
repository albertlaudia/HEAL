# HEAL — Codebase Review & Path to 1M ARR

**Date:** 2026-07-18 | **Status:** 0 errors, 55 info lints, pre-launch

---

## Executive Summary

HEAL is a Christian mindfulness app (~30K LOC, 60+ Dart files) with breathwork, meditation, scripture, prayer, praise, and essays. Exceptional design system, reverent microcopy, privacy-first. Currently **$0 revenue** — no monetization layer exists.

### Top 10 Gaps Blocking 1M ARR

1. **No monetization** — no paywall, IAP, or Stripe
2. **No viral loop** — no sharing, no referral, no social
3. **No A/B testing** — can't optimize conversion
4. **No analytics funnel** — blind to onboarding drop-off
5. **No push segmentation** — one-size-fits-all notifications
6. **No localization** — English only, caps TAM
7. **No iOS widget/Live Activity** — misses daily touchpoint
8. **Test coverage <5%** — regression risk
9. **SharedPreferences only** — no cross-device sync
10. **God files** — `router.dart` (839 lines), `home_page.dart` (1616 lines), `praise_library_page.dart` (~1100 lines)

---

## Code Quality

### P0 — Fix Before Launch

- **`router.dart` (839 lines)**: Split into `router.dart`, `main_scaffold.dart`, `mini_player.dart`, `lyrics_sheet.dart`. Remove dead `MiniPlayer` class (lines 170-310).
- **`ExpandableMiniPlayer`**: `DraggableScrollableSheet` inside `Column` causes infinite height exceptions. Use `showModalBottomSheet` or custom animated container.
- **`home_page.dart` (1616 lines)**: 9 inline widget classes. Extract to `features/home/widgets/`.
- **`praise_library_page.dart` (~1100 lines)**: Split into page + widget files.
- **Two audio engines**: `audioplayers` + `just_audio` — iOS session conflict risk. Consolidate to `just_audio`.

### P1 — Fix Within 30 Days

- Inconsistent Riverpod imports (use only `hooks_riverpod`)
- No `EmptyState` on feature page errors (raw `Could not load: $e`)
- SharedPreferences as sole persistence — migrate to Drift (already in pubspec)
- `NowPage` uses `FutureBuilder` in `build()` — use `FutureProvider`
- Bottom nav doesn't use `StatefulShellRoute` (modern GoRouter pattern)
- No GDPR/CCPA data deletion in settings
- Journal entries plaintext (documented gap) — encrypt with SQLCipher

### P2 — Nice to Have

- No `freezed` for PB models (17KB hand-written)
- No l10n/i18n infrastructure
- 55 `prefer_const_constructors` lints — run `dart fix --apply`
- Riverpod 2.6 → 3.3 and go_router 14 → 17 migration (breaking changes)

---

## UX/UI Review

### What's Excellent
- **Lumen companion**: 8-emotion CustomPainter character — unique, no asset deps
- **Microcopy**: `copy.dart` enforces no-guilt, no-shame, reverent tone
- **Onboarding**: Value before ask (notification permission after first session)
- **Breath Studio**: 5 patterns, voice calibration, haptic, in-pocket mode — best feature
- **EmptyState**: Lumen-centered, reverent, no exclamation marks
- **Pressable**: Spring-physics button — better than Material InkWell
- **EmotionPalette**: Emotion-driven colors make app feel reactive

### What Needs Work

| Area | Issue | Fix |
|---|---|---|
| Onboarding | No personalization question | "What brings you here?" → content recommendations |
| Home | No resume card for interrupted sessions | Track last session, show "Continue" card |
| Home | Practice grid is static | Use ActivityTracker data for recommendations |
| Home | No time-aware content | Evening → sleep stories, morning → scripture |
| Now Page | No session completion → streak credit | Add "Begin" CTA, credit after 2+ min |
| Praise | No in-library search, no queue, no sort | Add search bar, play-all, sort dropdown |
| Settings | No notification time customization | Let user pick morning/evening time |
| Profile | No data export | Add JSON export for journal + history |
| Search | No search history / suggestions | Cache recent searches, show trending |

---

## Performance

- ✅ `select()` on audio provider avoids 200ms tick rebuilds
- ✅ 5-min PB repository cache
- ✅ `CachedNetworkImage` for images
- ⚠️ `NowPage` re-fetches on every build
- ⚠️ No pagination on meditation list or praise library
- ⚠️ SharedPreferences will hit ~1MB limit at scale
- ⚠️ No pre-caching of today's content on splash

**Fixes:** Migrate to Drift (SQLite), add pagination (24/page), pre-cache today's content during splash, use `StatefulShellRoute` for tab preservation.

---

## Security

- ✅ No hardcoded API keys (uses `--dart-define`)
- ⚠️ Journal plaintext in SharedPreferences
- ⚠️ No GDPR/CCPA data deletion
- ⚠️ No certificate pinning for PB API
- ⚠️ Production URLs as defaults in `env.dart`

---

## Testing

Current: 3 test files, ~5% coverage. Design system tests are good (Lumen, EdgeGlow, EmptyState, Copy).

**Critical missing:**
1. Unit tests for all services (streak, favorites, history, journal)
2. Widget tests for each feature page
3. Golden tests for Lumen (all 8 emotions)
4. Integration test: onboarding → session → streak credit
5. Add `flutter test` to CI

---

## Monetization to 1M ARR

### Revenue Math

```
1M ARR = $83,333/mo

At $4.99/mo Premium, 3% conversion:
  Need 556,000 MAU → 16,700 subscribers

Blended (60% monthly @ $4.99, 40% annual @ $39):
  Need ~600,000 MAU → ~18,000 subscribers
```

### Required Stack

**Phase 1 (Weeks 1-4):** RevenueCat (mobile IAP) + Stripe (web) + EntitlementService (Riverpod) + PaywallWidget (soft wall, 7-day trial)

**Phase 2 (Weeks 5-8):** Tiers — Free / Premium ($4.99) / Family ($9.99) / Church ($49/mo B2B)

**Phase 3 (Weeks 9-12):** A/B test price, trial length, paywall trigger. Add gift subscription + lifetime deal.

### Paywall Principles
- Never block core practice (breathe, read, pray always free)
- Show paywall after 3rd session, not before
- Highlight annual savings as default
- Graceful degradation — if RevenueCat fails, default to free

### Conversion Levers to Hit 3%

| Lever | Lift |
|---|---|
| Onboarding personalization | +0.5% |
| 7-day free trial | +1.0% |
| Streak + sticker gamification | +0.3% |
| Time-aware recommendations | +0.2% |
| Church B2B channel | +0.5% |
| Shareable verse cards | +0.5% (viral) |

---

## Growth Engine

### Viral Loop (Currently Zero)

1. **Share verse/prayer** — One-tap share as image card (YouVersion's #1 growth channel)
2. **Invite a friend** — Deep link → both get 1 month Premium free
3. **Church referral** — Pastor link → members get extended trial
4. **Streak sharing** — "Day 30 of stillness" card with Lumen art
5. **"I prayed for you"** — Notification card sharing

### Retention Mechanics

| Mechanic | Status | Impact |
|---|---|---|
| Streak system | ✅ Built | Daily habit |
| Sticker book | ✅ Built | Achievement |
| Welcome back card | ✅ Built | Re-engagement |
| Smart notifications | ⚠️ Basic | Need segmentation |
| Push notification timing | ⚠️ Fixed | Need time personalization |
| Re-engagement campaign | ❌ Missing | Win-back lapsed users |
| Email digest | ❌ Missing | Weekly content preview |
| Community/prayer circle | ❌ Missing | Social retention |

### Acquisition Channels

| Channel | Cost | Expected Reach |
|---|---|---|
| App Store organic (ASO) | $0 | 80% of Year 1 installs |
| Church partnerships (50 pastors × 200) | low | 10K+ users |
| Christian podcast tour (10 episodes) | $500/ep | 50K impressions |
| Christian YouTube influencers (5) | $1-5K each | 200K impressions |
| Facebook/Insta ads (Christian 25-55 F) | $0.50-1.50 CPI | 50K per $1K |
| SEO content (15 posts) | $0 | 50K/yr per post |
| Shareable verse cards (viral) | $0 | Exponential |

---

## Product Roadmap to 1M ARR

### Q1 2026 (Launch) — "Clean Foundation"
- Fix all P0 code issues (split god files, fix mini player)
- Add RevenueCat + paywall
- Add shareable verse cards (viral loop seed)
- Add onboarding personalization
- Add analytics funnel (Amplitude or Mixpanel)
- Ship to App Store + Play Store
- **Target: 5,000 downloads, 50 subscribers**

### Q2 2026 — "Growth Engine"
- A/B test paywall (price, trial, trigger)
- Add invite/referral with Premium reward
- Add push notification segmentation
- Add iOS widget (today's verse)
- Add Android widget (streak flame)
- Church partnership program (5 churches)
- Podcast tour (10 episodes)
- **Target: 100K downloads, 1,500 subscribers, $11K MRR**

### Q3 2026 — "Retention & Depth"
- Add Drift migration (SQLite + sync)
- Add cross-device sync (Firebase)
- Add "Pray Together" 2-person sessions (Family tier)
- Add content localization (zh-CN, zh-TW, ja)
- Add email weekly digest
- Add re-engagement campaign (lapsed 7/14/30 day)
- **Target: 500K downloads, 8,000 subscribers, $60K MRR**

### Q4 2026 — "Scale"
- Add Church dashboard (B2B SaaS)
- Add AI prayer companion (on-device LLM)
- Add Apple Watch companion
- Add community/prayer circles
- Expand to 6 languages
- **Target: 1M ARR ($83K MRR)**

---

## 30/60/90 Day Execution Plan

### Days 1-30: Clean & Monetize
1. Split `router.dart` into 4 files
2. Split `home_page.dart` into widgets
3. Fix `ExpandableMiniPlayer` layout
4. Remove dead `MiniPlayer` class
5. Consolidate audio to `just_audio`
6. Add RevenueCat integration
7. Build `PaywallWidget` with 7-day trial
8. Build `EntitlementService` (Riverpod)
9. Add shareable verse card widget
10. Add analytics events (session, paywall_view, paywall_convert)
11. Run `dart fix --apply` for const lints
12. Add unit tests for StreakService, FavoritesService

### Days 31-60: Optimize & Grow
1. Add onboarding personalization screen
2. Add invite/referral with deep links
3. Add push notification segmentation
4. A/B test paywall trigger (session 3 vs 5)
5. Add pagination to all list pages
6. Add "resume session" card on home
7. Add time-aware content recommendations
8. Add iOS widget (today's verse)
9. Add Android widget (streak flame)
10. Church partnership outreach (5 pastors)
11. Add integration test: onboarding → session → streak
12. App Store / Play Store launch

### Days 61-90: Scale & Retain
1. Migrate user data to Drift (SQLite)
2. Add cross-device sync (Firebase)
3. Add "Pray Together" sessions
4. Add re-engagement notifications (7/14/30 day)
5. Add email weekly digest
6. Start localization (zh-CN first)
7. Add A/B testing framework
8. Add church dashboard MVP
9. Podcast tour outreach
10. Add golden tests for Lumen
11. Performance audit (frame rate, memory)
12. **Hit 1,500 subscribers → $11K MRR**

---

## Summary

HEAL has an exceptional product foundation — the design system, tone, and feature set are genuinely differentiated. The path to 1M ARR is:

1. **Fix the code debt** (split god files, fix mini player) — 1 week
2. **Add monetization** (RevenueCat + paywall) — 2 weeks
3. **Add viral loop** (shareable verse cards + referral) — 2 weeks
4. **Add analytics** (funnel + A/B framework) — 1 week
5. **Launch on App Store + Play Store** — 1 week
6. **Optimize conversion** (A/B test, personalize, segment) — ongoing
7. **Scale channels** (church partnerships, podcasts, ads) — ongoing

The product is ready. The monetization and growth infrastructure is not. Build those, and 1M ARR is achievable within 12 months.
