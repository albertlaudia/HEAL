# HEAL — Deep System Analysis
**Date:** 2026-07-09
**Scope:** Flutter mobile codebase (`mobile/lib/`), production runtime, UX psychology, security posture
**Goal:** Identify concrete, prioritized improvements across performance, security, user experience, UI/UX, and behavioral psychology.

---

## TL;DR — Top 10 Actions

| Rank | Action | Area | Effort | Impact |
|------|--------|------|--------|--------|
| 1 | Fix inverted `_volumeAtFull` flag + duplicate position listeners in `AudioService` | Performance / UX | 30 min | Eliminates audio fade bugs + reduces rebuilds |
| 2 | Close `http.Client()` after each offline-cache download | Security / Perf | 15 min | Stops socket leak on repeated downloads |
| 3 | Debounce/track-completion side effects (Bible progress + sticker evaluation) | Performance | 2h | Prevents network spam on every track end |
| 4 | Add cache size ceiling / TTL invalidation to repository caches | Performance | 2h | Prevents unbounded memory growth |
| 5 | Encrypt or obfuscate local SharedPreferences keys/values (at minimum user ID + activity log) | Security | 1d | Protects local behavioral data |
| 6 | Add Content-Security-Policy + WAF rules for Next.js/Flutter web | Security | 2h | Harders XSS / probing surface |
| 7 | Ship the "first breath" onboarding screen before notification permission ask | Psychology | 4h | Reduces Day-1 drop-off & 1-star reviews |
| 8 | Replace 6-tile grid with staged discovery for first 7 sessions | Psychology / UX | 1d | Reduces paradox of choice |
| 9 | Add per-practice time estimates + progress bar on 90-second ritual | UX | 4h | Increases completion & reduces anxiety |
| 10 | Add client-side search index for 935+ PB records | UX / Retention | 1d | Unlocks power-user re-engagement |

---

## 1. Performance Analysis

### 1.1 Audio subsystem

**Duplicate position listeners**
```@d:\Github\HEAL\mobile\lib\services\audio_service.dart:130-176
_posSub = _player.onPositionChanged.listen((p) { ... });
...
_positionSub = _player.onPositionChanged.listen((pos) { ... });
```
Two listeners subscribe to `onPositionChanged`. The second listener also updates `state.position` and drives the fade-out. This causes double state updates on every 200ms tick. Consolidate into a single listener.

**Inverted fade flag**
```@d:\Github\HEAL\mobile\lib\services\audio_service.dart:172-175
} else if (remaining > fadeWindow && _volumeAtFull) {
  _player.setVolume(1.0);
  _volumeAtFull = false;
}
```
When restoring full volume, the code sets `_volumeAtFull = false`, which then prevents future restores. The flag semantics are inverted. The intended behavior is likely: only restore volume once when leaving the fade window. A `bool _volumeWasFaded` flag would be clearer.

**Fade completion race**
Completion restores volume in `onPlayerComplete`, but the position listener may still fire once after completion and re-apply a stale fade. Add a guard on `state.playing` or track idempotency.

### 1.2 Offline cache downloader

**Unclosed HTTP client**
```@d:\Github\HEAL\mobile\lib\services\offline_cache_service.dart:125-127
final request = http.Request('GET', Uri.parse(url));
final response = await http.Client().send(request);
```
A new `http.Client()` is created for every download and never closed. On a praise library with 112 songs, this leaks sockets and can exhaust the connection pool. Fix: instantiate one client per service or close in a `finally` block.

**Misleading Range-header comment**
The comment says "Uses HTTP Range headers to handle Cloudflare caching gracefully", but the code sends a plain `GET`. Either implement resume with `Range` headers or update the comment.

### 1.3 Repository caching

**Unbounded in-memory cache**
```@d:\Github\HEAL\mobile\lib\data\pb_repositories.dart:35-40
class _CachedList<T> {
  final List<T> data;
  final DateTime fetchedAt;
  bool get fresh => DateTime.now().difference(fetchedAt) < _cacheTtl;
}
```
Each repository holds a `Map<String, _CachedList<T>>` with no eviction. With multiple filter/sort permutations, memory grows indefinitely. Add LRU eviction (e.g. max 20 entries) and explicit invalidation hooks.

**No disk cache for PB records**
Every app cold start refetches meditation/praise/prayer lists from PocketBase. On slow networks the home page shows skeletons/blank cards. Add a 24-hour disk cache layer using `drift` or encrypted SharedPreferences for the content catalog.

### 1.4 Track-completion side effects

**Heavy work on every completion**
```@d:\Github\HEAL\mobile\lib\main.dart:70-129
audio.onTrackComplete = (track, durationSeconds) async {
  ...
  final progress = await container.read(bibleProgressRepoProvider).forUser(userId)...
  final sticker = await container.read(stickerBookProvider.notifier).evaluate(...)
  ...
};
```
Every track completion triggers a network call to PB for Bible progress, plus SharedPreferences reads/writes for activity tracking and stickers. If a user skips through a playlist rapidly, this becomes a network/IO storm. Solutions:
- Cache Bible progress in a provider and refresh only once per session/day.
- Move sticker evaluation off the main isolate or batch it.

### 1.5 UI rebuilds

**Home page single scroll + many providers**
```@d:\Github\HEAL\mobile\lib\features\home\home_page.dart:43-50
SingleChildScrollView(
  physics: const BouncingScrollPhysics(),
  padding: ...,
  child: Column(...)
)
```
`HomePage` watches `timePaletteProvider`, `streakServiceProvider`, and `voiceCalibrationServiceProvider` at the top level. Any change rebuilds the entire page. Use `const` sub-widgets and `Consumer`/`Selector` scoped lower in the tree.

**Bottom nav rebuilds with audio state**
```@d:\Github\HEAL\mobile\lib\core\router.dart:43-64
final audio = ref.watch(audioServiceProvider);
...
return Scaffold(
  body: pages[currentIndex],
  bottomNavigationBar: Column(
    children: [
      if (audio.hasTrack) const ExpandableMiniPlayer(),
      _BottomNav(currentIndex: currentIndex),
    ],
  ),
);
```
`MainScaffold` watches the full `AudioState`; position updates every 200ms will rebuild the scaffold and all 5 tabs. Split this: watch only `audio.hasTrack` for the mini-player area.

### 1.6 Image loading

CDN images were optimized from PNG → WebP (~91% savings), which is excellent. Remaining gaps:
- No known `Cache-Control` headers on SmarterASP CDN. Images may re-download on every cold start.
- 2 praise illustrations are still PNG due to FTP failures; these cards load ~12x slower.
- Flutter web has no service worker, so repeat visits re-download the shell.

---

## 2. Security Analysis

### 2.1 Secrets management

Existing `SECURITY_NOTES_2026-07-08.md` already flags 5 exposed production secrets (GitHub PAT, Dokploy API key, PB superuser password, SmarterASP FTP password, SSH key). Additional mobile-specific concerns:

**Firebase config via `--dart-define`**
```@d:\Github\HEAL\mobile\lib\core\env.dart:21-25
static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
...
```
Good: keys are not hardcoded. Risk: if CI builds omit `--dart-define`, the app silently fails to initialize Firebase (no crash, but FCM/web analytics break). Add `assert` or build-time validation.

**User ID generation**
```@d:\Github\HEAL\mobile\lib\data\pb_repositories.dart:460-469
id = 'u-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
```
Uses `Random()` (not cryptographically secure) and a timestamp. For anonymous IDs this is acceptable locally, but if these IDs ever become auth tokens or shareable, switch to `Uuid.v4` or `Random.secure`.

### 2.2 Local data storage

**Unencrypted behavioral log**
`ActivityTracker`, `StreakService`, `StickerBook`, and profile name all store data in plain-text SharedPreferences. A malicious app with `READ_EXTERNAL_STORAGE` or a backup exploit could read the user's entire prayer/meditation history. Mitigations:
- Use `flutter_secure_storage` for user ID and any future auth tokens.
- Encrypt the activity log JSON with `encrypt` + a key derived from device ID.
- Set `android:allowBackup="false"` in `AndroidManifest.xml` to prevent cloud backup of local prefs.

**Activity log retention**
```@d:\Github\HEAL\mobile\lib\services\activity_tracker.dart:150-161
final j = {
  'recent': state.recent.take(200).map((e) => e.toJson()).toList(),
  ...
};
```
The log is capped at 200 events, which is reasonable, but event metadata (`meta`) can contain arbitrary strings. No sanitization before persistence.

### 2.3 PocketBase access rules

**Bible progress filter by raw user ID**
```@d:\Github\HEAL\mobile\lib\data\pb_repositories.dart:415-425
filter: "user_id='$userId'",
```
If `HEAL_bible_progress` collection rules are not strict (`viewRule: "user_id = @request.auth.id"`), any user can read any other user's progress by guessing IDs. PB rules must be audited server-side; the client filter is not protection.

**Public PB collections**
Meditations, praise, prayers, scriptures are fetched without authentication. This is intentional for an open content catalog, but ensure:
- `create/update/delete` rules are admin-only.
- `_superusers` endpoint is not internet-facing.
- API rate limits exist at Cloudflare/VPS level.

### 2.4 Network hygiene

- No certificate pinning for CDN or PB API.
- No integrity check on downloaded MP3 files (SHA-256/hash mismatch not verified).
- `print` statements in crash handler leak stack traces in release builds:
  ```@d:\Github\HEAL\mobile\lib\main.dart:146-148
  }, (error, stack) {
    print('Uncaught: $error\n$stack');
  });
  ```
  Replace with crash reporter (e.g. Firebase Crashlytics) and omit logs in release.

---

## 3. User Experience & UI/UX Analysis

### 3.1 Onboarding

The current onboarding (`OnboardingPage`) is already being improved with a "first breath" screen, but the code still asks for notification permission on the 3rd/4th screen before the user has completed a practice. This is a known 1-star risk.

Recommended flow:
1. Value prop (1-2 screens)
2. **First breath** (30-60s guided breath — user feels the product)
3. Notification ask **only after first completed session**, framed as *"Want a gentle nudge tomorrow at 7am?"*
4. Home

```@d:\Github\HEAL\mobile\lib\features\onboarding\onboarding_page.dart:37-52
final pages = [
  const _ValuePage(...),
  const _ValuePage(...),
  const _FirstBreathPage(),
  const _PermissionPage(),
];
```

### 3.2 Home page — paradox of choice

The grid exposes 6 practice types on day 1: Meditate, Praise, Pray, Reflections, Sleep, Stickers (plus Bible via tab). New users have no mental model to choose.

Fix: stage discovery based on `totalSessions`:
- Sessions 1-3: one "Start here" tile (today's practice)
- Sessions 4-7: 2 tiles (today's practice + most-used practice)
- Sessions 8+: full grid

### 3.3 Progress & feedback

**No visible progress during 90-second ritual**
The "Begin" today-practice sequence starts without a progress bar or step labels. Users in a mindfulness context need temporal anchors. Add a thin progress bar + labels: "Pause → Breathe → Read → Pray".

**Practice tiles lack duration**
Each tile should show "~5 min" so users can choose based on available time.

**Completion celebrations are light**
Sticker unlock plays a chime (good), but there is no visual milestone overlay for finishing a Bible chapter. Add a 2-second brass-glow overlay with the verse name, e.g. "You finished Genesis 1-3. Day 1 of 365." Keep it reverent — no confetti.

### 3.4 Sticker book

```@d:\Github\HEAL\mobile\lib\services\sticker_book.dart:50-83
const _allStickers = <Sticker>[...];
```
The sticker list is excellent and differentiated (Bible iconic moments). Missing:
- A "next milestone" panel: "5 more sessions → First Light".
- Family labels "streak / practice / moment" are abstract. Consider "Daily / Firsts / Stories".
- Tap targets and a11y labels should be verified.

### 3.5 Praise library

112 songs in one scroll is overwhelming on day 1. Default to a curated "Today's praise" at the top, deterministic by day, then show the full filterable library below.

### 3.6 Sleep / ambient

- Ambient mixer shows 6 tracks + 5 presets immediately. Reduce to 3 on first open.
- Sleep stories hero is poetic but vague. Add meta: "8-12 min · Psalm 23 · calm voice".

### 3.7 Notifications

Current defaults: morning 7am + evening 9pm. Evening reminders can feel like guilt. Existing `notification_service.dart` has good warm copy and missed-day variants. Recommendation:
- Default to **one notification per day, morning only**.
- Make evening opt-in in settings.
- Add notification action buttons: "I'm here" / "Skip today".

### 3.8 Search

With 271 meditations, 67 prayers, 31 scriptures, 365 Bible readings, and 60 quotes, browsing is the only discovery path. A client-side search index (built at app boot from cached PB data) would unlock power-user retention.

### 3.9 Accessibility

- Many icons use emoji (`Sticker.icon`) — screen readers may announce them poorly.
- Bottom nav has 5 items; on small screens labels are cramped.
- No `Semantics` wrappers observed on Today cards or sticker grid.
- A11y labels needed on breath ring, mini-player, and practice tiles.

---

## 4. Psychology & Behavioral Analysis

### 4.1 What's working well

- **Grace-based streaks:** 4-day grace period removes shame from missed days.
- **Warm copy:** Streak messages avoid guilt ("A quiet return", "Begin where you are").
- **No-failure notifications:** Missed-day copy leads with the practice, not blame.
- **Identity language:** Sticker descriptions emphasize becoming ("You are becoming", "The practice has roots now").

### 4.2 Identity formation gap

The profile page shows numbers (streak, total sessions, minutes) but does not explicitly name the user's identity. Add a small identity card:
> "You are the kind of person who shows up."

This shifts self-concept from "I use an app" to "I am someone who practices stillness."

### 4.3 Return-after-absence

Current welcome-back threshold is 4+ days. The card exists but is opt-in. After 7+ days, offer a one-time "Restart Day 1" button for Bible-in-a-Year so empty calendar cells don't accumulate shame.

### 4.4 Habit stacking

The app relies on notifications and willpower. It could leverage habit anchors:
- "After your morning coffee" scheduling option.
- Pairing breath practice with opening the app.
- "Same time tomorrow" one-tap scheduling from completion screen.

### 4.5 Variable reward

Stickers are deterministic milestones. Consider a small variable reward layer:
- "Today's verse" is a fresh daily discovery.
- Occasional "rare moment" stickers for less common actions (e.g. complete a reading before 6am).

### 4.6 Social proof & commitment

No social features are present. Low-friction options:
- "Share today's reflection" via Web Share API (already suggested in status report).
- Optional "pray for a friend" feature — lightweight and aligned with the brand.

### 4.7 Loss aversion

The streak counter triggers loss aversion. Use it carefully:
- Don't show "You're about to lose your streak" notifications.
- Frame re-engagement as "The practice is waiting" not "Don't break the chain."

---

## 5. Architecture & Code Quality

### 5.1 State management

Riverpod + hooks is a solid choice. Some refinements:
- Use `select` more aggressively to avoid full rebuilds.
- Avoid `Consumer` inside `HookConsumerWidget` unless necessary (`settings_page.dart` does this once for voice profile; acceptable but could be a `Selector`).

### 5.2 Error handling

Silent failures are common:
```@d:\Github\HEAL\mobile\lib\data\pb_repositories.dart:68-74
Future<Meditation?> get(String id) async {
  try {
    final r = await _pb.collection('HEAL_meditations').getOne(id);
    return Meditation.fromJson(r.toJson());
  } catch (_) {
    return null;
  }
}
```
Swallowing all errors makes debugging and user-visible failure states hard. Distinguish "not found" (404) from network errors and surface the latter to the user.

### 5.3 Model consistency

`pb_models.dart` recently had constructor/field mismatches (chords, dayOfYear, etc.) indicating schema drift between PB and Flutter. Establish:
- PB schema migration checklist.
- Code-generation from PB schema or golden sample JSON tests.

### 5.4 Imports & duplicate code

`router.dart` imports many feature pages directly; as features grow this file becomes a coupling hotspot. Consider route-specific barrels or code-splitting with `GoRouter` lazy builders.

### 5.5 Testing

No test files were found in the reviewed paths. Priority tests:
- Streak computation edge cases (grace days, timezone boundaries).
- AudioService playlist behavior.
- OfflineCache download/retry/removal.
- Sticker evaluation criteria.

### 5.6 Large files

- `home_page.dart`: ~1500 lines
- `profile_page.dart`: ~984 lines
- `pb_repositories.dart`: ~474 lines

These are approaching unmaintainable. Split by section/widget into private files.

---

## 6. Prioritized Roadmap

### This week (P0)
1. Fix `AudioService` duplicate listeners + fade flag.
2. Close `http.Client()` in `OfflineCacheService`.
3. Add repository cache size ceiling.
4. Move notification permission ask to after first completed session.
5. Add progress bar + step labels to 90-second ritual.
6. Stage home-page grid discovery for new users.
7. Add per-practice time estimates on tiles.

### Next 2 weeks (P1)
8. Encrypt local activity log + disable Android backup.
9. Cache Bible progress in a provider; stop fetching on every track completion.
10. Add client-side search index.
11. Add "Today's praise" curation.
12. Add completion milestone overlay for Bible chapters.
13. Default notifications to morning-only; evening opt-in.

### This month (P2)
14. Service worker for Flutter web + CDN cache headers.
15. Accessibility audit (VoiceOver/TalkBack).
16. Unit tests for streak, audio, cache, sticker evaluation.
17. Split oversized Dart files.
18. Add identity-language card to profile.
19. Rotate 5 exposed secrets and document procedure.

---

## 7. Quick Wins — Single-Line / Small Edits

- Replace `print('Uncaught: ...')` in `main.dart` with Crashlytics or Sentry.
- Add `Semantics` labels to Today cards and sticker grid.
- Add `maxLines` + overflow to sticker descriptions for small screens.
- Use `Selector` in `MainScaffold` to watch only `audio.hasTrack`.
- Add `android:allowBackup="false"` in `AndroidManifest.xml`.
- Rename sticker families to "Daily / Firsts / Stories".
- Add `const` constructors where analyzer flags them (57+ info-level issues).

---

## 8. Metrics to Watch

| Metric | Why it matters | Current baseline |
|--------|---------------|------------------|
| Day-1 retention | Onboarding quality | Unknown — add analytics |
| Day-7 / Day-30 retention | Habit formation | Unknown |
| Session completion rate | Ritual UX | Unknown |
| Notification opt-in rate | Permission timing | Unknown |
| Average session duration | Content fit | Unknown |
| Praise library scroll depth | Discovery | Unknown |
| Crash-free rate | Stability | Add Crashlytics |
| Apk size / build time | Perf | ~60MB likely |

---

## 9. Conclusion

HEAL is a psychologically thoughtful app with strong differentiation (Bible-in-a-Year, iconic-moment stickers, grace-based streaks). The immediate risks are not feature gaps but **runtime stability, resource leaks, and local data protection**. The biggest UX wins come from reducing cognitive load on day 1 and giving users temporal anchors during practice.

Ship the P0 fixes this week; they are low-effort and directly reduce churn and resource-related crashes. Then move to the P1 behavioral and discoverability improvements to deepen retention.
