import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:bumper_builder/game.dart';

enum Tool { pencil, eraser }

class ToolbarComponent extends PositionComponent with HasGameRef<BumperBuilderGame>, TapCallbacks {
  late final Paint _backgroundPaint;
  late final Paint _selectedIconPaint;

  late final TextPainter _pencilPainter;
  late final TextPainter _eraserPainter;

  ToolbarComponent() {
    _backgroundPaint = Paint()..color = const Color(0x8000d8ff);
    _selectedIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _pencilPainter = TextPainter(textDirection: TextDirection.ltr);
    _eraserPainter = TextPainter(textDirection: TextDirection.ltr);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(gameRef.size.x - 80, 60);
    size = Vector2(60, 120);

    _pencilPainter.text = TextSpan(
      text: String.fromCharCode(Icons.brush.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontFamily: Icons.brush.fontFamily,
      ),
    );
    _pencilPainter.layout();

    _eraserPainter.text = TextSpan(
      text: String.fromCharCode(Icons.cleaning_services_sharp.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontFamily: Icons.cleaning_services_sharp.fontFamily,
      ),
    );
    _eraserPainter.layout();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _backgroundPaint);

    // Eraser icon
    final eraserRect = Rect.fromLTWH(10, 10, 40, 40);
    if (gameRef.selectedTool == Tool.eraser) {
      canvas.drawRect(eraserRect, _selectedIconPaint);
    }
    _eraserPainter.paint(canvas, eraserRect.center - Offset(_eraserPainter.width / 2, _eraserPainter.height / 2));

    // Pencil icon
    final pencilRect = Rect.fromLTWH(10, 70, 40, 40);
    if (gameRef.selectedTool == Tool.pencil) {
      canvas.drawRect(pencilRect, _selectedIconPaint);
    }
    _pencilPainter.paint(canvas, pencilRect.center - Offset(_pencilPainter.width / 2, _pencilPainter.height / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (Rect.fromLTWH(10, 10, 40, 40).contains(event.localPosition.toOffset())) {
      gameRef.selectedTool = Tool.eraser;
    } else if (Rect.fromLTWH(10, 70, 40, 40).contains(event.localPosition.toOffset())) {
      gameRef.selectedTool = Tool.pencil;
    }
  }
}