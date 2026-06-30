// HEAL — Root app widget.
// Material 3 with custom theme + GoRouter.
// On first launch, shows onboarding after splash.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
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
    Timer(const Duration(milliseconds: 2200), () {
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
        // Wrap with overlay for splash + onboarding
        return Stack(
          children: [
            child ?? const SizedBox(),
            if (_showSplash)
              const Material(
                color: Colors.transparent,
                child: SplashPage(),
              ),
          ],
        );
      },
    );
  }
}