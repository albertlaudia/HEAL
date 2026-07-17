// HEAL — Force update guard.
//
// Invisible widget that, on mount, reads the cached force-update state
// and shows a dialog if a hard/soft update is required. Mounts once at
// the app root and then self-removes for the rest of the session.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../features/settings/force_update_dialog.dart';
import '../services/force_update_service.dart';

class ForceUpdateGuard extends ConsumerStatefulWidget {
  const ForceUpdateGuard({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ForceUpdateGuard> createState() => _ForceUpdateGuardState();
}

class _ForceUpdateGuardState extends ConsumerState<ForceUpdateGuard> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShow());
  }

  Future<void> _checkAndShow() async {
    if (_checked) return;
    _checked = true;
    final prefs = await SharedPreferences.getInstance();
    final stateName = prefs.getString('force_update_state_v1');
    if (stateName == null) return;
    final state = UpdateState.values.firstWhere(
      (e) => e.name == stateName,
      orElse: () => UpdateState.ok,
    );
    if (state == UpdateState.ok || state == UpdateState.checkFailed) return;
    if (!mounted) return;
    // Read the manifest that main.dart cached.
    final raw = prefs.getString('force_update_manifest_v1');
    if (raw == null) return;
    final parts = raw.split('|');
    if (parts.length < 2) return;
    final manifest = AppVersionManifest(
      minVersion: parts[0],
      latestVersion: parts[1],
      storeUrlIos: 'https://apps.apple.com/app/id6751891860',
      storeUrlAndroid: 'https://play.google.com/store/apps/details?id=com.pclub.heal',
    );
    final hard = state == UpdateState.hardUpdateRequired;
    // Defer the dialog until after this frame so the MaterialApp is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ForceUpdateDialog.show(context, manifest: manifest, hard: hard);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Re-export HealTokens for build tools that need to color the guard.
const _kRosewood = HealTokens.rosewood;
