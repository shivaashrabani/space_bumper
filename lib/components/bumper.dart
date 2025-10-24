import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Bumper extends BodyComponent {
  final Vector2 position;

  Bumper({required this.position});

  static final _paint = Paint()
    ..color = Colors.purpleAccent.withOpacity(0.7)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.5;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.8,
      density: 1.0,
      friction: 0.1,
    );
    final bodyDef = BodyDef(
      userData: this,
      position: position,
      type: BodyType.static,
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
