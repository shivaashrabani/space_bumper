import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:bumper_builder/game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GameWidget(
          game: BumperBuilderGame(),
        ),
      ),
    );
  }
}
