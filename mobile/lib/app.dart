// HEAL — Root app widget.
// Material 3 with custom theme + GoRouter.
// On first launch, shows onboarding after splash.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'design/audio_error_banner.dart';
import 'design/error_boundary.dart';
import 'design/motion.dart';
import 'features/onboarding/permission_gate.dart';
import 'features/onboarding/tracking_privacy_notice.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/home/splash_page.dart';

class HealApp extends ConsumerStatefulWidget {
  final bool firstLaunch;
  const HealApp({super.key, this.firstLaunch = false});

  @override
  ConsumerState<HealApp> createState() => _HealAppState();
}

class _HealAppState extends ConsumerState<HealApp> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.firstLaunch;
    Timer(HealMotion.splashMin, () {
      if (mounted) {
        setState(() => _showSplash = false);
        // After splash, decide where to go — use addPostFrameCallback so the
        // GoRouter navigator is fully mounted before we attempt navigation.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_showOnboarding) {
            HealRouter.router.push('/onboarding');
          } else {
            HealRouter.router.go('/home');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HEAL',
      debugShowCheckedModeBanner: false,
      theme: HealTheme.dark,
      darkTheme: HealTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: HealRouter.router,
      builder: (context, child) {
        // Wrap with ErrorBoundary (reverent fallback if any child throws) +
        // PermissionGate (asks for notifications after first session) +
        // overlay for splash + onboarding.
        return ErrorBoundary(
          child: PermissionGate(
            child: AudioErrorListener(
              child: TrackingPrivacyNotice(
                child: Stack(
              children: [
                child ?? const SizedBox(),
                if (_showSplash)
                  const Material(
                    color: Colors.transparent,
                    child: SplashPage(),
                  ),
              ],
            ),
            ),
            ),
          ),
        );
      },
    );
  }
}