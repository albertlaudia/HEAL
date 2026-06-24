// Meditate detail — single meditation player.

import 'package:flutter/material.dart';

class MeditateDetailPage extends StatelessWidget {
  const MeditateDetailPage({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditate')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Meditation: $slug'),
        ),
      ),
    );
  }
}
