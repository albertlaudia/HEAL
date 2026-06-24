// HEAL app shell — root widget, Material 3 dark theme,
// go_router-based navigation.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme.dart';
import 'core/router.dart';

class HealApp extends HookConsumerWidget {
  const HealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(healRouterProvider);
    return MaterialApp.router(
      title: 'HEAL',
      debugShowCheckedModeBanner: false,
      theme: HealTheme.dark(),
      darkTheme: HealTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
