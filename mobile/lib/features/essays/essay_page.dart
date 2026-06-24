// Essay detail — long-form reading view.

import 'package:flutter/material.dart';

class EssayPage extends StatelessWidget {
  const EssayPage({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(slug.replaceAll('-', ' '))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Essay: $slug'),
      ),
    );
  }
}
