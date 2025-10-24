import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:bumper_builder/game.dart';

class GridComponent extends Component with HasGameRef<BumperBuilderGame> {
  final Paint gridPaint = Paint()
    ..color = const Color(0x1AFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;
  final double gridSize = 10.0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final visibleRect = gameRef.camera.visibleWorldRect;

    for (var x = (visibleRect.left / gridSize).floor() * gridSize;
        x < visibleRect.right;
        x += gridSize) {
      canvas.drawLine(
          Offset(x, visibleRect.top), Offset(x, visibleRect.bottom), gridPaint);
    }
    for (var y = (visibleRect.top / gridSize).floor() * gridSize;
        y < visibleRect.bottom;
        y += gridSize) {
      canvas.drawLine(
          Offset(visibleRect.left, y), Offset(visibleRect.right, y), gridPaint);
    }
  }
}
