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

class BumperBuilderGame extends Forge2DGame with DragCallbacks {
  BumperBuilderGame() : super(world: BumperBuilderWorld(), zoom: 20, gravity: Vector2(0, 10));

  Vector2? dragStart;
  Vector2? dragEnd;
  bool isDraggingWall = false;
  Tool selectedTool = Tool.pencil;

  static final Paint drawnWallPaint = Paint()
    ..color = Colors.cyan.withOpacity(0.8)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(ToolbarComponent());
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
    super.onDragStart(event);
    if (event.localPosition.x > size.x - 80 && event.localPosition.y < 140) {
      // Drag started on the toolbar, ignore it for game interactions.
      return;
    }
    dragStart = event.localPosition;
    dragEnd = event.localPosition;
    isDraggingWall = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (dragStart == null) return; // Drag started on toolbar

    if (selectedTool == Tool.pencil) {
      if (dragEnd != null) {
        if (!isDraggingWall && (event.canvasEndPosition - dragStart!).length > 2.0) {
          isDraggingWall = true;
        }

        if (isDraggingWall) {
          final worldStart = screenToWorld(dragEnd!);
          final worldEnd = screenToWorld(event.canvasEndPosition);
          world.add(Wall(worldStart, worldEnd, wallPaint: drawnWallPaint, isErasable: true));
        }
      }
      dragEnd = event.canvasEndPosition;
    } else if (selectedTool == Tool.eraser) {
      final worldPosition = screenToWorld(event.canvasEndPosition);
      final aabb = AABB.new()
        ..lowerBound.setFrom(worldPosition - Vector2.all(0.1))
        ..upperBound.setFrom(worldPosition + Vector2.all(0.1));

      world.queryAABB(_WallEraser(), aabb);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (dragStart == null) return; // Drag started on toolbar

    if (selectedTool == Tool.pencil && !isDraggingWall && dragStart != null) {
      final worldPosition = screenToWorld(dragStart!);
      world.add(Bumper(position: worldPosition));
    }
    dragStart = null;
    dragEnd = null;
    isDraggingWall = false;
  }
}

class _WallEraser extends QueryCallback {
  @override
  bool reportFixture(Fixture fixture) {
    if (fixture.userData is Wall) {
      final wall = fixture.userData as Wall;
      if (wall.isErasable) {
        wall.removeFromParent();
      }
    }
    return true;
  }
}

class BumperBuilderWorld extends Forge2DWorld with HasGameRef<BumperBuilderGame>, ContactCallbacks {
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


    add(TargetVortex(position: Vector2(wallSize.x, wallSize.y * 1.75)));
    add(DrainHole(position: Vector2(wallSize.x / 2, wallSize.y * 1.75)));

    final pelletEmitterPosition = Vector2(5, 5);
    add(PelletEmitter(position: pelletEmitterPosition));

    add(
      TimerComponent(
        period: 1,
        repeat: true,
        onTick: () {
          add(Pellet(position: pelletEmitterPosition));
        },
      ),
    );
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