// Now — a single quiet screen showing what is here, right now.

import 'package:flutter/material.dart';

class NowPage extends StatelessWidget {
  const NowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 5 => 'A quiet small hour',
      < 9 => 'A gentle morning',
      < 12 => 'Mid-morning stillness',
      < 14 => 'Midday pause',
      < 18 => 'Afternoon light',
      < 21 => 'Evening settling',
      _ => 'Late and quiet',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Now')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'You are here. That is enough.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
