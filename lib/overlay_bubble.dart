// lib/overlay_bubble.dart
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const _BubbleApp());
}

class _BubbleApp extends StatelessWidget {
  const _BubbleApp();

  @override
  Widget build(BuildContext context) {
    // App ultra simple: un cercle visible, sans transparence totale
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // Pas de AppBar, fond légèrement transparent pour bien voir la bulle
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.blueAccent, // visible !
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '●',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
