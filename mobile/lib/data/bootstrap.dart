// App bootstrap — initializes PocketBase, Firebase, and audio context.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../core/env.dart';
import '../core/observability.dart';

/// Provider for the shared PocketBase client.
final pocketbaseProvider = Provider<PocketBase>((ref) {
  throw UnimplementedError('Override in bootstrap()');
});

/// Provider for the shared Firebase app.
final firebaseAppProvider = Provider<FirebaseApp>((ref) {
  throw UnimplementedError('Override in bootstrap()');
});

/// Provider for the shared Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

Future<void> bootstrap({
  required ProviderContainer container,
  required Env env,
}) async {
  // PocketBase
  container.updateOverrides(<Override>[
    pocketbaseProvider.overrideWithValue(PocketBase(env.pocketbaseUrl)),
  ]);

  // Firebase (optional — only if API key is set)
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
    } catch (e, stack) {
      Observability.recordError(e, stack);
    }
  } else {
    Observability.log('Firebase not configured — auth disabled.');
  }
}
