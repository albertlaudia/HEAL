// HEAL — Journal nudge card.
//
// A tiny, dismissable card on the home page that says "What's one thing
// from today you want to remember?" with a single tap to open the
// journal. Non-blocking. Doesn't appear if the user has already journaled
// today. Once dismissed for the day, won't reappear until tomorrow.
//
// This is the discovery multiplier for the journal feature. The journal
// exists but is buried inside the Library tab. A 1-line nudge on the
// home page dramatically increases how often users write.
//
// Privacy: the nudge reads the journal state (which is local-only) and
// checks today's date. No network calls.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../services/journal_service.dart';

const _kNudgeKey = 'heal.journal_nudge.dismissed_date';

class JournalNudgeCard extends ConsumerStatefulWidget {
  const JournalNudgeCard({super.key});

  @override
  ConsumerState<JournalNudgeCard> createState() => _JournalNudgeCardState();
}

class _JournalNudgeCardState extends ConsumerState<JournalNudgeCard> {
  String? _dismissedDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDismiss();
  }

  Future<void> _loadDismiss() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissedDate = prefs.getString(_kNudgeKey);
    } catch (_) {
      _dismissedDate = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _dismiss() async {
    HapticFeedback.selectionClick();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNudgeKey, _todayKey());
    } catch (_) {}
    if (mounted) setState(() => _dismissedDate = _todayKey());
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    // Hidden if dismissed today
    if (_dismissedDate == _todayKey()) return const SizedBox.shrink();

    final journal = ref.watch(journalServiceProvider);
    // Hidden if user already journaled today
    final hasEntryToday = journal.entries.any((e) {
      final d = e.createdAt;
      return d.year == DateTime.now().year &&
          d.month == DateTime.now().month &&
          d.day == DateTime.now().day;
    });
    if (hasEntryToday) return const SizedBox.shrink();

    // 7 different prompts — rotate by day-of-year so it doesn't feel canned
    final prompts = [
      'What\'s one thing from today you want to remember?',
      'Where did you notice God today?',
      'What did your soul hear this week?',
      'A sentence about today. Just one.',
      'What made you breathe easier today?',
      'What did you want to say, but didn\'t?',
      'What is the small thing you keep forgetting to thank Him for?',
    ];
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final prompt = prompts[dayOfYear % prompts.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/library');
        },
        borderRadius: BorderRadius.circular(HealTokens.r16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            HealTokens.s16, HealTokens.s12, HealTokens.s12, HealTokens.s12,
          ),
          decoration: BoxDecoration(
            color: HealTokens.rosewoodLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(HealTokens.r16),
            border: Border.all(
              color: HealTokens.brass.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HealTokens.brass.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: HealTokens.brass,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    color: HealTokens.cream,
                    fontSize: 14,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  color: HealTokens.creamDim,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Not today',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
