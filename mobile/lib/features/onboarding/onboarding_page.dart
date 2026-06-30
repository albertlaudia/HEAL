// HEAL — Onboarding flow.
// 3 pages with horizontal swipe, smooth_page_indicator dots.
// Final page requests notification permission.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';
import '../../services/notification_service.dart';

class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState<int>(0);

    final pages = [
      const _OnboardingPage(
        icon: Icons.spa_outlined,
        title: 'A quiet place\nto be still',
        body: 'Five minutes of scripture, breath, and prayer.\nFor the hurried and the weary.',
        color: HealTokens.brass,
      ),
      const _OnboardingPage(
        icon: Icons.cloud_outlined,
        title: 'No tracking.\nNo noise.',
        body: 'Your practice is yours. No ads, no analytics, no accounts required.',
        color: HealTokens.amber,
      ),
      const _OnboardingPage(
        icon: Icons.notifications_active_outlined,
        title: 'A gentle\nreminder',
        body: 'We can nudge you at sunrise and sunset. Or never. Your choice.',
        color: HealTokens.bronzeLight,
        cta: 'CONTINUE',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: pages.length,
              onPageChanged: (i) => currentPage.value = i,
              itemBuilder: (context, i) => pages[i],
            ),
            // Skip button
            Positioned(
              top: HealTokens.s16,
              right: HealTokens.s20,
              child: currentPage.value < pages.length - 1
                  ? TextButton(
                      onPressed: () async {
                        await _completeOnboarding();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('SKIP'),
                    )
                  : const SizedBox.shrink(),
            ),
            // Page indicator
            Positioned(
              bottom: HealTokens.s96,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: pageController,
                  count: pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: HealTokens.brass,
                    dotColor: HealTokens.creamDim.withValues(alpha: 0.24),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 8,
                  ),
                ),
              ),
            ),
            // CTA button
            Positioned(
              bottom: HealTokens.s48,
              left: HealTokens.s24,
              right: HealTokens.s24,
              child: AnimatedOpacity(
                opacity: currentPage.value == pages.length - 1 ? 1 : 0.3,
                duration: HealTokens.d300,
                child: FilledButton(
                  onPressed: currentPage.value == pages.length - 1
                      ? () async {
                          HapticFeedback.mediumImpact();
                          // Request notification permission
                          await ref.read(notificationServiceProvider).requestPermission();
                          // Mark onboarding complete
                          await _completeOnboarding();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
                  child: Text(pages.last.cta ?? 'CONTINUE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final String? cta;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HealTokens.s40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: HealTokens.s40),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: HealTokens.cream,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: HealTokens.s24),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: HealTokens.creamDim,
                  height: 1.6,
                ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}