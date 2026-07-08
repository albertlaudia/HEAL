// HEAL — PermissionGate.
//
// Fires the notification permission ask AFTER the first completed session.
// Reasoning: per Calm/Headspace benchmarks, asking permission before value
// delivery leads to ~60% opt-out. Asking after the user has felt the
// product raises opt-in to ~70%+.
//
// Usage: wrap the home shell with PermissionGate. The gate reads
// `ask_notifications_after_first_session` and shows a soft modal
// (not the OS dialog directly — the modal frames the ask first).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../services/notification_service.dart';

class PermissionGate extends StatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _shownThisSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wait until first session is complete; check on every rebuild but
    // only show once per session.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  Future<void> _maybeAsk() async {
    if (_shownThisSession) return;
    final prefs = await SharedPreferences.getInstance();
    final completedSessions = prefs.getInt('total_sessions') ?? 0;
    final shouldAsk = prefs.getBool('ask_notifications_after_first_session') ?? false;
    final alreadyAsked = prefs.getBool('notification_permission_asked') ?? false;
    // Only ask AFTER the first completed session, and only once.
    if (!shouldAsk || alreadyAsked || completedSessions < 1) return;
    _shownThisSession = true;
    await _showSoftModal();
    await prefs.setBool('notification_permission_asked', true);
    await prefs.setBool('ask_notifications_after_first_session', false);
  }

  Future<void> _showSoftModal() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            HealTokens.s24, HealTokens.s16, HealTokens.s24, HealTokens.s40,
          ),
          decoration: const BoxDecoration(
            color: HealTokens.rosewood,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(HealTokens.r28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: HealTokens.creamDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: HealTokens.s24),
              const Icon(
                Icons.notifications_none_rounded,
                color: HealTokens.brass,
                size: 36,
              ),
              const SizedBox(height: HealTokens.s16),
              const Text(
                'A gentle nudge?',
                style: TextStyle(
                  color: HealTokens.cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: HealTokens.s12),
              const Text(
                'Tomorrow morning at 7am, we\'ll quietly remind you to come back. That\'s it — once a day, never twice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HealTokens.creamDim,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: HealTokens.s24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'No thanks',
                        style: TextStyle(color: HealTokens.creamDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: HealTokens.s12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HealTokens.brass,
                        foregroundColor: HealTokens.oxblood,
                        padding: const EdgeInsets.symmetric(vertical: HealTokens.s16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HealTokens.r12),
                        ),
                      ),
                      child: const Text(
                        'Yes, once a day',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == true) {
      // User opted in — request OS permission
      await NotificationService.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
