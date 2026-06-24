// Home — single quiet narrative flow. Mirrors /web's app/page.tsx redesign.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HEAL'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () => Navigator.of(context).pushNamed('/now'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _greeting(),
              const SizedBox(height: 28),
              _scripture(),
              const SizedBox(height: 32),
              _meditationCard(),
              const SizedBox(height: 32),
              _healCards(),
              const SizedBox(height: 32),
              _breath(),
              const SizedBox(height: 32),
              _praiseAndPrayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _greeting() {
    return const Text(
      'Welcome back.\nA quiet hour is here.',
      style: TextStyle(fontSize: 24, height: 1.4, fontWeight: FontWeight.w300),
    );
  }

  Widget _scripture() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3A3328)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        '"Be still, and know that I am God."\n— Psalm 46:10',
        style: TextStyle(fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _meditationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'TODAY · DAY 1',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                color: const Color(0xFF8B8275),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A Breath of Stillness',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('12 minutes · H.E.A.L. framework'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {},
              child: const Text('Begin'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _healPill('H', 'Hope'),
        _healPill('E', 'Engage'),
        _healPill('A', 'Anchor'),
        _healPill('L', 'Lift'),
      ],
    );
  }

  Widget _healPill(String letter, String label) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF25201A),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Color(0xFFB08C4F),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _breath() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.air),
      label: const Text('Take a 90-second breath'),
    );
  }

  Widget _praiseAndPrayer() {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context)
                .pushNamed('/praise'),
            child: const Text('Praise'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context)
                .pushNamed('/prayer'),
            child: const Text('Prayer'),
          ),
        ),
      ],
    );
  }
}
