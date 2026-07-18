// HEAL — Library page.
//
// The user's personal library: Favorites, History, Journal. One place to
// revisit everything they've touched in HEAL.
//
// Three tabs:
//   1. Favorites  — hearted items across all content types
//   2. History    — recently played (last 100)
//   3. Journal    — private reflection entries
//
// Mirrors the calm/premium feel of the rest of HEAL. Each row is a
// "tappable card" that navigates to the item's detail page.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/widgets/brass_widgets.dart';
import '../../services/favorites_service.dart';
import '../../services/history_service.dart';
import '../../services/journal_service.dart';
import '../../services/analytics_service.dart';

class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState<int>(0);
    unawaited(ref.read(analyticsServiceProvider).log(
      const AnalyticsEvent('library_opened', params: {'tab_index': 0}),
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your library'),
        backgroundColor: HealTokens.rosewood,
        iconTheme: const IconThemeData(color: HealTokens.cream),
      ),
      body: Container(
        color: HealTokens.oxblood,
        child: Column(
          children: [
            // ── Tab bar ──────────────────────────────────────
            _LibraryTabBar(
              current: tab.value,
              onChange: (i) {
                tab.value = i;
                HapticFeedback.selectionClick();
                unawaited(ref.read(analyticsServiceProvider).log(
                  AnalyticsEvent('library_tab_changed', params: {'tab_index': i}),
                ));
              },
              favoritesCount: ref.watch(favoritesServiceProvider).count,
              historyCount: ref.watch(historyServiceProvider).entries.length,
              journalCount: ref.watch(journalServiceProvider).count,
            ),
            const Divider(height: 1, color: HealTokens.rosewoodLight),
            // ── Tab body ───────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: tab.value,
                children: const [
                  _FavoritesTab(),
                  _HistoryTab(),
                  _JournalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTabBar extends StatelessWidget {
  const _LibraryTabBar({
    required this.current,
    required this.onChange,
    required this.favoritesCount,
    required this.historyCount,
    required this.journalCount,
  });

  final int current;
  final ValueChanged<int> onChange;
  final int favoritesCount;
  final int historyCount;
  final int journalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HealTokens.rosewood,
      padding: const EdgeInsets.symmetric(horizontal: HealTokens.s8, vertical: HealTokens.s8),
      child: Row(
        children: [
          _TabButton(
            label: 'Favorites',
            count: favoritesCount,
            active: current == 0,
            onTap: () => onChange(0),
          ),
          _TabButton(
            label: 'History',
            count: historyCount,
            active: current == 1,
            onTap: () => onChange(1),
          ),
          _TabButton(
            label: 'Journal',
            count: journalCount,
            active: current == 2,
            onTap: () => onChange(2),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? HealTokens.brass : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? HealTokens.cream : HealTokens.creamDim,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              if (count > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: active ? HealTokens.brass : HealTokens.creamDim.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Favorites tab ────────────────────────────────────────────────
class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesServiceProvider);
    if (favs.ids.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        body: 'Heart a meditation, praise song, or scripture and it shows up here.',
      );
    }
    final entries = favs.ids.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(HealTokens.s16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: HealTokens.s8),
      itemBuilder: (context, i) {
        final composite = entries[i];
        final colonIdx = composite.indexOf(':');
        final kind = composite.substring(0, colonIdx);
        final slug = composite.substring(colonIdx + 1);
        return _LibraryRow(
          kind: kind,
          slug: slug,
          title: _titleForKind(slug, kind),
          subtitle: _subtitleForKind(slug, kind),
          onTap: () => _navigate(context, kind, slug),
          onRemove: () async {
            HapticFeedback.selectionClick();
            await ref.read(favoritesServiceProvider.notifier).remove(kind, slug);
            unawaited(ref.read(analyticsServiceProvider).log(
              AnalyticsEvent(HealEvents.favoriteRemoved, params: {
                'kind': kind,
                'slug': slug,
              }),
            ));
          },
        );
      },
    );
  }

  String _titleForKind(String slug, String kind) {
    // The favorite id is a composite ("praise:slug"). We don't have the
    // original title cached — fall back to a slug → humanized form.
    return slug.split('-').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  String _subtitleForKind(String slug, String kind) {
    return 'Favorite · $kind';
  }

  void _navigate(BuildContext context, String kind, String slug) {
    switch (kind) {
      case 'meditation': context.push('/meditate/$slug'); break;
      case 'praise':     context.push('/praise/$slug'); break;
      case 'prayer':     context.push('/prayer/$slug'); break;
      case 'scripture':  context.push('/scripture/$slug'); break;
      case 'essay':      context.push('/essay/$slug'); break;
      case 'world':      context.push('/world/$slug'); break;
    }
  }
}

// ── History tab ─────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyServiceProvider);
    if (history.entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'Nothing here yet',
        body: 'Play a meditation or praise song and it shows up here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(HealTokens.s16),
      itemCount: history.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: HealTokens.s8),
      itemBuilder: (context, i) {
        final e = history.entries[i];
        return _LibraryRow(
          kind: e.kind,
          slug: e.slug,
          title: e.title,
          subtitle: '${e.subtitle ?? ''} · ${_relativeTime(e.playedAt)}',
          trailing: e.completionRatio >= 0.95
              ? const Icon(Icons.check_circle_rounded, color: HealTokens.brass, size: 16)
              : null,
          onTap: () => _navigate(context, e.kind, e.slug),
          onRemove: () async {
            await ref.read(historyServiceProvider.notifier).remove(e.kind, e.slug);
          },
        );
      },
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(t);
  }

  void _navigate(BuildContext context, String kind, String slug) {
    switch (kind) {
      case 'meditation': context.push('/meditate/$slug'); break;
      case 'praise':     context.push('/praise/$slug'); break;
      case 'prayer':     context.push('/prayer/$slug'); break;
      case 'scripture':  context.push('/scripture/$slug'); break;
      case 'essay':      context.push('/essay/$slug'); break;
      case 'world':      context.push('/world/$slug'); break;
    }
  }
}

// ── Journal tab ─────────────────────────────────────────────────
class _JournalTab extends ConsumerWidget {
  const _JournalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalServiceProvider);
    if (journal.entries.isEmpty) {
      return _EmptyState(
        icon: Icons.edit_note_rounded,
        title: 'A quiet place to reflect',
        body: 'After a meditation or scripture, jot down what surfaced. '
            'It\'s just for you — no one else can see it.',
        action: _ComposeButton(
          onTap: () => _openEditor(context, ref, null),
        ),
      );
    }
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            HealTokens.s16, HealTokens.s16, HealTokens.s16, 80,
          ),
          itemCount: journal.entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: HealTokens.s8),
          itemBuilder: (context, i) {
            final e = journal.entries[i];
            return _JournalRow(
              entry: e,
              onTap: () => _openEditor(context, ref, e),
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: HealTokens.rosewood,
                    title: const Text('Delete this entry?',
                        style: TextStyle(color: HealTokens.cream)),
                    content: const Text('This can\'t be undone.',
                        style: TextStyle(color: HealTokens.creamDim)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: HealTokens.creamDim)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: HealTokens.brass)),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(journalServiceProvider.notifier).delete(e.id);
                }
              },
            );
          },
        ),
        Positioned(
          right: HealTokens.s16,
          bottom: HealTokens.s16,
          child: _ComposeButton(
            onTap: () => _openEditor(context, ref, null),
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, JournalEntry? entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HealTokens.oxblood,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
      ),
      builder: (ctx) => _JournalEditor(
        initial: entry,
        onSave: (body, mood) async {
          if (entry == null) {
            await ref.read(journalServiceProvider.notifier).create(
              body: body,
              mood: mood,
            );
            unawaited(ref.read(analyticsServiceProvider).log(
              const AnalyticsEvent(HealEvents.journalEntrySaved),
            ));
          } else {
            await ref.read(journalServiceProvider.notifier).update(
              entry.id,
              body: body,
              mood: mood,
            );
          }
        },
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.kind,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
    this.trailing,
  });
  final String kind;
  final String slug;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: HealTokens.s16, vertical: HealTokens.s12,
      ),
      child: Row(
        children: [
          Icon(_iconForKind(kind), color: HealTokens.brass, size: 20),
          const SizedBox(width: HealTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HealTokens.cream,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HealTokens.creamDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          IconButton(
            icon: const Icon(Icons.close_rounded, color: HealTokens.creamDim, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'meditation': return Icons.self_improvement_rounded;
      case 'praise':     return Icons.music_note_rounded;
      case 'prayer':     return Icons.connect_without_contact_rounded;
      case 'scripture':  return Icons.menu_book_rounded;
      case 'essay':      return Icons.article_outlined;
      case 'world':      return Icons.public_rounded;
      default:           return Icons.bookmark_rounded;
    }
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(HealTokens.s16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MMM d, h:mm a').format(entry.updatedAt),
                  style: const TextStyle(
                    color: HealTokens.brass,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (entry.contextTitle != null)
                  Expanded(
                    child: Text(
                      'on ${entry.contextTitle}',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HealTokens.creamDim,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: HealTokens.creamDim, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: HealTokens.cream,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEditor extends HookWidget {
  const _JournalEditor({this.initial, required this.onSave});
  final JournalEntry? initial;
  final Future<void> Function(String body, int? mood) onSave;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initial?.body ?? '');
    final mood = useState<int?>(initial?.mood);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(HealTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: HealTokens.s16),
              decoration: BoxDecoration(
                color: HealTokens.creamDim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              initial == null ? 'New entry' : 'Edit entry',
              style: const TextStyle(
                color: HealTokens.cream,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: HealTokens.s16),
            TextField(
              controller: controller,
              maxLines: 8,
              minLines: 4,
              autofocus: true,
              style: const TextStyle(color: HealTokens.cream, fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: 'What surfaced for you?',
                hintStyle: TextStyle(color: HealTokens.creamDim.withValues(alpha: 0.5)),
                filled: true,
                fillColor: HealTokens.rosewood.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HealTokens.r12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: HealTokens.s16),
            // Mood
            Row(
              children: List.generate(5, (i) {
                final value = i + 1;
                final selected = mood.value == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_moodEmoji(value)),
                    selected: selected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      mood.value = selected ? null : value;
                    },
                    backgroundColor: HealTokens.rosewood,
                    selectedColor: HealTokens.brass,
                    labelStyle: TextStyle(
                      color: selected ? HealTokens.oxblood : HealTokens.cream,
                      fontSize: 18,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: HealTokens.s16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: HealTokens.creamDim)),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    final body = controller.text.trim();
                    if (body.isEmpty) return;
                    await onSave(body, mood.value);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(backgroundColor: HealTokens.brass),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _moodEmoji(int value) {
    switch (value) {
      case 1: return '😔';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😊';
    }
    return '😐';
  }
}

class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      backgroundColor: HealTokens.brass,
      foregroundColor: HealTokens.oxblood,
      child: const Icon(Icons.add_rounded),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HealTokens.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: HealTokens.creamDim),
            const SizedBox(height: HealTokens.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HealTokens.cream,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: HealTokens.s8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HealTokens.creamDim,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: HealTokens.s24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── (helpers live inline above) ────────────────────────────────
