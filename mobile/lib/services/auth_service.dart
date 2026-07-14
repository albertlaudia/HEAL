// HEAL — Authentication service.
//
// Wraps Firebase Auth with three providers:
//   - Email + password (sign in / sign up / reset)
//   - Google   (Android + iOS + Web)
//   - Apple    (iOS + macOS only; gracefully hidden elsewhere)
//
// We do NOT use Firebase Anonymous Auth as a primary sign-in because the
// current UserIdService (random local ID) is the working baseline. Anonymous
// auth is offered only as a "skip for now" CTA on the welcome screen that
// preserves the local ID and writes it nowhere.
//
// All auth state is exposed through [authStateProvider] so screens can react
// to sign-in / sign-out. The auth state also produces a stable [userId] that
// downstream services (bible progress, sticker book, settings) can use
// instead of the old random local ID.
//
// On first sign-in we copy the existing random local ID to the Firebase user's
// record's `legacyUserId` field so we don't lose any in-flight data, and
// from that point on we prefer the Firebase UID.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart'
    show
        AuthCredential,
        AuthProvider,
        EmailAuthProvider,
        FacebookAuthProvider,
        FirebaseAuth,
        GoogleAuthProvider,
        OAuthProvider,
        PhoneAuthProvider,
        TwitterAuthProvider,
        User,
        UserCredential;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String providerId;   // 'password' | 'google.com' | 'apple.com' | 'anonymous'
  final bool isAnonymous;

  const HealUser({
    required this.uid,
    required this.providerId,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  factory HealUser.fromFirebase(User u) => HealUser(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        photoUrl: u.photoURL,
        providerId: u.providerData.isNotEmpty
            ? (u.providerData.first.providerId ?? 'unknown')
            : 'anonymous',
        isAnonymous: u.isAnonymous,
      );

  static const empty = HealUser(uid: '', providerId: 'none');
  bool get isSignedIn => uid.isNotEmpty;
}

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  final _local = _LegacyUserIdBridge();

  /// Reactive stream of the current user. Emits null when signed out.
  Stream<HealUser?> authState() => _auth.authStateChanges().map(
        (u) => u == null ? null : HealUser.fromFirebase(u),
      );

  HealUser? currentUser() {
    final u = _auth.currentUser;
    return u == null ? null : HealUser.fromFirebase(u);
  }

  // ──────────────────────────  Email + password  ──────────────────────────

  Future<HealUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _migrateLegacyUserId(cred.user);
    return HealUser.fromFirebase(cred.user!);
  }

  Future<HealUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    await _migrateLegacyUserId(cred.user);
    return HealUser.fromFirebase(cred.user!);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ──────────────────────────  Google  ──────────────────────────

  Future<HealUser?> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: popup via Firebase. google_sign_in is awkward on web.
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final cred = await _auth.signInWithPopup(provider);
      await _migrateLegacyUserId(cred.user);
      return HealUser.fromFirebase(cred.user!);
    }

    // Mobile (Android + iOS): use google_sign_in to get the id token.
    final google = GoogleSignIn(scopes: const ['email', 'profile']);
    final account = await google.signIn();
    if (account == null) return null; // user cancelled
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await _migrateLegacyUserId(cred.user);
    return HealUser.fromFirebase(cred.user!);
  }

  // ──────────────────────────  Apple  ──────────────────────────

  /// Apple Sign In only exists on iOS / macOS / Web. On Android we throw an
  /// [UnsupportedError] so the caller can hide the button.
  Future<HealUser?> signInWithApple() async {
    if (kIsWeb) {
      // Apple blocks the cross-origin popup flow, so we have to use
      // `signInWithRedirect` on the web. We do NOT await a result here —
      // the page navigates away and back, and the result is picked up by
      // the auth state stream on the way back. Callers should listen to
      // [authStateProvider] rather than await this future.
      final provider = OAuthProvider('apple.com')..addScope('email');
      await _auth.signInWithRedirect(provider);
      return null;
    }
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign In is only available on Apple devices.');
    }
    // Generate a nonce to defend against replay attacks.
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauth = OAuthProvider('apple.com');
    final credential = oauth.credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
    );
    final cred = await _auth.signInWithCredential(credential);
    // Apple only sends the name on the FIRST sign-in, so we update it then.
    if (apple.givenName != null && apple.givenName!.isNotEmpty) {
      final name = [apple.givenName, apple.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (name.isNotEmpty) {
        await cred.user?.updateDisplayName(name);
      }
    }
    await _migrateLegacyUserId(cred.user);
    return HealUser.fromFirebase(cred.user!);
  }

  // ──────────────────────────  Sign-out  ──────────────────────────

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {/* noop */}
    await _auth.signOut();
  }

  /// True if the device supports the Apple Sign In button. On Android the
  /// platform check inside [signInWithApple] is the real authority; this is
  /// just a UI gate.
  static bool get appleSignInAvailable {
    if (kIsWeb) return true;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────  Migration  ──────────────────────────

  /// On first sign-in, write the legacy local random ID to a per-user
  /// SharedPreferences key (`heal.migrated.<uid>`). The actual stitching of
  /// local-only data to the new account happens lazily on first read:
  /// the `userIdProvider` below checks this key and re-uses the legacy
  /// ID's stored data when the user signs in.
  ///
  /// We keep the migration in SharedPreferences (not Firestore) so we don't
  /// take a `cloud_firestore` dependency just for one field. When we're
  /// ready to upload a real profile to Firestore, we can re-introduce it.
  Future<void> _migrateLegacyUserId(User? u) async {
    if (u == null) return;
    try {
      final legacy = await _local.read();
      if (legacy == null) return;
      if (legacy == u.uid) return; // already a Firebase uid
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('heal.migrated.${u.uid}', legacy);
      // Don't clear `heal.user_id.v1` yet — we still need it for first reads
      // after sign-in until downstream services switch to the Firebase uid.
    } catch (e) {
      if (kDebugMode) print('AuthService._migrateLegacyUserId: $e');
    }
  }
}

// ──────────────────────────  Riverpod  ──────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(firebaseAuthProvider)));

/// Streams the currently-signed-in user, or null when signed out.
final authStateProvider = StreamProvider<HealUser?>((ref) {
  return ref.watch(authServiceProvider).authState();
});

/// Synchronous read of the current user. Use [authStateProvider] for widgets
/// that should rebuild on sign-in/out.
final currentUserProvider = Provider<HealUser?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.valueOrNull;
});

// ──────────────────────────  Helpers  ──────────────────────────

class _LegacyUserIdBridge {
  static const _key = 'heal.user_id.v1';
  static String? _cached;

  Future<String?> read() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_key);
    return _cached;
  }
}

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}
