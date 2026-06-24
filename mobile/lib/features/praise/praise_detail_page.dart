// Praise detail — single song player with description, tags, audio controls.

import 'package:flutter/material.dart';

class PraiseDetailPage extends StatelessWidget {
  const PraiseDetailPage({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(slug.replaceAll('-', ' '))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.music_note, size: 64),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                child: const Text('Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
