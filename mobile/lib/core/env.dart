// HEAL — Environment configuration.
// Reads from --dart-define at build time. Defaults to production values.

class HealEnv {
  static const String pocketbaseUrl = String.fromEnvironment(
    'PB_URL',
    defaultValue: 'https://pocketbase.scaleupcrm.com',
  );

  static const String cdnUrl = String.fromEnvironment(
    'CDN_URL',
    defaultValue: 'https://resources.positiveness.club/heal',
  );

  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://heal.positiveness.club',
  );

  /// Next.js API gateway URL (Postgres-backed). Set to empty to fall back
  /// to PocketBase for the read paths. See api_repositories.dart.
  static const String nextApiUrl = String.fromEnvironment(
    'NEXT_API_URL',
    defaultValue: 'https://heal.positiveness.club',
  );

  // Firebase (overridden via --dart-define)
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: false);

  static const String appName = 'HEAL';
  static const String appTagline = 'A quiet Christian mindfulness practice';
}