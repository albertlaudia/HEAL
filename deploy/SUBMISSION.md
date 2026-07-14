# HEAL — App Store / Play Store Submission Guide

This is the canonical checklist for submitting HEAL to the App Store and
Google Play. It is the single source of truth for what reviewers will need
to find, what they will ask about, and how to answer.

## Bundle / Package identifiers

| Surface | ID |
|---|---|
| iOS bundle ID | `com.pclub.heal` |
| Android applicationId | `com.pclub.heal` |
| Android namespace | `com.pclub.heal` |
| Dart package name | `heal` |
| Web package.json name | `heal` |

All five must match exactly.

## URLs to provide in the store listings

| URL | Purpose |
|---|---|
| `https://heal.positiveness.club/privacy` | **Privacy policy** — required by both stores |
| `https://heal.positiveness.club/support` | **Support URL** — required by App Store |
| `https://heal.positiveness.club/terms`   | **Terms of service** — required if you collect any account data |

## App Store Connect checklist (iOS)

### 1. App information

- [ ] **Name:** HEAL
- [ ] **Subtitle:** A quiet Christian mindfulness practice
- [ ] **Category:** Health & Fitness (primary), Lifestyle (secondary)
- [ ] **Content Rights:** contains third-party content (scripture translations) — confirm license
- [ ] **Privacy Policy URL:** `https://heal.positiveness.club/privacy`
- [ ] **Support URL:** `https://heal.positiveness.club/support`
- [ ] **Marketing URL:** leave empty
- [ ] **Subtitle (30 char max):** A quiet mindfulness practice
- [ ] **Promotional text (170 char max):** Five minutes of scripture, breath, and prayer. No tracking. No ads. No noise.

### 2. Pricing and availability

- [ ] **Price tier:** Free
- [ ] **Availability:** all territories except embargoed

### 3. App Privacy (the questionnaire)

App Store requires a privacy questionnaire per data type. Our answers:

| Data type | Collected? | Linked to user identity? | Used for tracking? | Purposes |
|---|---|---|---|---|
| **Email address** | Yes (only if you sign in) | Yes | No | App functionality |
| **Name** | Yes (only if you sign in) | Yes | No | App functionality |
| **Photos or videos** | No | — | — | — |
| **Audio data** (playback duration) | Yes | No | No | App functionality |
| **Gameplay content** | No | — | — | — |
| **Contacts** | No | — | — | — |
| **Health & fitness** | No | — | — | — |
| **Financial info** | No | — | — | — |
| **Location** | No | — | — | — |
| **Sensitive info** | No | — | — | — |
| **Browsing history** | No | — | — | — |
| **Search history** | No | — | — | — |
| **Identifiers** (User ID) | Yes (random local + Firebase UID) | Yes | No | App functionality |
| **Usage data** (sessions, stickers) | Yes | No | No | App functionality |
| **Diagnostics** (crash logs) | No | — | — | — |
| **Purchases** | No | — | — | — |

If the questionnaire asks about **tracking**: NO, we do not track.

### 4. App Capabilities

- [ ] **Sign in with Apple:** enabled (Firebase provider, entitlement present in `Runner.entitlements`)
- [ ] **Push notifications:** disabled in v16 (only local notifications for daily reminders)
- [ ] **In-app purchases:** none
- [ ] **Background modes:** audio (so playback continues when device is locked)

### 5. Build upload

- [ ] Archive in Xcode with the **Any iOS Device** destination
- [ ] Distribution method: App Store Connect
- [ ] Upload via Xcode Organizer or Transporter
- [ ] Build number must increment (current: 1)

### 6. Export compliance (encryption)

- [ ] HEAL uses HTTPS only (ATS defaults). No use of cryptography outside
      of Apple's standard iOS / iPadOS / tvOS / watchOS APIs.
- [ ] Answer **"Is your app designed to use cryptography or contains
      cryptography?"** → **YES**
- [ ] Answer **"Does your app qualify for any of the exemptions provided
      in Category 5 Part 2 of the U.S. Export Administration Regulations?"** → **YES** (HTTPS-only, no proprietary cryptography)

## Play Console checklist (Android)

### 1. App content

- [ ] **App access:** all functionality is available without login
- [ ] **Ads:** none
- [ ] **Content rating:** Everyone (PEGI 4 / ESRB E)
- [ ] **Target audience:** 13+
- [ ] **News app:** no
- [ ] **COVID-19 contact tracing:** no
- [ ] **Health apps:** no (mindfulness, not medical)
- [ ] **Data safety:**
    - **Data shared with third parties:** none
    - **Data collected:**
        - Email (only if signed in) — used for app functionality, not for advertising
        - Name (only if signed in) — used for app functionality
        - Audio playback duration — used for app functionality
    - **Data the user can request to delete:** yes (Settings → Privacy → "Delete my account" — or via the support email)
    - **Data stored on-device only:** yes
    - **Data encrypted in transit:** yes (HTTPS / TLS)
    - **Data the user can opt out of:** yes (can stop signing in, can clear local data via device settings)
- [ ] **Government app:** no
- [ ] **Financial features:** none
- [ ] **Health:** none

### 2. Target API level

- [ ] **Target API level:** 36 (Android 14) — required by Google Play
- [ ] **Minimum API level:** 23 (Android 6.0 Marshmallow)

### 3. Permissions disclosure

The app declares these permissions in `AndroidManifest.xml`. Each one has
a clear user-facing explanation either in-app or in the system prompt.

| Permission | Why |
|---|---|
| `INTERNET` | Stream audio + fetch practice content |
| `ACCESS_NETWORK_STATE` | Detect offline mode + show "no internet" copy |
| `FOREGROUND_SERVICE` | Background audio playback |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Required for media-style foreground services on Android 14+ |
| `WAKE_LOCK` | Keep CPU alive during audio playback |
| `RECORD_AUDIO` | Breath Studio calibration (opt-in, only if user opens the calibration flow) |
| `POST_NOTIFICATIONS` | Daily reminder (Android 13+) |
| `RECEIVE_BOOT_COMPLETED` | Restore scheduled notifications after device reboot |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Fire reminders at the user-chosen time |
| `VIBRATE` | Haptic feedback for sticker unlocks |

### 4. Build upload

- [ ] Build a release AAB: `flutter build appbundle --release`
- [ ] Sign with the release keystore (see `mobile/android/key.properties` template)
- [ ] Upload to Play Console → Production → Create new release
- [ ] Roll out to internal testing first

## Common reviewer questions and answers

**Q: Why does HEAL ask for microphone access?**
A: Only if you open Breath Studio → Calibrate, which measures the rhythm of
your natural breath to personalize the inhale/exhale pace. We never
record, store, or upload the audio. Only the timing (in seconds) is kept,
on-device.

**Q: Why do I see a "Sign in" button in the app? What data do you collect
when I sign in?**
A: Signing in is optional. If you do, we get your email (for sign-in) and
display name (to greet you). We do not use your email for marketing, and
we do not share any data with third parties.

**Q: Does HEAL contain ads? Track users across apps?**
A: No. There is no ad SDK in the app. There is no cross-app tracking.
There is no advertising ID access.

**Q: Why is the iOS deployment target 13.0?**
A: Sign in with Apple requires iOS 13+. We chose the minimum deployment
target that supports all our required APIs.

**Q: Does HEAL use the camera? Location? Contacts?**
A: No.

## Pre-submission verification

```bash
# iOS
flutter build ios --release
# Check the build has:
#   - NSUserTrackingUsageDescription (no, only if you want to show the ATT prompt)
#   - PrivacyInfo.xcprivacy
#   - GoogleService-Info.plist
# All confirmed in mobile/ios/Runner/.

# Android
flutter build appbundle --release
# Verify:
#   - AndroidManifest.xml has dataExtractionRules
#   - targetSdk 36, minSdk 23
#   - All required permissions have usage descriptions

# Privacy policy
curl -sS -I https://heal.positiveness.club/privacy   # 200
curl -sS -I https://heal.positiveness.club/support   # 200
curl -sS -I https://heal.positiveness.club/terms     # 200
```
