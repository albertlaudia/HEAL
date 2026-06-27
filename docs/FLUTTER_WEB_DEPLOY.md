# Flutter Web — Deploy Strategy + Dokploy Setup

**Date:** 2026-06-27
**Author:** Mavis
**Status:** Recommended (not yet deployed)

---

## TL;DR

YES — deploy the Flutter mobile app as a third surface to Dokploy. It complements
the Next.js web (which is the marketing + content site) by giving users the full
practice experience (streak, voice calibration, sit-with-verse, haptics, time-of-day
palette) in the browser.

**Where to point the DNS:**
- `heal.positiveness.club` → **Next.js** (live today, SEO-friendly)
- `app.heal.positiveness.club` → **Flutter Web** (new, full practice experience)
- OR use a path: `heal.positiveness.club/app` → Flutter Web, `/` stays Next.js

The simplest model: keep the existing site as-is, add Flutter Web as a sibling
app on a subdomain. Users see the brand on the main site, then click into the app.

---

## 1. Flutter Web Setup (in the existing mobile/ project)

The Flutter SDK supports web out-of-the-box in 3.24+. We just need to:

1. **Add `web/` folder** via `flutter create --platforms=web .` (in the mobile dir)
2. **Customize `web/index.html`** with HEAL branding + PWA tags
3. **Set the web renderer** to `canvaskit` (already default in 3.27+, faster than html)
4. **Add CORS-aware audio service** (audioplayers needs special handling on web)
5. **Add a build script** that produces a static bundle under `build/web/`
6. **Configure Dokploy** to serve the static bundle via Nginx

### Key code changes for web compatibility

```dart
// lib/core/audio_session.dart (NEW — platform-aware)
import 'dart:io' show Platform;
import 'package:audio_session/audio_session.dart';

Future<void> configureAudioSession() async {
  if (kIsWeb) {
    // Web doesn't need AudioSession config — browser handles it
    return;
  }
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  ));
}
```

```dart
// lib/services/voice_calibration_service.dart (already has kIsWeb guard needed)
class VoiceCalibrationService {
  Future<void> start() async {
    if (kIsWeb) {
      // Web can't use `record` package for raw audio capture
      // Use the Web Audio API instead — getUserMedia() for mic level metering
      // Fallback: skip voice calibration on web, prompt user to use mobile
      state = state.copyWith(
        phase: CalibrationPhase.idle,
        message: 'Voice calibration is mobile-only. Use the iOS or Android app.',
      );
      return;
    }
    // ... existing mic recording code ...
  }
}
```

```dart
// lib/services/notification_service.dart (already needs kIsWeb guard)
Future<void> init() async {
  if (kIsWeb) return; // Web push uses Firebase Messaging, separate setup
  // ... existing notification init ...
}
```

### Custom index.html

```html
<!-- mobile/web/index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="HEAL — a quiet Christian mindfulness practice">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="HEAL">

  <link rel="manifest" href="manifest.json">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <title>HEAL</title>
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

### Manifest.json (PWA install)

```json
{
  "name": "HEAL",
  "short_name": "HEAL",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#1A1110",
  "theme_color": "#B08C4F",
  "description": "A quiet Christian mindfulness practice",
  "orientation": "portrait",
  "prefer_related_applications": true,
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

---

## 2. Build the web bundle

```bash
cd /workspace/HEAL/mobile
flutter pub get
flutter build web --release --no-tree-shake-icons \
  --dart-define=PB_URL=https://pocketbase.scaleupcrm.com \
  --dart-define=CDN_URL=https://resources.positiveness.club/heal \
  --dart-define=SITE_URL=https://app.heal.positiveness.club \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_PROJECT_ID=heal-prd \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
```

**Output:** `mobile/build/web/` (static files: index.html, main.dart.js, assets/, etc.)

**Bundle size:** ~2-3MB initial, ~600KB gzipped. Acceptable for a content-heavy app.

**Optimization flags:**
- `--web-renderer canvaskit` — better visual fidelity (default in 3.27+)
- `--no-tree-shake-icons` — keep all material icons available (Flutter 3.27+ default)
- `--source-maps` — for production debugging

---

## 3. Dokploy setup

### Option A: Static site via Nginx (recommended for Flutter Web)

Create a Dockerfile in `mobile/web.Dockerfile`:

```dockerfile
FROM nginx:1.27-alpine

# Copy the Flutter web build
COPY build/web /usr/share/nginx/html

# Custom Nginx config: SPA fallback + gzip + cache headers
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
  listen 80;
  server_name _;

  root /usr/share/nginx/html;
  index index.html;

  # SPA fallback — Flutter handles routing in JS
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Long cache for immutable assets
  location ~* \.(js|css|wasm|woff2?|ttf|otf|png|jpg|jpeg|gif|svg|ico)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
  }

  # index.html — short cache so deploys take effect immediately
  location = /index.html {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    expires 0;
  }

  # Gzip everything text
  gzip on;
  gzip_types text/plain text/css application/javascript application/json image/svg+xml;
  gzip_min_length 1024;

  # Security headers
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O /dev/null http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
```

### Create the Dokploy app

```bash
# Via API (the pattern we used for the Next.js app)
DOKPLOY_URL=https://dokploy.scaleupcrm.com
DOKPLOY_API_KEY=...

# Step 1: create the project entry if needed (we have "Sites" project: YaIYbkOB74WCZGgnJSNVf)

# Step 2: create the app
curl -X POST "$DOKPLOY_URL/api/trpc/application.create" \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "json": {
      "name": "HEAL Flutter Web",
      "projectId": "YaIYbkOB74WCZGgnJSNVf",
      "environmentId": "yxYViwNoutfji_VT1e013",
      "sourceType": "github",
      "githubId": "V0DXOTtjjFRqNPC_vyL2A",  // from existing HEAL app
      "owner": "albertlaudia",
      "repository": "HEAL",
      "branch": "main",
      "buildPath": "/mobile",
      "dockerfile": "web.Dockerfile",
      "buildType": "dockerfile",
      "autoDeploy": true,
      "triggerType": "push",
      "replicas": 1,
      "memoryLimit": "1073741824",
      "memoryReservation": "536870912"
    }
  }'
```

### Step 3: Add the domain

```bash
curl -X POST "$DOKPLOY_URL/api/trpc/domain.create" \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "json": {
      "host": "app.heal.positiveness.club",
      "https": true,
      "port": 80,
      "certificateType": "letsencrypt",
      "applicationId": "<new-app-id>",
      "domainType": "application",
      "path": "/"
    }
  }'
```

### Step 4: Manual deploy (first time only — API returns null for new apps)

Open https://dokploy.scaleupcrm.com → HEAL Flutter Web → click **Deploy**.

### Step 5: DNS — point `app.heal.positiveness.club` to Dokploy

Either:
- **Cloudflare proxy**: add CNAME `app` → Dokploy's auto-sslip URL
- **OR** add the subdomain directly to Dokploy's IP via the user's DNS provider

---

## 4. GitHub Actions — auto-deploy

The existing `trigger-dokploy.yml` only handles the Next.js app. Add a second workflow:

```yaml
# .github/workflows/trigger-dokploy-flutter.yml
name: Trigger Dokploy (Flutter Web)

on:
  push:
    branches: [main]
    paths:
      - 'mobile/**'
      - '.github/workflows/trigger-dokploy-flutter.yml'

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - run: |
          curl -X POST "https://dokploy.scaleupcrm.com/api/trpc/application.redeploy" \
            -H "x-api-key: ${{ secrets.DOKPLOY_API_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{"json":{"applicationId":"<new-flutter-app-id>"}}'
```

---

## 5. URL routing model (final)

```
User visits heal.positiveness.club
  → Next.js app (marketing + content library)
  → User clicks "Begin Practice" or "Today"
  → Redirects to app.heal.positiveness.club
  → Flutter Web (full experience)

OR (alternative — same origin):
User visits heal.positiveness.club
  → Next.js renders homepage
  → "Try the full experience" CTA
  → /app route rewrites to Flutter Web on the same domain
    (proxied via Dokploy middleware)
```

**Recommended:** subdomain (app.heal.positiveness.club). Simpler setup, cleaner separation.

---

## 6. What works on Flutter Web vs what doesn't

| Feature | Web | Native | Workaround |
|---|---|---|---|
| PB content fetch | ✅ | ✅ | — |
| Streak + welcome-back | ✅ | ✅ | — |
| Time-of-day palette | ✅ | ✅ | — |
| Sit-with-verse | ✅ | ✅ | — |
| Breath studio animations | ✅ | ✅ | — |
| Breath haptics | ❌ | ✅ | Use Audio session on web |
| Voice calibration | ❌ | ✅ | "Available on mobile" CTA |
| Notifications | ⚠️ | ✅ | Web uses Firebase Messaging (separate setup) |
| Audio playback | ✅ | ✅ | — |
| Audio background | ❌ | ✅ | Browser tab must stay active |
| Favorites (Firestore) | ✅ | ✅ | — |
| Journal entries | ✅ | ✅ | — |

**Web limitations are acceptable** — voice calibration + haptics are bonus features, the core practice works on all surfaces.

---

## 7. Estimated timeline

| Step | Effort | ETA |
|---|---|---|
| Add `web/` folder to mobile + customize index.html | 1h | today |
| Add kIsWeb guards in voice_calibration, notification_service | 30min | today |
| Build first web bundle + verify it renders | 30min | today |
| Create `web.Dockerfile` + Nginx config | 30min | today |
| Create Dokploy app via API | 5min | today |
| Add domain `app.heal.positiveness.club` | 5min | today |
| First deploy (UI click, API returns null) | 10min | today |
| DNS CNAME via Cloudflare | 5min | today |
| Add GitHub Action for auto-deploy | 15min | today |
| End-to-end verification on live URL | 30min | today |
| **Total** | **4h** | **today** |

---

## 8. Cost impact

| Resource | Current | After Flutter Web |
|---|---|---|
| Disk (Flutter build artifacts) | 681MB | ~750MB (+~70MB web bundle) |
| Bandwidth (web bundle load) | — | +600KB gzipped × first visit |
| Memory (Flutter web runtime) | — | +200-400MB per tab |
| Dokploy container count | 1 (Next.js) | 2 (+ Flutter Web) |
| Dokploy cost | shared VPS | no change (single VPS, 2 containers) |

**Total added monthly cost:** ~$0.50 in extra CPU/RAM for the Flutter Web container.

---

## 9. Rollback plan

If Flutter Web has issues in production:

1. The Next.js app at `heal.positiveness.club` is unchanged — unaffected
2. Just delete the Dokploy app for Flutter Web (or pause it)
3. Users who bookmarked `app.heal.positiveness.club` get a 404 (clean — no half-broken state)
4. Re-deploy anytime by clicking Deploy in the UI

The risk is bounded: Flutter Web is purely additive to the existing experience.

---

## 10. Ready to execute?

Say "do it" and I'll:
1. Add `web/` folder to mobile with custom index.html + manifest.json
2. Add kIsWeb guards to voice_calibration_service + notification_service
3. Create `mobile/web.Dockerfile` with Nginx + SPA fallback
4. Create the new Dokploy app via API
5. Add the GitHub Action for auto-deploy
6. Commit + push (you'll need to click Deploy in Dokploy UI for the first build)
