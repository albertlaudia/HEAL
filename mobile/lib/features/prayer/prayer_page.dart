// Prayer page — quiet container for the day's prayer.

import 'package:flutter/material.dart';

class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '"Lord, hear our prayer."',
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
