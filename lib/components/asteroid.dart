import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Asteroid extends BodyComponent {
  final Vector2 position;
  final double radius;

  Asteroid({required this.position, required this.radius});

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      userData: this,
      position: position,
      type: BodyType.static,
    );
    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.4,
      density: 100.0,
      friction: 0.8,
    );
    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    final textStyle = TextStyle(
      fontSize: radius * 1.5,
      color: Colors.white,
    );
    final textSpan = TextSpan(
      text: '🪨',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }
}