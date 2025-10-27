import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
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

class Level {
  final Vector2 emitterPosition;
  final Vector2 drainHolePosition;
  final Vector2 targetVortexPosition;
  final Vector2 pelletVelocity;

  Level({
    required this.emitterPosition,
    required this.drainHolePosition,
    required this.targetVortexPosition,
    required this.pelletVelocity,
  });
}

class BumperBuilderGame extends Forge2DGame with DragCallbacks {
  BumperBuilderGame() : super(world: BumperBuilderWorld(), zoom: 20, gravity: Vector2(0, 10));

  int currentLevel = 1;
  late final List<Level> levels;

  Vector2? dragStart;
  Vector2? dragEnd;
  bool isDraggingWall = false;
  Tool selectedTool = Tool.pencil;
  final List<List<Wall>> wallStrokes = [];
  int remainingWalls = 3;
  GameState gameState = GameState.waitingToStart;
  int remainingTime = 30;

  double currentWallLength = 0.0;
  static const double maxWallLength = 20.0;

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
    final wallSize = screenToWorld(size);
    _initializeLevels(wallSize);

    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll([
      'gamemusic.mp3',
      'correct.mp3',
      'wrong.mp3',
    ]);
    overlays.add('startScreen');
    add(ToolbarComponent());
  }

  void _initializeLevels(Vector2 wallSize) {
    const bottomPadding = 5.0;
    final bottomY = wallSize.y * 2 - bottomPadding;
    final gravity = world.gravity.y;

    Vector2 calculateVelocity(Vector2 start, Vector2 end, double time) {
      final dx = end.x - start.x;
      final dy = end.y - start.y;
      final vx = dx / time;
      final vy = (dy - 0.5 * gravity * time * time) / time;
      return Vector2(vx, vy);
    }

    levels = [
      // Level 1
      Level(
        emitterPosition: Vector2(wallSize.x, 5),
        drainHolePosition: Vector2(wallSize.x, bottomY),
        targetVortexPosition: Vector2(wallSize.x * 2 - bottomPadding, bottomY),
        pelletVelocity: Vector2(0, 0),
      ),
      // Level 2
      Level(
        emitterPosition: Vector2(5, 5),
        drainHolePosition: Vector2(wallSize.x, bottomY),
        targetVortexPosition: Vector2(wallSize.x * 2 - bottomPadding, bottomY),
        pelletVelocity: calculateVelocity(Vector2(5, 5), Vector2(wallSize.x, bottomY), 2.0),
      ),
      // Level 3
      Level(
        emitterPosition: Vector2(5, 5),
        drainHolePosition: Vector2(wallSize.x + 5, bottomY),
        targetVortexPosition: Vector2(bottomPadding, bottomY),
        pelletVelocity: calculateVelocity(Vector2(5, 5), Vector2(wallSize.x + 5, bottomY), 2.5),
      ),
      // Level 4
      Level(
        emitterPosition: Vector2(wallSize.x * 2 - 5, 5),
        drainHolePosition: Vector2(wallSize.x - 5, bottomY),
        targetVortexPosition: Vector2(bottomPadding, bottomY),
        pelletVelocity: calculateVelocity(Vector2(wallSize.x * 2 - 5, 5), Vector2(wallSize.x - 5, bottomY), 2.0),
      ),
      // Level 5
      Level(
        emitterPosition: Vector2(5, 5),
        drainHolePosition: Vector2(wallSize.x, bottomY - 10),
        targetVortexPosition: Vector2(wallSize.x * 2 - bottomPadding, bottomY),
        pelletVelocity: calculateVelocity(Vector2(5, 5), Vector2(wallSize.x, bottomY - 10), 2.0),
      ),
    ];
  }

  void startGame() {
    if (gameState == GameState.waitingToStart) {
      overlays.remove('startScreen');
      loadLevel();
    }
  }

  void endGame() {
    FlameAudio.bgm.stop();
    (world as BumperBuilderWorld).stopDroppingPellets();
    gameState = GameState.waitingForPelletsToSettle;
    add(SettleDownComponent(level: currentLevel));
  }

  void goToNextLevel() {
    currentLevel++;
    if (currentLevel > levels.length) {
      currentLevel = 1;
    }
    loadLevel();
  }

  void loadLevel() {
    overlays.remove('endScreen');

    // Reset game state
    remainingTime = 30;
    (world as BumperBuilderWorld).totalPellets = 0;
    (world as BumperBuilderWorld).pellets.clear();
    (world as BumperBuilderWorld).stopDroppingPellets();
    world.children.whereType<Pellet>().forEach((pellet) => pellet.removeFromParent());
    world.children.whereType<Wall>().where((wall) => wall.isErasable).forEach((wall) => wall.removeFromParent());
    world.children.whereType<Bumper>().forEach((bumper) => bumper.removeFromParent());
    wallStrokes.clear();
    remainingWalls = 3;

    (world as BumperBuilderWorld).setupLevel(levels[currentLevel - 1]);

    // Remove old timers
    children.whereType<TimerComponent>().forEach((timer) => timer.removeFromParent());

    // Start countdown
    gameState = GameState.countingDown;
    add(CountdownComponent());

    // Add game timer
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

  void startDroppingPellets() {
    FlameAudio.bgm.play('gamemusic.mp3');
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
      return;
    }
    if (selectedTool == Tool.pencil) {
      if (remainingWalls > 0) {
        wallStrokes.add([]);
        currentWallLength = 0.0;
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
    if (dragStart == null) return;

    if (selectedTool == Tool.pencil && remainingWalls > 0) {
      if (dragEnd != null) {
        if (!isDraggingWall && (event.canvasEndPosition - dragStart!).length > 2.0) {
          isDraggingWall = true;
        }

        if (isDraggingWall) {
          final worldStart = screenToWorld(dragEnd!);
          final worldEnd = screenToWorld(event.canvasEndPosition);
          final segmentLength = (worldEnd - worldStart).length;

          if (currentWallLength + segmentLength <= maxWallLength) {
            currentWallLength += segmentLength;
            final wall = Wall(worldStart, worldEnd, wallPaint: drawnWallPaint, isErasable: true);
            world.add(wall);
            if (wallStrokes.isNotEmpty) {
              wallStrokes.last.add(wall);
            }
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
    if (dragStart == null) return;

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
  late TargetVortex targetVortex;
  late DrainHole drainHole;
  late PelletEmitter pelletEmitter;
  late Level currentLevel;

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

    targetVortex = TargetVortex(position: Vector2.zero());
    drainHole = DrainHole(position: Vector2.zero());
    pelletEmitter = PelletEmitter(position: Vector2.zero());

    final wallSize = gameRef.screenToWorld(gameRef.size);
    gameRef.camera.moveTo(wallSize);
    add(GridComponent());

    const inset = 0.5;
    final rect = Rect.fromLTRB(inset, inset, wallSize.x * 2 - inset, wallSize.y * 2 - inset);
    add(_RoundedBoundaryPainter(rect: rect, paint: boundaryPaint, cornerRadius: 10.0));

    // Boundary walls
    add(Wall(Vector2(inset, inset), Vector2(wallSize.x * 2 - inset, inset)));
    add(Wall(Vector2(inset, wallSize.y * 2 - inset), Vector2(wallSize.x * 2 - inset, wallSize.y * 2 - inset)));
    add(Wall(Vector2(inset, inset), Vector2(inset, wallSize.y * 2 - inset)));
    add(Wall(Vector2(wallSize.x * 2 - inset, inset), Vector2(wallSize.x * 2 - inset, wallSize.y * 2 - inset)));

    const innerInset = 1.0;
    add(Wall(Vector2(innerInset, innerInset), Vector2(wallSize.x * 2 - innerInset, innerInset), wallPaint: innerBoundaryPaint));
    add(Wall(Vector2(innerInset, wallSize.y * 2 - innerInset), Vector2(wallSize.x * 2 - innerInset, wallSize.y * 2 - innerInset), wallPaint: innerBoundaryPaint));
    add(Wall(Vector2(innerInset, innerInset), Vector2(innerInset, wallSize.y * 2 - innerInset), wallPaint: innerBoundaryPaint));
    add(Wall(Vector2(wallSize.x * 2 - innerInset, innerInset), Vector2(wallSize.x * 2 - innerInset, wallSize.y * 2 - innerInset), wallPaint: innerBoundaryPaint));
  }

  void setupLevel(Level level) {
    currentLevel = level;

    children.whereType<DrainHole>().forEach((e) => e.removeFromParent());
    children.whereType<TargetVortex>().forEach((e) => e.removeFromParent());
    children.whereType<PelletEmitter>().forEach((e) => e.removeFromParent());

    drainHole = DrainHole(position: level.drainHolePosition);
    targetVortex = TargetVortex(position: level.targetVortexPosition);
    pelletEmitter = PelletEmitter(position: level.emitterPosition);

    add(drainHole);
    add(targetVortex);
    add(pelletEmitter);
  }

  void startDroppingPellets() {
    _pelletDropper = TimerComponent(
      period: 1,
      repeat: true,
      onTick: () {
        if (gameRef.gameState == GameState.playing) {
          final pellet = Pellet(
            position: currentLevel.emitterPosition,
            velocity: currentLevel.pelletVelocity,
          );
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

class SettleDownComponent extends Component with HasGameRef<BumperBuilderGame> {
  final int level;

  SettleDownComponent({required this.level});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(RectangleComponent(
      size: gameRef.size,
      paint: Paint()..color = Colors.black.withOpacity(0.5),
    ));

    if (level == 1 || level == 5) {
      final timerOverText = TextComponent(
        text: 'Timer is Over',
        position: gameRef.size / 2,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 50,
            fontFamily: 'Orbitron',
            shadows: [Shadow(color: Colors.red, blurRadius: 10)],
          ),
        ),
      );
      add(timerOverText);

      await Future.delayed(const Duration(seconds: 2));

      remove(timerOverText);

      final convertingText = TextBoxComponent(
        text: level == 1 ? 'Converting pallets to encoded message...' : 'Decoding final transmission...',
        size: Vector2(gameRef.size.x * 0.8, 200),
        position: gameRef.size / 2,
        anchor: Anchor.center,
        align: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 20,
            fontFamily: 'Orbitron',
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
          ),
        ),
      );
      add(convertingText);

      final flickerTimer = TimerComponent(
        period: 0.5,
        repeat: true,
        onTick: () {
          if (convertingText.isMounted) {
            remove(convertingText);
          } else {
            add(convertingText);
          }
        },
      );
      add(flickerTimer);
    } else {
      final collectingDataText = TextBoxComponent(
        text: 'Collecting pallet data...',
        size: Vector2(gameRef.size.x * 0.8, 200),
        position: gameRef.size / 2,
        anchor: Anchor.center,
        align: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 20,
            fontFamily: 'Orbitron',
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
          ),
        ),
      );
      add(collectingDataText);
    }

    add(TimerComponent(
      period: 0.1,
      repeat: true,
      onTick: () {
        if (gameRef.pelletsHaveSettled) {
          gameRef.gameState = GameState.gameOver;
          gameRef.overlays.add('endScreen');
          gameRef.children.whereType<TimerComponent>().forEach((timer) => timer.timer.stop());
          removeFromParent();
        }
      },
    ));
  }
}