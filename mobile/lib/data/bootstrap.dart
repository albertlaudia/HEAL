// App bootstrap — initializes PocketBase and Firebase (when configured).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../core/env.dart';
import '../core/observability.dart';

/// Provider for the shared PocketBase client.
/// Overridden in main() after bootstrap completes.
final pocketbaseProvider = Provider<PocketBase>((ref) {
  throw UnimplementedError(
    'pocketbaseProvider must be overridden in main() after bootstrap. '
    'Make sure you awaited bootstrap() before calling runApp().',
  );
});

/// Provider for the shared Firebase app. Only available after bootstrap().
final firebaseAppProvider = Provider<FirebaseApp?>((ref) {
  return null; // null when Firebase is not configured
});

/// Provider for the shared Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final app = ref.watch(firebaseAppProvider);
  if (app == null) return null;
  return FirebaseFirestore.instance;
});

/// Boot PocketBase + Firebase (if API key is set), overriding the providers.
Future<void> bootstrap({
  required ProviderContainer container,
  required Env env,
}) async {
  // PocketBase — always available
  final pb = PocketBase(env.pocketbaseUrl);
  container.updateOverrides(<Override>[
    pocketbaseProvider.overrideWithValue(pb),
  ]);

  // Firebase — optional
  if (env.firebaseApiKey.isNotEmpty) {
    try {
      final app = await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: env.firebaseApiKey,
          projectId: env.firebaseProjectId,
          appId: env.firebaseAppId,
        ),
      );
      container.updateOverrides(<Override>[
        firebaseAppProvider.overrideWithValue(app),
      ]);
      Observability.log('Firebase initialized: ${app.name}');
    } catch (e, stack) {
      Observability.recordError(e, stack);
    }
  } else {
    Observability.log('Firebase not configured — auth disabled.');
  }
}