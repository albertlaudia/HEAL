// HEAL — Force update check service.
//
// Reads a tiny "min version" manifest from the Next.js API gateway
// (https://heal.positiveness.club/api/heal/app-version) and compares
// the user's running version against it. If the running version is
// below the minimum required version, the app shows a blocking dialog
// with a store link.
//
// The manifest is server-controlled so we can push a critical security
// fix or migration without shipping a new app binary that bypasses it.
//
// JSON shape:
//   {
//     "min_version": "0.1.7",        // semver, the user MUST update
//     "latest_version": "0.1.8",     // for the "Update available" banner
//     "store_url_ios": "https://apps.apple.com/app/id1234567890",
//     "store_url_android": "https://play.google.com/store/apps/details?id=com.pclub.heal",
//     "release_notes": "..."          // shown in the dialog
//   }

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/env.dart';
import 'analytics_service.dart';

class AppVersionManifest {
  final String minVersion;
  final String latestVersion;
  final String storeUrlIos;
  final String storeUrlAndroid;
  final String releaseNotes;

  const AppVersionManifest({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrlIos,
    required this.storeUrlAndroid,
    this.releaseNotes = '',
  });

  factory AppVersionManifest.fromJson(Map<String, dynamic> json) =>
      AppVersionManifest(
        minVersion: (json['min_version'] ?? '0.0.0') as String,
        latestVersion: (json['latest_version'] ?? '0.0.0') as String,
        storeUrlIos: (json['store_url_ios'] ?? '') as String,
        storeUrlAndroid: (json['store_url_android'] ?? '') as String,
        releaseNotes: (json['release_notes'] ?? '') as String,
      );

  factory AppVersionManifest.fallback() => const AppVersionManifest(
        minVersion: '0.0.0',
        latestVersion: '0.0.0',
        storeUrlIos: 'https://apps.apple.com/app/id6751891860',
        storeUrlAndroid: 'https://play.google.com/store/apps/details?id=com.pclub.heal',
      );
}

enum UpdateState {
  ok,                   // running version is current
  softUpdateSuggested,  // a newer version exists but not required
  hardUpdateRequired,   // running version is below the minimum
  checkFailed,          // couldn't reach the server
}

class ForceUpdateService {
  ForceUpdateService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _dismissedKey = 'force_update_dismissed_v1';
  static const _softDismissedKey = 'force_update_soft_dismissed_v1';
  static const _lastCheckedKey = 'force_update_last_checked_ms_v1';

  /// Check the server for the current app version. Returns null if it
  /// can't reach the server (we treat that as "no update required").
  Future<AppVersionManifest?> fetch() async {
    try {
      final url = Uri.parse('${HealEnv.nextApiUrl}/app-version');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      return AppVersionManifest.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('ForceUpdateService.fetch failed: $e');
      }
      return null;
    }
  }

  /// Decide whether the user needs an update.
  Future<UpdateState> check() async {
    if (kIsWeb) return UpdateState.ok;
    final pkg = await PackageInfo.fromPlatform();
    final running = '${pkg.version}+${pkg.buildNumber}';
    final manifest = await fetch();
    await _recordChecked();
    if (manifest == null) return UpdateState.checkFailed;

    final cmpMin = _compareSemver(pkg.version, manifest.minVersion);
    if (cmpMin < 0) {
      // Below the minimum — but check if the user already dismissed.
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_dismissedKey) ?? '';
      if (dismissed == manifest.minVersion) return UpdateState.ok;
      return UpdateState.hardUpdateRequired;
    }
    final cmpLatest = _compareSemver(pkg.version, manifest.latestVersion);
    if (cmpLatest < 0) {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_softDismissedKey) ?? '';
      if (dismissed == manifest.latestVersion) return UpdateState.ok;
      return UpdateState.softUpdateSuggested;
    }
    return UpdateState.ok;
  }

  /// Persist the user's "I see this" decision for the given version.
  Future<void> markHardDismissed(String minVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, minVersion);
  }

  Future<void> markSoftDismissed(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_softDismissedKey, latestVersion);
  }

  Future<void> _recordChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Open the appropriate store for the user's platform.
  Future<void> openStore(AppVersionManifest m) async {
    final url = (Platform.isAndroid ? m.storeUrlAndroid : m.storeUrlIos);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Compare two semver strings (X.Y.Z). Returns -1, 0, or 1.
  /// Tolerant of build suffixes (`+1`) and pre-release tags (`-beta.1`).
  static int _compareSemver(String a, String b) {
    final pa = a.split(RegExp(r'[+-]'))[0].split('.').map(int.tryParse).toList();
    final pb = b.split(RegExp(r'[+-]'))[0].split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final ai = i < pa.length ? (pa[i] ?? 0) : 0;
      final bi = i < pb.length ? (pb[i] ?? 0) : 0;
      if (ai < bi) return -1;
      if (ai > bi) return 1;
    }
    return 0;
  }

  void dispose() => _client.close();
}

final forceUpdateServiceProvider = Provider<ForceUpdateService>((ref) {
  final svc = ForceUpdateService();
  ref.onDispose(svc.dispose);
  return svc;
});
