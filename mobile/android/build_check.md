# HEAL mobile — Android build troubleshooting

## Currently configured
- Android Gradle Plugin: **8.11.1**
- Kotlin: **2.2.20** (explicitly declared in `settings.gradle`)
- Gradle: **8.14**
- Java source/target: **17**
- Kotlin JVM target: **17** (forced in `app/build.gradle`)

## Why "Inconsistent JVM-target (17) vs (21)" happened

When `kotlinOptions { jvmTarget = ... }` is missing, Kotlin 2.2.20 defaults to JVM 21.
Java compileOptions stays at 17.
Gradle refuses to mix targets in the same compile unit.

**Fix applied 2026-07-01:** added `kotlinOptions { jvmTarget = "17" }` in `app/build.gradle`.

## Why the "Kotlin 2.0.0 will soon be dropped" warning appeared

AGP 8.11.1 ships with Kotlin **2.0.0** by default.
When `android.builtInKotlin=true` was in `gradle.properties`, Gradle used the embedded Kotlin
2.0.0 plugin instead of our explicitly pinned 2.2.20.

**Fix applied 2026-07-01:**
- Removed `android.builtInKotlin=true`
- Added `id "org.jetbrains.kotlin.android" version "2.2.20" apply false` to plugins block in `settings.gradle`

## Verification steps after pulling these changes

```bash
cd mobile
flutter clean
flutter pub get
flutter run -d <device>
```

Expected:
- No "Kotlin 2.0.0 will soon be dropped" warning
- No "Inconsistent JVM-target compatibility" error
- App reaches splash screen in ~3 sec

## If you ever need to bump Kotlin again

Edit `mobile/android/settings.gradle`:
```groovy
plugins {
    id "org.jetbrains.kotlin.android" version "2.3.20" apply false  // bump here
}
```

Make sure the Kotlin version's minimum AGP requirement is met:
- Kotlin 2.2.x → AGP 7.4.2+
- Kotlin 2.3.x → AGP 8.7+
- Always pair with AGP that came out before or with the Kotlin release

## If you ever need to add another Kotlin module (multi-module)

Each module needs its own `kotlinOptions { jvmTarget = "17" }` (or matching Java version).
Consider extracting this to a shared `buildSrc` config in a future refactor.
