import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;
  final Paint? wallPaint;
  final bool isErasable;

  Wall(this.start, this.end, {this.wallPaint, this.isErasable = false});

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape, friction: 0.3, userData: this); // Set userData
    final bodyDef = BodyDef(position: Vector2.zero());
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (wallPaint != null) {
      canvas.drawLine(start.toOffset(), end.toOffset(), wallPaint!);
    }
  }
}