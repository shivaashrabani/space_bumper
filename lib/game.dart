import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:bumper_builder/components/bumper.dart';
import 'package:bumper_builder/components/drain_hole.dart';
import 'package:bumper_builder/components/grid.dart';
import 'package:bumper_builder/components/pellet.dart';
import 'package:bumper_builder/components/pellet_emitter.dart';
import 'package:bumper_builder/components/target_vortex.dart';
import 'package:bumper_builder/components/toolbar.dart';
import 'package:bumper_builder/components/wall.dart';
import 'package:flutter/material.dart';

enum GameState { waitingToStart, countingDown, playing, waitingForPelletsToSettle, gameOver }

class BumperBuilderGame extends Forge2DGame with DragCallbacks {
  BumperBuilderGame() : super(world: BumperBuilderWorld(), zoom: 20, gravity: Vector2(0, 10));

  Vector2? dragStart;
  Vector2? dragEnd;
  bool isDraggingWall = false;
  Tool selectedTool = Tool.pencil;
  final List<List<Wall>> wallStrokes = [];
  int remainingWalls = 3;
  GameState gameState = GameState.waitingToStart;
  int remainingTime = 30;

  TargetVortex get targetVortex => (world as BumperBuilderWorld).targetVortex;
  DrainHole get drainHole => (world as BumperBuilderWorld).drainHole;
  int get totalPellets => (world as BumperBuilderWorld).totalPellets;
  bool get pelletsHaveSettled {
    if ((world as BumperBuilderWorld).pellets.isEmpty) {
      return true;
    }
    for (final pellet in (world as BumperBuilderWorld).pellets) {
      if (pellet.body.linearVelocity.length > 0.1) {
        return false;
      }
    }
    return true;
  }

  static final Paint drawnWallPaint = Paint()
    ..color = Colors.cyan.withOpacity(0.8)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    overlays.add('startScreen');
    add(ToolbarComponent());
  }

  void startGame() {
    if (gameState == GameState.waitingToStart) {
      overlays.remove('startScreen');
      gameState = GameState.countingDown;
      add(CountdownComponent());
      add(
        TimerComponent(
          period: 1,
          repeat: true,
          onTick: () {
            if (gameState == GameState.playing) {
              remainingTime--;
              if (remainingTime <= 0) {
                endGame();
              }
            }
          },
        ),
      );
    }
  }

  void endGame() {
    (world as BumperBuilderWorld).stopDroppingPellets();
    gameState = GameState.waitingForPelletsToSettle;
    add(
      TimerComponent(
        period: 0.1,
        repeat: true,
        onTick: () {
          if (pelletsHaveSettled) {
            gameState = GameState.gameOver;
            overlays.add('endScreen');
            this.children.whereType<TimerComponent>().forEach((timer) => timer.timer.stop());
          }
        },
      ),
    );
  }

  void restartGame() {
    overlays.remove('endScreen');
    gameState = GameState.waitingToStart;
    remainingTime = 30;
    (world as BumperBuilderWorld).totalPellets = 0;
    (world as BumperBuilderWorld).pellets.clear();
    (world as BumperBuilderWorld).stopDroppingPellets();
    targetVortex.reset();
    drainHole.reset();
    world.children.whereType<Pellet>().forEach((pellet) => pellet.removeFromParent());
    world.children.whereType<Wall>().where((wall) => wall.isErasable).forEach((wall) => wall.removeFromParent());
    world.children.whereType<Bumper>().forEach((bumper) => bumper.removeFromParent());
    wallStrokes.clear();
    remainingWalls = 3;
    overlays.add('startScreen');
  }

  void startDroppingPellets() {
    (world as BumperBuilderWorld).startDroppingPellets();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewport.size = size;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawColor(const Color(0xFF0c0a1f), BlendMode.src);
    super.render(canvas);
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (gameState != GameState.playing) return;
    super.onDragStart(event);
    if (event.localPosition.x > size.x - 80 && event.localPosition.y < 140) {
      // Drag started on the toolbar, ignore it for game interactions.
      return;
    }
    if (selectedTool == Tool.pencil) {
      if (remainingWalls > 0) {
        wallStrokes.add([]);
      }
    }
    dragStart = event.localPosition;
    dragEnd = event.localPosition;
    isDraggingWall = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameState != GameState.playing) return;
    super.onDragUpdate(event);
    if (dragStart == null) return; // Drag started on toolbar

    if (selectedTool == Tool.pencil && remainingWalls > 0) {
      if (dragEnd != null) {
        if (!isDraggingWall && (event.canvasEndPosition - dragStart!).length > 2.0) {
          isDraggingWall = true;
        }

        if (isDraggingWall) {
          final worldStart = screenToWorld(dragEnd!);
          final worldEnd = screenToWorld(event.canvasEndPosition);
          final wall = Wall(worldStart, worldEnd, wallPaint: drawnWallPaint, isErasable: true);
          world.add(wall);
          if (wallStrokes.isNotEmpty) {
            wallStrokes.last.add(wall);
          }
        }
      }
      dragEnd = event.canvasEndPosition;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (gameState != GameState.playing) return;
    super.onDragEnd(event);
    if (dragStart == null) return; // Drag started on toolbar

    if (selectedTool == Tool.pencil) {
      if (!isDraggingWall && dragStart != null) {
        final worldPosition = screenToWorld(dragStart!);
        world.add(Bumper(position: worldPosition));
      } else if (isDraggingWall) {
        remainingWalls--;
      }
    }
    dragStart = null;
    dragEnd = null;
    isDraggingWall = false;
  }

  void undoLastWall() {
    if (wallStrokes.isNotEmpty) {
      final lastStroke = wallStrokes.removeLast();
      if (lastStroke.isNotEmpty) {
        remainingWalls++;
      }
      for (final wall in lastStroke) {
        world.remove(wall);
      }
    }
  }
}

class BumperBuilderWorld extends Forge2DWorld with HasGameRef<BumperBuilderGame>, ContactCallbacks {
  late final TargetVortex targetVortex;
  late final DrainHole drainHole;
  int totalPellets = 0;
  final List<Pellet> pellets = [];
  TimerComponent? _pelletDropper;

  static final Paint boundaryPaint = Paint()
    ..color = const Color(0xFF00d8ff)
    ..strokeWidth = 0.3
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

  static final Paint innerBoundaryPaint = Paint()
    ..color = const Color(0xFF00a0c0)
    ..strokeWidth = 0.1
    ..style = PaintingStyle.stroke;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final size = gameRef.size;
    final wallSize = gameRef.screenToWorld(size);

    gameRef.camera.moveTo(wallSize);

    add(GridComponent());

    const inset = 0.5;
    final rect = Rect.fromLTRB(inset, inset, wallSize.x * 2 - inset, wallSize.y * 2 - inset);

    add(_RoundedBoundaryPainter(rect: rect, paint: boundaryPaint, cornerRadius: 10.0));

    // Boundary walls (invisible)
    add(Wall(Vector2(inset, inset), Vector2(wallSize.x * 2 - inset, inset)));
    add(Wall(Vector2(inset, wallSize.y * 2 - inset), Vector2(wallSize.x * 2 - inset, wallSize.y * 2 - inset)));
    add(Wall(Vector2(inset, inset), Vector2(inset, wallSize.y * 2 - inset)));
    add(Wall(Vector2(wallSize.x * 2 - inset, inset), Vector2(wallSize.x * 2 - inset, wallSize.y * 2 - inset)));


    // Inner border
    const innerInset = 1.0;
    add(Wall(Vector2(innerInset, innerInset), Vector2(wallSize.x * 2 - innerInset, innerInset), wallPaint: innerBoundaryPaint));
    add(Wall(Vector2(innerInset, wallSize.y * 2 - innerInset), Vector2(wallSize.x * 2 - innerInset, wallSize.y * 2 - innerInset), wallPaint: innerBoundaryPaint));
    add(Wall(Vector2(innerInset, innerInset), Vector2(innerInset, wallSize.y * 2 - innerInset), wallPaint: innerBoundaryPaint));
    add(Wall(Vector2(wallSize.x * 2 - innerInset, innerInset), Vector2(wallSize.x * 2 - innerInset, wallSize.y * 2 - innerInset), wallPaint: innerBoundaryPaint));


    targetVortex = TargetVortex(position: Vector2(wallSize.x, wallSize.y * 1.75));
    drainHole = DrainHole(position: Vector2(wallSize.x / 2, wallSize.y * 1.75));
    add(targetVortex);
    add(drainHole);

    final pelletEmitterPosition = Vector2(5, 5);
    add(PelletEmitter(position: pelletEmitterPosition));
  }

  void startDroppingPellets() {
    final pelletEmitterPosition = Vector2(5, 5);
    _pelletDropper = TimerComponent(
      period: 1,
      repeat: true,
      onTick: () {
        if (gameRef.gameState == GameState.playing) {
          final pellet = Pellet(position: pelletEmitterPosition);
          add(pellet);
          pellets.add(pellet);
          totalPellets++;
        }
      },
    );
    add(_pelletDropper!);
  }

  void stopDroppingPellets() {
    _pelletDropper?.removeFromParent();
    _pelletDropper = null;
  }
}

class _RoundedBoundaryPainter extends Component {
  final Rect rect;
  final Paint paint;
  final double cornerRadius;

  _RoundedBoundaryPainter({
    required this.rect,
    required this.paint,
    this.cornerRadius = 1.0,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    canvas.drawRRect(rrect, paint);
  }
}

class CountdownComponent extends Component with HasGameRef<BumperBuilderGame> {
  int count = 3;

  late final TextComponent _text;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _text = TextComponent(
      text: '$count',
      position: gameRef.size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 100,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_text);

    add(
      TimerComponent(
        period: 1,
        repeat: true,
        onTick: () {
          count--;
          if (count > 0) {
            _text.text = '$count';
          } else if (count == 0) {
            _text.text = 'Go!';
          } else {
            removeFromParent();
            gameRef.gameState = GameState.playing;
            gameRef.startDroppingPellets();
          }
        },
      ),
    );
  }
}
