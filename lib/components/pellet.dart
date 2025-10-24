import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Pellet extends BodyComponent {
  final Vector2 position;

  Pellet({required this.position});

  static final Paint _paint = Paint()
    ..color = Colors.greenAccent
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.2;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.8,
      density: 1.0,
      friction: 0.1,
    );
    final bodyDef = BodyDef(
      userData: this,
      angularDamping: 0.8,
      position: position,
      type: BodyType.dynamic,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final circle = body.fixtures.first.shape as CircleShape;
    canvas.drawCircle(
      circle.position.toOffset(),
      circle.radius,
      _paint,
    );
  }
}
