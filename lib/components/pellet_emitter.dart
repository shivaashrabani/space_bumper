import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PelletEmitter extends PositionComponent {
  PelletEmitter({super.position});

  static final Paint _glowPaint = Paint()
    ..color = Colors.purple.withValues()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0); // Increased blur

  static final Paint _planetPaint = Paint()
    ..color = Colors.purple
    ..style = PaintingStyle.fill;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the glow
    canvas.drawCircle(Offset.zero, 2.0, _glowPaint); // Increased glow radius
    // Draw the planet body
    canvas.drawCircle(Offset.zero, 1.0, _planetPaint);
  }
}
