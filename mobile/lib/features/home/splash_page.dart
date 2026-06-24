// Splash — quiet first impression, transitions to home after 1.4s.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'HEAL',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w300),
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 12),
            Text(
              'a quiet practice',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
