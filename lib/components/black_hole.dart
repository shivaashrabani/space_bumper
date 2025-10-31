import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:bumper_builder/components/pellet.dart';

class BlackHole extends BodyComponent {
  final Vector2 position;
  final double radius;
  final double gravitationalRadius;

  BlackHole({
    required this.position,
    required this.radius,
  }) : gravitationalRadius = radius * 2.5;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(shape, isSensor: true);
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final component in world.children) {
      if (component is Pellet) {
        final pellet = component;
        final distance = pellet.body.position.distanceTo(body.position);
        if (distance < gravitationalRadius) {
          final direction = (body.position - pellet.body.position)..normalize();
          final force = (gravitationalRadius - distance) * 200;
          pellet.body.applyForce(direction * force);
        }
        if (distance < radius) {
          pellet.removeFromParent();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset.zero;

    final gradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.5),
        Colors.white.withOpacity(0.0),
      ],
      stops: [0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: gravitationalRadius));

    final gravitationalPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, gravitationalRadius, gravitationalPaint);

    final blackHolePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, blackHolePaint);
  }
}