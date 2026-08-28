import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bg_service.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const _BubbleApp());
}

class _BubbleApp extends StatefulWidget {
  const _BubbleApp();
  @override
  State<_BubbleApp> createState() => _BubbleAppState();
}

class _BubbleAppState extends State<_BubbleApp> {
  Timer? _poll;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    debugPrint('=== OVERLAY: initState ===');
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) => _update());
  }

  Future<void> _update() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final running = p.getBool('gym.isRunning') ?? false;
    final baseMs = p.getInt('gym.elapsedMs') ?? 0;
    final lastMs =
        p.getInt('gym.lastEpochMs') ?? DateTime.now().millisecondsSinceEpoch;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final effMs = running ? (baseMs + (nowMs - lastMs)) : baseMs;
    final capped = effMs.clamp(0, 360000);
    if (mounted) {
      setState(() {
        _isRunning = running;
        _elapsed = Duration(milliseconds: capped);
      });
    }
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _toggle() async {
    await gymSetRunning(!_isRunning);
    await _update();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== OVERLAY: build ===');
    return Material(
      color: Colors.black87,
      child: InkWell(
        onTap: _toggle,
        child: Container(
          width: 140,
          height: 56,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _fmt(_elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isRunning ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
