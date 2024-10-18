import 'package:flutter/material.dart';
import 'screens/editor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WYSIWYG',
      home: const EditorScreen(),
      routes: {
        "/editor": (context) => const EditorScreen(),
      },
    );
  }
}

// https://kazuhideoka.net/game/natsuno-kanata-beyond/
// https://sprite.net/everlastingflowers