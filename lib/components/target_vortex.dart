import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:bumper_builder/components/pellet.dart';
import 'package:bumper_builder/game.dart';

class TargetVortex extends BodyComponent with ContactCallbacks {
  final Vector2 position;
  int pelletCount = 0;

  late final TextComponent _counter;

  TargetVortex({required this.position});

  static final _paint = Paint()
    ..color = Colors.lightBlueAccent.withOpacity(0.5)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _counter = TextComponent(
      text: '0',
      position: Vector2(0, 0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color.fromARGB(255, 31, 35, 229),
          fontSize: 1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_counter);
  }

  void reset() {
    pelletCount = 0;
    _counter.text = '0';
  }

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
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      circle.position.toOffset(),
      circle.radius / 2,
      corePaint,
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Pellet) {
      FlameAudio.play('correct.mp3');
      (world as BumperBuilderWorld).pellets.remove(other);
      other.removeFromParent();
      pelletCount++;
      _counter.text = '$pelletCount';
    }
  }
}
