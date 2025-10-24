import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:bumper_builder/game.dart';

enum Tool { pencil, undo }

class ToolbarComponent extends PositionComponent with HasGameRef<BumperBuilderGame>, TapCallbacks {
  late final Paint _backgroundPaint;
  late final Paint _selectedIconPaint;

  late final TextPainter _wallCountPainter;
  late final TextPainter _undoPainter;
  late final TextPainter _percentagePainter;
  late final TextPainter _timerPainter;

  ToolbarComponent() {
    _backgroundPaint = Paint()..color = const Color(0x8000d8ff);
    _selectedIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _wallCountPainter = TextPainter(textDirection: TextDirection.ltr);
    _undoPainter = TextPainter(textDirection: TextDirection.ltr);
    _percentagePainter = TextPainter(textDirection: TextDirection.ltr);
    _timerPainter = TextPainter(textDirection: TextDirection.ltr);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(gameRef.size.x - 80, 60);
    size = Vector2(60, 240); // Increased height

    _undoPainter.text = TextSpan(
      text: String.fromCharCode(Icons.undo.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontFamily: Icons.undo.fontFamily,
      ),
    );
    _undoPainter.layout();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _backgroundPaint);

    // Undo icon
    final undoRect = Rect.fromLTWH(10, 10, 40, 40);
    _undoPainter.paint(canvas, undoRect.center - Offset(_undoPainter.width / 2, _undoPainter.height / 2));

    // Wall count
    _wallCountPainter.text = TextSpan(
      text: gameRef.remainingWalls.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
      ),
    );
    _wallCountPainter.layout();

    final pencilRect = Rect.fromLTWH(10, 70, 40, 40);
    if (gameRef.selectedTool == Tool.pencil) {
      canvas.drawRect(pencilRect, _selectedIconPaint);
    }
    _wallCountPainter.paint(canvas, pencilRect.center - Offset(_wallCountPainter.width / 2, _wallCountPainter.height / 2));

    // Percentage
    final whitePellets = gameRef.targetVortex.pelletCount;
    final totalPellets = gameRef.totalPellets;
    final percentage = totalPellets > 0 ? (whitePellets / totalPellets) * 100 : 0;

    _percentagePainter.text = TextSpan(
      text: '${percentage.toStringAsFixed(0)}%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    );
    _percentagePainter.layout();

    final percentageRect = Rect.fromLTWH(10, 130, 40, 40);
    _percentagePainter.paint(canvas, percentageRect.center - Offset(_percentagePainter.width / 2, _percentagePainter.height / 2));

    // Timer
    final minutes = (gameRef.remainingTime / 60).floor().toString().padLeft(2, '0');
    final seconds = (gameRef.remainingTime % 60).toString().padLeft(2, '0');
    _timerPainter.text = TextSpan(
      text: '$minutes:$seconds',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    );
    _timerPainter.layout();

    final timerRect = Rect.fromLTWH(10, 190, 40, 40);
    _timerPainter.paint(canvas, timerRect.center - Offset(_timerPainter.width / 2, _timerPainter.height / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (Rect.fromLTWH(10, 10, 40, 40).contains(event.localPosition.toOffset())) {
      gameRef.undoLastWall();
    } else if (Rect.fromLTWH(10, 70, 40, 40).contains(event.localPosition.toOffset())) {
      if (gameRef.remainingWalls > 0) {
        gameRef.selectedTool = Tool.pencil;
      }
    }
  }
}
