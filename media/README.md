# HEAL Media — Golden Source

**This is the single source of truth for all HEAL branding and content assets.**

When you need a logo, app icon, illustration, or screenshot for the platform (web or mobile), look here first. Do not generate, redraw, or recreate — use the file in this folder.

## Structure

```
media/
├── branding/      # HEAL logo, wordmark, color palette, fonts
├── app-icon/      # All app icon sizes (iOS, Android, PWA, web favicon)
├── illustrations/ # Hand-illustrated / AI-illustrated content (meditations, prayers, etc.)
├── screenshots/   # Marketing screenshots for App Store / Play Store / website
├── docs/          # Source files for the documentation (diagrams, mockups)
└── audio/         # Audio source files for praise + meditations (if/when we keep local copies)
```

## Naming convention

- `kebab-case` for files: `heal-app-icon-1024.png`
- Include size in filename when there are multiple: `Icon-App-60x60@3x.png`
- Include language/variant if relevant: `wordmark-en.svg`, `wordmark-zh.svg`
- Include platform: `ios/`, `android/`, `web/`, `pwa/`

## Where assets are deployed (DO NOT copy here)

| Asset type | Lives in | Source of truth |
|---|---|---|
| **Logo, branding, app icons** | `/workspace/HEAL/media/` | THIS folder |
| **Web images (meditation, prayer, scripture illustrations)** | CDN at `resources.positiveness.club/heal/images/` | `/web/scripts/seed-programs-images.mjs` etc. |
| **Web audio (praise vocals/instrumentals)** | CDN at `resources.positiveness.club/heal/audio/` | `/web/scripts/auto-generate.mjs` etc. |
| **Flutter app icons (Android)** | `/mobile/android/app/src/main/res/mipmap-*/` | iOS AppIcon set + adaptive icon |
| **Flutter app icons (iOS)** | `/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/` | 60×60, 120×120, 180×180, 1024×1024 PNGs |

## How to add a new asset

1. **Drop the source file** into the appropriate subfolder here
2. **Use kebab-case** naming
3. **Update LICENSES.md** if it's third-party content (CC0, CC-BY, etc.)
4. **Update deployment script** to copy from here to wherever it needs to be (CDN, mobile bundle, etc.)
5. **Commit to git** with a clear message about what's added

## Sync to CDN

When new illustrations are added to `media/illustrations/`, run the web upload script to push them to the CDN. Do not duplicate them into multiple places.

## Sync to Flutter

The Flutter `pubspec.yaml` declares which assets to bundle. The build process picks them up from `/mobile/assets/` (a Flutter convention, not this folder). For now, the Flutter app downloads images from CDN at runtime (rather than bundling), so `/mobile/assets/` is mostly empty except for icons and a few static files.
