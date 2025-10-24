import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:bumper_builder/components/pellet.dart';

class DrainHole extends BodyComponent with ContactCallbacks {
  final Vector2 position;

  DrainHole({required this.position});

  static final _paint = Paint()
    ..color = Colors.redAccent.withOpacity(0.6)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

  static final _corePaint = Paint()
    ..color = Colors.deepOrange
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 1.5; // Made it a bit larger
    final fixtureDef = FixtureDef(
      shape,
      isSensor: true,
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
    // Add a core to the planet
    canvas.drawCircle(
      circle.position.toOffset(),
      circle.radius / 1.5,
      _corePaint,
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Pellet) {
      other.removeFromParent();
      // End game here
    }
  }
}
