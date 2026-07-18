// HEAL — Settings page.
// Toggle notifications (morning/evening), haptic strength, sign-in, about.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/env.dart';
import '../../core/widgets/brass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_service.dart';
import '../../services/voice_calibration_service.dart';
import '../../services/streak_service.dart';
import '../../services/sticker_book.dart';
import '../../data/bible_progress_cache.dart';

final _voiceProfileProvider = Provider<bool>((ref) {
  final cal = ref.watch(voiceCalibrationServiceProvider);
  return cal.hasProfile;
});

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsEnabled = useState<bool>(false);
    final morningEnabled = useState<bool>(true);
    final eveningEnabled = useState<bool>(false);
    final hapticsEnabled = useState<bool>(true);
    final user = ref.watch(currentUserProvider);

    useEffect(() {
      _loadPrefs(notifsEnabled, morningEnabled, eveningEnabled, hapticsEnabled);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(HealTokens.s20),
        children: [
          const SectionHeader(title: 'Practice'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Daily reminders',
                  subtitle: 'A gentle nudge to practice',
                  trailing: Switch(
                    value: notifsEnabled.value,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return HealTokens.brass;
                      return null;
                    }),
                    onChanged: (v) async {
                      notifsEnabled.value = v;
                      final svc = ref.read(notificationServiceProvider);
                      if (v) {
                        await svc.enable(
                          morning: morningEnabled.value,
                          evening: eveningEnabled.value,
                        );
                      } else {
                        await svc.disable();
                      }
                      await _saveNotif(v);
                    },
                  ),
                ),
                if (notifsEnabled.value) ...[
                  const Divider(height: 1, color: HealTokens.rosewoodLight),
                  _SettingTile(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Morning reminder',
                    subtitle: 'Around 7:00 AM',
                    trailing: Switch(
                      value: morningEnabled.value,
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return HealTokens.brass;
                        return null;
                      }),
                      onChanged: (v) async {
                        morningEnabled.value = v;
                        if (notifsEnabled.value) {
                          await ref.read(notificationServiceProvider).enable(
                                morning: v,
                                evening: eveningEnabled.value,
                              );
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1, color: HealTokens.rosewoodLight),
                  _SettingTile(
                    icon: Icons.nights_stay_outlined,
                    title: 'Evening reminder',
                    subtitle: 'Around 9:00 PM',
                    trailing: Switch(
                      value: eveningEnabled.value,
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return HealTokens.brass;
                        return null;
                      }),
                      onChanged: (v) async {
                        eveningEnabled.value = v;
                        if (notifsEnabled.value) {
                          await ref.read(notificationServiceProvider).enable(
                                morning: morningEnabled.value,
                                evening: v,
                              );
                        }
                      },
                    ),
                  ),
                ],
                const Divider(height: 1, color: HealTokens.rosewoodLight),
                _SettingTile(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic feedback',
                  subtitle: 'Gentle taps on breath transitions',
                  trailing: Switch(
                    value: hapticsEnabled.value,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return HealTokens.brass;
                      return null;
                    }),
                    onChanged: (v) async {
                      hapticsEnabled.value = v;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('haptics_enabled', v);
                      if (v) HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: HealTokens.s32),
          const SectionHeader(title: 'Personal'),
          Consumer(
            builder: (context, ref, _) {
              final hasProfile = ref.watch(
                  _voiceProfileProvider);
              return GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.record_voice_over_rounded,
                      title: hasProfile ? 'Breath profile' : 'Calibrate breath',
                      subtitle: hasProfile
                          ? 'HEAL paces to your natural rhythm'
                          : '30 seconds · teach HEAL your pace',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/breathe/calibrate');
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: HealTokens.s32),
          const SectionHeader(title: 'Account'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (user != null && user.isSignedIn) ...[
                  _SignedInTile(
                    user: user,
                    onSignOut: () async {
                      HapticFeedback.selectionClick();
                      await ref.read(authServiceProvider).signOut();
                    },
                    onManage: () => context.push('/auth'),
                  ),
                ] else
                  _SettingTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Sign in',
                    subtitle: 'Save your practice across devices',
                    onTap: () => context.push('/auth'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: HealTokens.s32),
          const SectionHeader(title: 'Re-orient'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.replay_rounded,
                  title: 'Replay welcome tour',
                  subtitle: 'See how HEAL works, from the beginning',
                  onTap: () => _replayOnboarding(context, ref),
                ),
                const Divider(height: 1, color: HealTokens.rosewoodLight),
                _SettingTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Reset HEAL',
                  subtitle: 'Clear all practice history on this device',
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: HealTokens.s32),
          const SectionHeader(title: 'About'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About HEAL',
                  subtitle: 'A quiet Christian mindfulness practice',
                  onTap: () => _showAbout(context),
                ),
                const Divider(height: 1, color: HealTokens.rosewoodLight),
                _SettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  subtitle: 'No tracking. No ads. Your data stays yours.',
                  onTap: () => _openPrivacyPolicy(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: HealTokens.s48),
          Center(
            child: Text(
              'HEAL · v0.1.0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: HealTokens.creamDim,
                    letterSpacing: 2.0,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPrefs(
    ValueNotifier<bool> notifs,
    ValueNotifier<bool> morning,
    ValueNotifier<bool> evening,
    ValueNotifier<bool> haptics,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    notifs.value = prefs.getBool('notifications_enabled') ?? false;
    morning.value = prefs.getBool('notif_morning_enabled') ?? true;
    evening.value = prefs.getBool('notif_evening_enabled') ?? false;
    haptics.value = prefs.getBool('haptics_enabled') ?? true;
  }

  Future<void> _saveNotif(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
  }

  /// Show the onboarding flow again. Marks the user as not-onboarded
  /// and re-navigates to the welcome screen. Doesn't wipe any data.
  void _replayOnboarding(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    if (!context.mounted) return;
    // Pop everything and force the splash route to re-evaluate.
    context.go('/');
    unawaited(ref.read(analyticsServiceProvider).log(
      const AnalyticsEvent(HealEvents.onboardingReplay),
    ));
  }

  /// Confirmation dialog before wiping all local data. (Signed-in users
  /// keep their cloud-synced data — only the on-device cache is cleared.)
  /// After confirm: clear SharedPreferences, reset providers, log the user out.
  void _confirmReset(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HealTokens.rosewood,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealTokens.r24),
        ),
        title: Text('Reset HEAL?',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  color: HealTokens.cream,
                )),
        content: Text(
          'This clears your practice history, favorites, journal entries, '
          'and sticker book on this device. If you\'re signed in, your cloud '
          'data is preserved.\n\nThis can\'t be undone.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: HealTokens.creamDim,
                height: 1.5,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: HealTokens.creamDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset',
                style: TextStyle(color: HealTokens.brass)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await _performReset(context, ref);
  }

  /// The actual reset. Wipes all HEAL keys from SharedPreferences and
  /// re-hydrates the providers so the UI immediately reflects the
  /// empty state. Sign-out is preserved (we don't auto-sign-out the user
  /// — only local caches go).
  Future<void> _performReset(BuildContext context, WidgetRef ref) async {
    final analytics = ref.read(analyticsServiceProvider);
    unawaited(analytics.log(const AnalyticsEvent(HealEvents.resetHealTriggered)));
    final prefs = await SharedPreferences.getInstance();
    // Wipe every HEAL-namespaced key.
    final allKeys = prefs.getKeys().where((k) => k.startsWith('heal.')).toList();
    for (final k in allKeys) {
      await prefs.remove(k);
    }
    // Also wipe the inline keys that don't have the prefix.
    for (final k in const [
      'onboarding_complete',
      'notifications_enabled',
      'notif_morning_enabled',
      'notif_evening_enabled',
      'haptics_enabled',
      'selected_voice_profile',
      'force_update_dismissed_v1',
    ]) {
      await prefs.remove(k);
    }
    // Reset all in-memory providers.
    await ref.read(streakServiceProvider.notifier).load();
    await ref.read(stickerBookProvider.notifier).hydrate();
    ref.read(bibleProgressCacheProvider('').notifier).clear();
    unawaited(analytics.log(const AnalyticsEvent(HealEvents.resetHealCompleted)));
    if (!context.mounted) return;
    // Hop back to home so the user sees the "fresh HEAL" state.
    context.go('/');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: HealTokens.rosewood,
        content: Text('HEAL has been reset. Welcome back.',
            style: TextStyle(color: HealTokens.cream)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HealTokens.rosewood,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(HealTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: HealTokens.s24),
              decoration: BoxDecoration(
                color: HealTokens.creamDim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'HEAL',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: HealTokens.cream,
                    letterSpacing: 8,
                  ),
            ),
            const SizedBox(height: HealTokens.s16),
            Text(
              'A quiet Christian mindfulness practice.\n\n'
              'Five minutes of scripture, breath, and prayer. No tracking, no ads, no noise. Just a place to be still.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HealTokens.creamDim,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: HealTokens.s32),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text('Privacy policy'),
                  onPressed: () => _openLink(context, HealEnv.privacyPolicyUrl),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.support_outlined, size: 16),
                  label: const Text('Support'),
                  onPressed: () => _openLink(context, HealEnv.supportUrl),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.gavel_outlined, size: 16),
                  label: const Text('Terms'),
                  onPressed: () => _openLink(context, HealEnv.termsUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    await _openLink(context, HealEnv.privacyPolicyUrl);
  }
}

class _SignedInTile extends StatelessWidget {
  final HealUser user;
  final VoidCallback onSignOut;
  final VoidCallback onManage;
  const _SignedInTile({
    required this.user,
    required this.onSignOut,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName!
        : (user.email ?? 'Signed in');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HealTokens.s20,
        vertical: HealTokens.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle with the user's initial
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HealTokens.brass, HealTokens.brassLight],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: HealTokens.rosewoodDeep,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: HealTokens.cream,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email != null && user.email != name)
                      Text(
                        user.email!,
                        style: TextStyle(
                          color: HealTokens.creamDim.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'Signed in via ${_providerLabel(user.providerId)}',
                      style: const TextStyle(
                        color: HealTokens.brass,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Switch account'),
                onPressed: onManage,
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(foregroundColor: HealTokens.brass),
                onPressed: onSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _providerLabel(String id) {
    switch (id) {
      case 'google.com': return 'Google';
      case 'apple.com': return 'Apple';
      case 'password': return 'email + password';
      case 'anonymous': return 'guest';
      default: return id;
    }
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: HealTokens.brass),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HealTokens.s20,
        vertical: HealTokens.s4,
      ),
    );
  }
}