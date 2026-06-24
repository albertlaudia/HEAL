// Praise library — full song list with emotion/context filters.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PraiseLibraryPage extends StatelessWidget {
  const PraiseLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Praise')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final slug in const <String>[
            'amazing-grace-full',
            'how-firm-a-foundation',
            'be-still-my-soul',
            'come-thou-fount-of-every-blessing',
            'psalm-23-sung',
          ])
            ListTile(
              title: Text(slug.replaceAll('-', ' ')),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => context.go('/praise/$slug'),
            ),
        ],
      ),
    );
  }
}
