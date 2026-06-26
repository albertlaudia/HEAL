// HEAL — Settings page.
// Toggle notifications (morning/evening), haptic strength, sign-in, about.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../services/notification_service.dart';
import '../../services/voice_calibration_service.dart';

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
    final eveningEnabled = useState<bool>(true);
    final hapticsEnabled = useState<bool>(true);

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
                    activeColor: HealTokens.brass,
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
                  const Divider(height: 1, color: Color(0xFF3A201C)),
                  _SettingTile(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Morning reminder',
                    subtitle: 'Around 7:00 AM',
                    trailing: Switch(
                      value: morningEnabled.value,
                      activeColor: HealTokens.brass,
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
                  const Divider(height: 1, color: Color(0xFF3A201C)),
                  _SettingTile(
                    icon: Icons.nights_stay_outlined,
                    title: 'Evening reminder',
                    subtitle: 'Around 9:00 PM',
                    trailing: Switch(
                      value: eveningEnabled.value,
                      activeColor: HealTokens.brass,
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
                const Divider(height: 1, color: Color(0xFF3A201C)),
                _SettingTile(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic feedback',
                  subtitle: 'Gentle taps on breath transitions',
                  trailing: Switch(
                    value: hapticsEnabled.value,
                    activeColor: HealTokens.brass,
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
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Sign in',
                  subtitle: 'Save your practice across devices',
                  onTap: () {},
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
                const Divider(height: 1, color: Color(0xFF3A201C)),
                _SettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  subtitle: 'No tracking. No ads. Your data stays yours.',
                  onTap: () {},
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
    evening.value = prefs.getBool('notif_evening_enabled') ?? true;
    haptics.value = prefs.getBool('haptics_enabled') ?? true;
  }

  Future<void> _saveNotif(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
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
          ],
        ),
      ),
    );
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