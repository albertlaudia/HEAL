// HEAL — Force update dialog.
//
// Shown when the running app version is below the server-side minimum.
// Hard update = blocking (only the "Update" button is enabled).
// Soft update = dismissible banner with a single CTA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/force_update_service.dart';

class ForceUpdateDialog extends ConsumerWidget {
  const ForceUpdateDialog({
    super.key,
    required this.manifest,
    required this.hard,
  });
  final AppVersionManifest manifest;
  final bool hard;

  static Future<void> show(
    BuildContext context, {
    required AppVersionManifest manifest,
    required bool hard,
  }) async {
    final analytics = ProviderScope.containerOf(context, listen: false)
        .read(analyticsServiceProvider);
    unawaited(analytics.log(AnalyticsEvent(HealEvents.forceUpdateShown, params: {
      'hard': hard,
      'min_version': manifest.minVersion,
    })));
    return showDialog<void>(
      context: context,
      barrierDismissible: !hard,
      builder: (_) => ForceUpdateDialog(manifest: manifest, hard: hard),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(forceUpdateServiceProvider);
    return AlertDialog(
      backgroundColor: HealTokens.rosewood,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HealTokens.r24),
      ),
      title: Text(
        hard ? 'A new HEAL is here' : 'Update available',
        style: const TextStyle(color: HealTokens.cream, fontWeight: FontWeight.w500),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hard)
            const Text(
              'This version of HEAL needs to be updated before you can keep practicing. It only takes a moment.',
              style: TextStyle(color: HealTokens.creamDim, height: 1.5),
            )
          else
            const Text(
              'A new version of HEAL is available. It has small fixes and improvements.',
              style: TextStyle(color: HealTokens.creamDim, height: 1.5),
            ),
          if (manifest.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: HealTokens.s12),
            Text(
              manifest.releaseNotes,
              style: const TextStyle(
                color: HealTokens.creamDim,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!hard)
          TextButton(
            onPressed: () async {
              await svc.markSoftDismissed(manifest.latestVersion);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Later',
                style: TextStyle(color: HealTokens.creamDim)),
          ),
        FilledButton(
          onPressed: () async {
            final analytics = ref.read(analyticsServiceProvider);
            unawaited(analytics.log(AnalyticsEvent(
              HealEvents.forceUpdateAccepted,
              params: {'hard': hard},
            )));
            await svc.openStore(manifest);
          },
          style: FilledButton.styleFrom(backgroundColor: HealTokens.brass),
          child: Text(
            hard ? 'Update' : 'Update now',
            style: const TextStyle(color: HealTokens.oxblood, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
