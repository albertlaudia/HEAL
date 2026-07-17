// HEAL — Mobile search page.
//
// Live search across all content types (meditations, praise, prayers,
// scriptures, essays, world). Uses the global SearchService.
//
// Features:
//   - Debounced input (250ms) to avoid hammering the API
//   - Result chips show the kind (Meditation/Praise/Prayer/Scripture/Essay/World)
//   - Tap a result to navigate to its detail page
//   - "Try a topic" suggestion chips on empty state
//   - Analytics logged (search + search_result_tap)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../services/analytics_service.dart';
import '../../services/search_service.dart';
import '../../services/activity_tracker.dart';

class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState<String>('');
    final results = useState<List<SearchResult>>([]);
    final isLoading = useState<bool>(false);
    final hasSearched = useState<bool>(false);

    // Debounce: 250ms after the user stops typing.
    useEffect(() {
      Timer? debounce;
      controller.addListener(() {
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 250), () {
          query.value = controller.text;
        });
      });
      return () => debounce?.cancel();
    }, [controller]);

    // Re-run search whenever the query changes.
    useEffect(() {
      final q = query.value.trim();
      if (q.isEmpty) {
        results.value = const [];
        isLoading.value = false;
        hasSearched.value = false;
        return null;
      }
      isLoading.value = true;
      hasSearched.value = true;
      final svc = ref.read(searchServiceProvider);
      svc.search(q).then((r) {
        if (!isMounted()) return;
        results.value = r;
        isLoading.value = false;
        unawaited(ref.read(activityTrackerProvider.notifier).log(
          'search',
          meta: {'query_length': q.length, 'result_count': r.length},
        ));
        unawaited(ref.read(analyticsServiceProvider).log(
          AnalyticsEvent(HealEvents.search, params: {
            'query_length': q.length,
            'result_count': r.length,
          }),
        ));
      }).catchError((_) {
        if (!isMounted()) return;
        results.value = const [];
        isLoading.value = false;
      });
      return null;
    }, [query.value]);

    bool isMounted() {
      try { return context.mounted; } catch (_) { return false; }
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HealTokens.cream,
              ),
          decoration: InputDecoration(
            hintText: 'Search scripture, prayer, praise…',
            hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HealTokens.creamDim.withValues(alpha: 0.5),
                ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded, color: HealTokens.brass),
            suffixIcon: query.value.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, color: HealTokens.creamDim),
                    onPressed: () {
                      controller.clear();
                      HapticFeedback.selectionClick();
                    },
                  ),
          ),
        ),
        backgroundColor: HealTokens.rosewood,
        iconTheme: const IconThemeData(color: HealTokens.cream),
      ),
      body: Container(
        color: HealTokens.oxblood,
        child: _buildBody(context, ref, query.value, results.value,
            isLoading.value, hasSearched.value, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    String query,
    List<SearchResult> results,
    bool isLoading,
    bool hasSearched,
    TextEditingController controller,
  ) {
    if (query.isEmpty) {
      return _emptyState(context, controller);
    }
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: HealTokens.brass),
      );
    }
    if (results.isEmpty) {
      return _noResults(context, query);
    }
    return _resultList(context, ref, results);
  }

  Widget _emptyState(BuildContext context, TextEditingController controller) {
    return ListView(
      padding: const EdgeInsets.all(HealTokens.s24),
      children: [
        Text(
          'Try a topic',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HealTokens.cream,
              ),
        ),
        const SizedBox(height: HealTokens.s16),
        Wrap(
          spacing: HealTokens.s12,
          runSpacing: HealTokens.s12,
          children: const [
            'peace', 'anxiety', 'gratitude', 'morning', 'sleep',
            'prayer', 'psalm 23', 'forgiveness', 'praise',
          ].map((topic) {
            return ActionChip(
              label: Text(topic),
              backgroundColor: HealTokens.rosewood,
              labelStyle: const TextStyle(color: HealTokens.cream),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HealTokens.r16),
                side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.3)),
              ),
              onPressed: () {
                controller.text = topic;
                HapticFeedback.selectionClick();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: HealTokens.s32),
        Text(
          'Search by word, phrase, or scripture reference',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HealTokens.creamDim,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _noResults(BuildContext context, String query) {
    return Padding(
      padding: const EdgeInsets.all(HealTokens.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: HealTokens.creamDim),
          const SizedBox(height: HealTokens.s16),
          Text(
            'No matches for "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HealTokens.cream,
                ),
          ),
          const SizedBox(height: HealTokens.s8),
          Text(
            'Try a shorter word or a different spelling.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HealTokens.creamDim,
                ),
          ),
        ],
      ),
    );
  }

  Widget _resultList(BuildContext context, WidgetRef ref, List<SearchResult> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: HealTokens.s8),
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(
        color: HealTokens.rosewoodLight.withValues(alpha: 0.3),
        height: 1,
      ),
      itemBuilder: (context, i) {
        final r = results[i];
        return _ResultTile(
          result: r,
          onTap: () {
            HapticFeedback.selectionClick();
            unawaited(ref.read(analyticsServiceProvider).log(
              AnalyticsEvent(HealEvents.searchResultTap, params: {
                'kind': r.kind,
                'slug': r.slug,
                'position': i,
              }),
            ));
            _navigateToResult(context, r);
          },
        );
      },
    );
  }

  void _navigateToResult(BuildContext context, SearchResult r) {
    switch (r.kind) {
      case 'meditation':
        context.push('/meditate/${r.slug}');
        break;
      case 'praise':
        context.push('/praise/${r.slug}');
        break;
      case 'prayer':
        context.push('/prayer/${r.slug}');
        break;
      case 'scripture':
        context.push('/scripture/${r.slug}');
        break;
      case 'essay':
        context.push('/essay/${r.slug}');
        break;
      case 'world':
        context.push('/world/${r.slug}');
        break;
    }
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.onTap});
  final SearchResult result;
  final VoidCallback onTap;

  static const _kindLabel = {
    'meditation': 'Meditation',
    'praise': 'Praise',
    'prayer': 'Prayer',
    'scripture': 'Scripture',
    'essay': 'Essay',
    'world': 'World',
  };
  static const _kindColor = {
    'meditation': HealTokens.auroraTeal,
    'praise': HealTokens.brass,
    'prayer': HealTokens.rosewoodLight,
    'scripture': HealTokens.terracotta,
    'essay': HealTokens.forest,
    'world': HealTokens.sunrise,
  };

  @override
  Widget build(BuildContext context) {
    final kindColor = _kindColor[result.kind] ?? HealTokens.brass;
    final kindLabel = _kindLabel[result.kind] ?? result.kind;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HealTokens.s20,
          vertical: HealTokens.s16,
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 56,
              decoration: BoxDecoration(
                color: kindColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: HealTokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kindColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kindLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: kindColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (result.durationSeconds > 0)
                        Text(
                          _formatDuration(result.durationSeconds),
                          style: TextStyle(
                            color: HealTokens.creamDim,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: HealTokens.cream,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.creamDim,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: HealTokens.creamDim),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int s) {
    final m = (s / 60).round();
    return m < 60 ? '${m}m' : '${(m / 60).floor()}h ${m % 60}m';
  }
}
