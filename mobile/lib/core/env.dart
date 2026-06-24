// Environment configuration for HEAL mobile.
// Mirrors the /web's NEXT_PUBLIC_* env vars but resolved at app launch.

import 'package:flutter/foundation.dart';

class Env {
  Env._({
    required this.cdnBase,
    required this.pocketbaseUrl,
    required this.firebaseApiKey,
    required this.firebaseProjectId,
    required this.firebaseAppId,
  });

  final String cdnBase;
  final String pocketbaseUrl;
  final String firebaseApiKey;
  final String firebaseProjectId;
  final String firebaseAppId;

  static Future<Env> load() async {
    // For now, hard-code from .env.example. Real impl: read from --dart-define
    // at build time (e.g. `flutter run --dart-define=CDN_BASE=...`).
    return Env._(
      cdnBase: const String.fromEnvironment(
        'CDN_BASE',
        defaultValue: 'https://resources.positiveness.club/heal',
      ),
      pocketbaseUrl: const String.fromEnvironment(
        'POCKETBASE_URL',
        defaultValue: 'https://pocketbase.scaleupcrm.com',
      ),
      firebaseApiKey: const String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: '',
      ),
      firebaseProjectId: const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: '',
      ),
      firebaseAppId: const String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '',
      ),
    );
  }

  bool get isDebug => kDebugMode;
}
