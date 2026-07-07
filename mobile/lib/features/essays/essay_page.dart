// HEAL — Reflections reader (longer-form essays).
// PageView with horizontal swipe between articles. Generous typography.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../data/pb_repositories.dart';
import '../../data/pb_models.dart';

class EssayPage extends HookConsumerWidget {
  const EssayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final essaysAsync = ref.watch(essaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reflections')),
      body: essaysAsync.when(
        data: (essays) {
          if (essays.isEmpty) {
            return const Center(
              child: Text('No reflections yet.', style: TextStyle(color: HealTokens.creamDim)),
            );
          }
          return PageView.builder(
            itemCount: essays.length,
            itemBuilder: (context, i) {
              return _EssayReader(essay: essays[i]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
      ),
    );
  }
}

final essaysProvider = FutureProvider<List<Essay>>((ref) {
  return ref.read(essayRepoProvider).list();
});

class _EssayReader extends StatelessWidget {
  final Essay essay;
  const _EssayReader({required this.essay});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HealTokens.s24,
        HealTokens.s8,
        HealTokens.s24,
        HealTokens.s64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero illustration
          ClipRRect(
            borderRadius: BorderRadius.circular(HealTokens.r20),
            child: CachedNetworkImage(
              imageUrl: essay.cdnIllustration,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: HealTokens.rosewoodLight,
                height: 240,
              ),
              errorWidget: (_, __, ___) => Container(
                color: HealTokens.rosewoodLight,
                height: 240,
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, color: HealTokens.brass, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: HealTokens.s24),
          Text(
            essay.subtitle.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: HealTokens.brass,
                  letterSpacing: 2.0,
                ),
          ),
          const SizedBox(height: HealTokens.s8),
          Text(
            essay.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: HealTokens.cream,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: HealTokens.s8),
          Text(
            '${essay.readMinutes} min read',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HealTokens.creamDim,
                ),
          ),
          const SizedBox(height: HealTokens.s32),
          // Body
          Text(
            essay.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: HealTokens.cream,
                  height: 1.8,
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: HealTokens.s48),
          // Footer
          Row(
            children: [
              Container(width: 32, height: 1, color: HealTokens.brass),
              const SizedBox(width: HealTokens.s12),
              Text(
                'SWIPE TO READ MORE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HealTokens.creamDim,
                      letterSpacing: 2.0,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}