// lib/bg_service.dart
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fft;

/// Clés partagées avec main.dart
const _kIsRunning   = 'gym.isRunning';
const _kElapsedMs   = 'gym.elapsedMs';
const _kLastEpochMs = 'gym.lastEpochMs';

Future<void> gymSetRunning(bool running) async {
  final p   = await SharedPreferences.getInstance();
  final now = DateTime.now().millisecondsSinceEpoch;
  final base = p.getInt(_kElapsedMs) ?? 0;
  final last = p.getInt(_kLastEpochMs) ?? now;

  if (running) {
    // démarrage/reprise
    await p.setInt(_kLastEpochMs, now);
    await p.setBool(_kIsRunning, true);
  } else {
    // arrêt → fige et CAP à 6:00
    final delta   = now - last;
    final newBase = (base + (delta > 0 ? delta : 0)).clamp(0, 360000);
    await p.setInt(_kElapsedMs, newBase);
    await p.setInt(_kLastEpochMs, now);
    await p.setBool(_kIsRunning, false);
  }
}

Future<void> gymReset() async {
  final p = await SharedPreferences.getInstance();
  final now = DateTime.now().millisecondsSinceEpoch;
  await p.setInt(_kElapsedMs, 0);
  await p.setInt(_kLastEpochMs, now);
  await p.setBool(_kIsRunning, false);
}

class GymTaskHandler extends fft.TaskHandler {
  SendPort? _sendPort;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    // Rien de spécial ici : la notif sera tenue à jour dans onRepeatEvent.
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Tick toutes les 1000 ms (configuré dans main.dart → ForegroundTaskOptions.interval=1000)
    final p   = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    final running = p.getBool(_kIsRunning) ?? false;
    final baseMs  = p.getInt(_kElapsedMs) ?? 0;
    final lastMs  = p.getInt(_kLastEpochMs) ?? now;

    // Temps effectif: base + (si running) temps depuis le dernier départ
    final effMs = running ? (baseMs + (now - lastMs)) : baseMs;
    final capped = effMs.clamp(0, 360000);

    // Optionnel: auto-coupe si on a atteint 6:00 côté service
    if (running && capped >= 360000) {
      await p.setBool(_kIsRunning, false);
      await p.setInt(_kElapsedMs, 360000);
    }

    // Envoi au process UI
    _sendPort?.send({'elapsedMs': capped, 'running': p.getBool(_kIsRunning) ?? false});
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Nettoyage si besoin
  }
}
