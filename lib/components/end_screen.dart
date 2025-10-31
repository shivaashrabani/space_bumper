import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum DecodingStep { initial, shuffling, revealing, complete }

class EndScreen extends StatefulWidget {
  final int score;
  final int totalPellets;
  final int level;
  final VoidCallback onRestart;
  final VoidCallback onNextLevel;

  const EndScreen({
    super.key,
    required this.score,
    required this.totalPellets,
    required this.level,
    required this.onRestart,
    required this.onNextLevel,
  });

  @override
  State<EndScreen> createState() => _EndScreenState();
}

class _EndScreenState extends State<EndScreen> with TickerProviderStateMixin {
  late final AnimationController _star1Controller;
  late final AnimationController _star2Controller;
  late final AnimationController _star3Controller;

  bool _isDecoding = false;
  String _decodedMessage = '';
  late String _visibleMessage;
  DecodingStep _decodingStep = DecodingStep.initial;

  @override
  void initState() {
    super.initState();

    if (widget.level == 20) {
      _decodedMessage = 'You have conquered the black holes and reached the final frontier. The universe is yours to explore. Congratulations, Master Builder!';
    } else if (widget.level == 15) {
      _decodedMessage = 'You have become a master of gravity manipulation. The final challenges await.';
    } else if (widget.level == 10) {
      _decodedMessage = 'Great Job. You have mastered the art of cosmic construction. The path to Cygnus Gamma-9 is getting clear. Beaware of the black holes next.';
    } else if (widget.level == 5) {
      _decodedMessage = 'Quantum entanglement successful. Trajectory data acquired. Warning: Gravitational anomalies detected ahead. Navigate with caution. Asteroid fields imminent.';
    } else {
      _decodedMessage = 'Initializing first-contact sequence. Draw lines and channel the pallets to your planet. Velocity nominal.';
    }

    _star1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _star2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _star3Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    final percentage = widget.totalPellets > 0 ? (widget.score / widget.totalPellets) * 100 : 0;

    if (percentage >= 50) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _star1Controller.forward();
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (percentage >= 75) {
          _star2Controller.forward();
        }
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (percentage >= 98) {
          _star3Controller.forward();
        }
      });
    }
    _visibleMessage = _scrambleMessage(_decodedMessage).toUpperCase();

    if ((widget.level >= 2 && widget.level <= 4) || (widget.level >= 6 && widget.level <= 9) || (widget.level >= 11 && widget.level <= 14) || (widget.level >= 16 && widget.level <= 19)) {
      if (percentage < 50) {
        _isDecoding = false;
      } else {
        _isDecoding = true;
        _decodingStep = DecodingStep.complete; // Skip to the end for non-decoding levels
      }
    }
  }

  String _scrambleMessage(String message) {
    List<String> characters = message.split('');
    characters.shuffle();
    return characters.join('');
  }

  void _decode() {
    setState(() {
      _isDecoding = true;
    });

    Timer(const Duration(seconds: 2), () {
      setState(() {
        _decodingStep = DecodingStep.shuffling;
      });

      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_decodingStep != DecodingStep.shuffling) {
          timer.cancel();
          return;
        }
        setState(() {
          _visibleMessage = _scrambleMessage(_decodedMessage).toUpperCase();
        });
      });
    });

    Timer(const Duration(seconds: 4), () {
      setState(() {
        _decodingStep = DecodingStep.revealing;
      });

      final percentage = widget.totalPellets > 0 ? (widget.score / widget.totalPellets) * 100 : 0;
      final int decodedLength = (_decodedMessage.length * (percentage / 100)).floor();
      int charsRevealed = 0;

      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (charsRevealed >= decodedLength) {
          timer.cancel();
          setState(() {
            _decodingStep = DecodingStep.complete;
            _visibleMessage = _decodedMessage;
          });
          return;
        }

        charsRevealed++;
        final revealedPart = _decodedMessage.substring(0, charsRevealed);
        final remainingPart = '*' * (_decodedMessage.length - charsRevealed);
        setState(() {
          _visibleMessage = revealedPart + remainingPart;
        });
      });
    });
  }

  @override
  void dispose() {
    _star1Controller.dispose();
    _star2Controller.dispose();
    _star3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.totalPellets > 0 ? (widget.score / widget.totalPellets) * 100 : 0).toDouble();
    final bool failed = percentage < 50;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0c0a1f).withOpacity(0.8),
      ),
      child: Center(
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Colors.cyanAccent,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.5),
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: _isDecoding ? _buildDecodingView(failed) : _buildInitialView(failed, percentage),
        ),
      ),
    );
  }

  Widget _buildInitialView(bool failed, double percentage) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            failed ? 'Transmission Failed' : 'Finished',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32.0,
              fontFamily: 'Orbitron',
              shadows: [
                Shadow(
                  color: Colors.cyanAccent,
                  blurRadius: 5.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40.0),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80.0,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.cyanAccent,
                  blurRadius: 10.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          if (failed)
            ElevatedButton(
              onPressed: widget.onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                ),
                shadowColor: Colors.cyanAccent,
                elevation: 10.0,
              ),
              child: const Text(
                'Retry Again',
                style: TextStyle(
                  fontSize: 20.0,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _star1Controller,
                  child: const Icon(Icons.star, color: Colors.yellow, size: 80.0),
                ),
                ScaleTransition(
                  scale: _star2Controller,
                  child: const Icon(Icons.star, color: Colors.yellow, size: 80.0),
                ),
                ScaleTransition(
                  scale: _star3Controller,
                  child: const Icon(Icons.star, color: Colors.yellow, size: 80.0),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            if (widget.level == 1 || widget.level == 5 || widget.level == 10 || widget.level == 15 || widget.level == 20) ...[
              const Text(
                'You received an encoded message from planet Cygnus Gamma-9',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontFamily: 'Orbitron',
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent,
                      blurRadius: 5.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _decode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                  ),
                  shadowColor: Colors.cyanAccent,
                  elevation: 10.0,
                ),
                child: const Text(
                  'Decode',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Great Job!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontFamily: 'Orbitron',
                  shadows: [
                    Shadow(
                      color: Colors.greenAccent,
                      blurRadius: 5.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: widget.onNextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                  ),
                  shadowColor: Colors.cyanAccent,
                  elevation: 10.0,
                ),
                child: const Text(
                  'Next Level',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDecodingView(bool failed) {
    final percentage = (widget.totalPellets > 0 ? (widget.score / widget.totalPellets) * 100 : 0).toDouble();
    final int decodedLength = (_decodedMessage.length * (percentage / 100)).floor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_decodingStep != DecodingStep.complete)
          Text(
            _visibleMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontFamily: 'Orbitron',
              shadows: [
                Shadow(
                  color: Colors.cyanAccent,
                  blurRadius: 5.0,
                ),
              ],
            ),
          ),
        if (_decodingStep == DecodingStep.complete)
          Column(
            children: [
              if (((widget.level >= 2 && widget.level <= 4) || (widget.level >= 6 && widget.level <= 9) || (widget.level >= 11 && widget.level <= 14) || (widget.level >= 16 && widget.level <= 19)) && !failed) ...[
                const Text(
                  'Great Job!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontFamily: 'Orbitron',
                    shadows: [
                      Shadow(
                        color: Colors.greenAccent,
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (!failed) ...[
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontFamily: 'Orbitron',
                    ),
                    children: [
                      TextSpan(
                        text: _visibleMessage.substring(0, decodedLength),
                        style: const TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: '*' * (_visibleMessage.length - decodedLength),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Based on the collected pallets only ${percentage.toStringAsFixed(0)}% of the message is decoded.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16.0,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 20.0),
        if (_decodingStep == DecodingStep.complete || failed)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: widget.onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                  ),
                  shadowColor: Colors.cyanAccent,
                  elevation: 10.0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              if (!failed) ...[
                ElevatedButton(
                  onPressed: widget.onNextLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Colors.cyanAccent, width: 2.0),
                    ),
                    shadowColor: Colors.cyanAccent,
                    elevation: 10.0,
                  ),
                  child: Text(
                    widget.level < 20 ? 'Next Level' : 'Play Again',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]
            ],
          ),
      ],
    );
  }
}
