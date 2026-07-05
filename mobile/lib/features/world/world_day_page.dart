// HEAL — World Day page.
// Reader for a single HEAL_world record (the "world, today" piece).
// Used by both /world/:slug deep links and the Today card on home.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../data/pb_models.dart';
import '../../data/pb_repositories.dart';

class WorldDayPage extends HookConsumerWidget {
  final String slug;
  const WorldDayPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWorld = ref.watch(_worldBySlugProvider(slug));
    final palette    = ref.watch(timePaletteProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'The world, today',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: HealTokens.cream,
                letterSpacing: 2.0,
              ),
        ),
      ),
      body: asyncWorld.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: palette.primary, strokeWidth: 1.2),
        ),
        error: (e, _) => Center(
          child: Text('Could not load.', style: TextStyle(color: HealTokens.creamDim)),
        ),
        data: (world) {
          if (world == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_off_rounded, color: HealTokens.creamDim, size: 48),
                  const SizedBox(height: 12),
                  Text('No piece for $slug yet.', style: TextStyle(color: HealTokens.creamDim)),
                ],
              ),
            );
          }
          return _WorldBody(world: world, palette: palette);
        },
      ),
    );
  }
}

class _WorldBody extends StatelessWidget {
  final WorldDay world;
  final TimePalette palette;
  const _WorldBody({required this.world, required this.palette});

  Color _kindBg() {
    switch (world.promptKind) {
      case 'challenge': return const Color(0xFF1F3A40);  // deep teal-blue
      case 'grace':     return const Color(0xFF1F3328);  // deep sage
      case 'gratitude': return const Color(0xFF3D2E1A);  // deep amber
      default:          return const Color(0xFF2A2A2A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          HealTokens.s24, HealTokens.s16, HealTokens.s24, HealTokens.s40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: HealTokens.s12,
                vertical: HealTokens.s4,
              ),
              decoration: BoxDecoration(
                color: _kindBg(),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                (world.promptKind ?? 'today').toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: HealTokens.s16),

            Text(
              world.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: HealTokens.cream,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                  ),
            ),
            const SizedBox(height: HealTokens.s8),
            if (world.publishedAt != null)
              Text(
                _formatDate(world.publishedAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HealTokens.creamDim,
                      fontStyle: FontStyle.italic,
                    ),
              ),

            const SizedBox(height: HealTokens.s32),

            // In the world today — prompt
            _SectionLabel(label: 'In the world today', palette: palette),
            const SizedBox(height: HealTokens.s8),
            Text(
              world.prompt,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HealTokens.cream,
                    height: 1.55,
                  ),
            ),

            const SizedBox(height: HealTokens.s32),

            // Scripture
            if (world.scriptureRef != null && world.scriptureRef!.isNotEmpty) ...[
              _SectionLabel(label: 'What the Bible says', palette: palette),
              const SizedBox(height: HealTokens.s12),
              Container(
                padding: const EdgeInsets.all(HealTokens.s20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(HealTokens.r16),
                  border: Border.all(color: palette.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${world.scriptureText ?? ''}”',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: HealTokens.cream,
                            height: 1.55,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '— ${world.scriptureRef}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HealTokens.creamDim,
                            letterSpacing: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HealTokens.s32),
            ],

            // Reflection
            _SectionLabel(label: 'A reflection', palette: palette),
            const SizedBox(height: HealTokens.s8),
            Text(
              world.reflection,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HealTokens.cream,
                    height: 1.6,
                  ),
            ),

            const SizedBox(height: HealTokens.s32),

            // Prayer
            _SectionLabel(label: 'A prayer', palette: palette),
            const SizedBox(height: HealTokens.s12),
            Container(
              padding: const EdgeInsets.all(HealTokens.s20),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(HealTokens.r16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                world.prayer,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HealTokens.cream,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),

            const SizedBox(height: HealTokens.s32),

            // Expectation
            _SectionLabel(label: 'What we could expect', palette: palette),
            const SizedBox(height: HealTokens.s8),
            Text(
              world.expectation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HealTokens.cream,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final TimePalette palette;
  const _SectionLabel({required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 24, height: 1, color: palette.primary),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

/// Provider for a single world day by slug.
final _worldBySlugProvider = FutureProvider.family<WorldDay?, String>((ref, slug) async {
  return ref.watch(worldRepoProvider).recent(limit: 60).then((days) {
    try {
      return days.firstWhere((w) => w.slug == slug);
    } catch (_) {
      return null;
    }
  });
});
