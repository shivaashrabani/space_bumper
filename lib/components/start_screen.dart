import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onStartPressed;

  const StartScreen({super.key, required this.onStartPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0c0a1f).withOpacity(0.8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
              child: const Text(
                'Planet : URGENT: Transmission is failing Cygnus Gamma-9 (47,000 Light Years from Sol). Stabilize the Conduit. Route the Pallets to the Receiver. Our message depends on your aim.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontFamily: 'Orbitron', // Assuming Orbitron font is added to the project
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent,
                      blurRadius: 5.0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: onStartPressed,
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
                'Start',
                style: TextStyle(
                  fontSize: 20.0,
                  fontFamily: 'Orbitron', // Assuming Orbitron font is added to the project
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}