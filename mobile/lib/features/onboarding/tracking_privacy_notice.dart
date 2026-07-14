// HEAL — Tracking privacy notice.
//
// iOS 14+ requires apps that declare `NSUserTrackingUsageDescription` in
// their Info.plist to either:
//   (a) call `AppTrackingTransparency.requestTrackingAuthorization()` so
//       the system shows the prompt, or
//   (b) clearly disclose to the user that the app does not track.
//
// HEAL does NOT track users across apps or websites. We declare
// `NSUserTrackingUsageDescription` only because the App Store policy
// requires it for any future feature that might want to track. Today,
// no tracking occurs, and we never call ATTrackingManager.
//
// This notice is shown ONCE, on first launch (before the first breath).
// After acknowledging it, we set a SharedPreferences flag and never
// show it again.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../design/pressable.dart';

class TrackingPrivacyNotice extends ConsumerStatefulWidget {
  final Widget child;
  const TrackingPrivacyNotice({super.key, required this.child});

  static const _flag = 'heal.tracking_notice_ack.v1';

  static Future<bool> hasAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_flag) ?? false;
  }

  static Future<void> acknowledge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flag, true);
  }

  @override
  ConsumerState<TrackingPrivacyNotice> createState() =>
      _TrackingPrivacyNoticeState();
}

class _TrackingPrivacyNoticeState extends ConsumerState<TrackingPrivacyNotice> {
  bool? _showNotice;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ack = await TrackingPrivacyNotice.hasAcknowledged();
    if (mounted) setState(() => _showNotice = !ack);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showNotice == true) _Notice(onAck: _acknowledge),
      ],
    );
  }

  Future<void> _acknowledge() async {
    await TrackingPrivacyNotice.acknowledge();
    if (mounted) setState(() => _showNotice = false);
  }
}

class _Notice extends StatelessWidget {
  final Future<void> Function() onAck;
  const _Notice({required this.onAck});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HealTokens.rosewood,
                borderRadius: BorderRadius.circular(HealTokens.r20),
                border: Border.all(
                  color: HealTokens.brass.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: HealTokens.brass.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: HealTokens.brass,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A word on privacy',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: HealTokens.cream),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'HEAL does not track you across apps or websites. '
                    'There are no ads. There is no analytics that follows '
                    'you off this device.\n\n'
                    'Your practice data — streaks, favorites, and your breath '
                    'profile — stays on your device. If you sign in, your '
                    'progress syncs to your own account.\n\n'
                    'You can read the full policy in Settings → About → Privacy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HealTokens.cream.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Pressable(
                    onTap: onAck,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        color: HealTokens.brass,
                        borderRadius: BorderRadius.circular(HealTokens.r16),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: HealTokens.rosewoodDeep,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
