# HEAL — Mobile

Flutter app (iOS + Android) for HEAL — a quiet Christian mindfulness practice.

Mirrors the `/web` Next.js site, focused on the daily practice loop:
home → meditate → breathe → praise → prayer → essay.

## Stack

- **Flutter 3.24+** (Dart 3.5+)
- **flutter_riverpod 2** — state (matches /web pattern of single Notifier)
- **go_router 14** — deep-linkable navigation
- **drift** — local storage (settings + history), drift_flutter for native
- **pocketbase** — same backend as /web (`HEAL_*` collections)
- **firebase_auth** + **cloud_firestore** — same identity layer as /web
- **audioplayers** + **record** — same audio stack as /web
- **google_fonts** — Inter (body) + Cormorant Garamond (display)
- **flutter_animate** — micro-animations

## Build & run

```bash
# Install dependencies
flutter pub get

# Run codegen (drift, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Launch on connected device/emulator
flutter run --dart-define=CDN_BASE=https://resources.positiveness.club/heal

# Production build
flutter build apk --release --dart-define=CDN_BASE=https://resources.positiveness.club/heal
flutter build ios --release --dart-define=CDN_BASE=https://resources.positiveness.club/heal
```

## Layout

```
lib/
  main.dart           # App entry
  app.dart            # MaterialApp.router shell
  core/
    env.dart          # CDN_BASE, POCKETBASE_URL, FIREBASE_*
    router.dart       # GoRouter config
    theme.dart        # Material 3 dark + rosewood/brass/bronze palette
    observability.dart
  data/
    bootstrap.dart    # PocketBase + Firebase init
  features/
    home/             # Splash + Home (single narrative flow)
    now/              # "What is here, right now"
    meditate/         # Meditation player
    praise/           # Library + detail
    prayer/           # Prayer screen
    breathe/          # Breath studio (animated)
    essays/           # Long-form reading
```

## Content parity with /web

This app reads the **same PocketBase collections** as the web app
(`HEAL_meditations`, `HEAL_praise`, `HEAL_prayers`, `HEAL_essays`,
`HEAL_breathwork`, `HEAL_scriptures`, `HEAL_quotes`).

All media (illustrations + audio) is served from the Cloudflare-fronted
CDN at `https://resources.positiveness.club/heal/...` — no large assets
shipped in the bundle.

## iOS bundle id

`com.solverwatch.heal`

## Android package

`com.solverwatch.heal`
