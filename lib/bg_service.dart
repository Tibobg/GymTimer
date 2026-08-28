import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(GymTimerTaskHandler());
}

class GymTimerTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final running = p.getBool('gym.isRunning') ?? false;
      final baseMs = p.getInt('gym.elapsedMs') ?? 0;
      final lastMs =
          p.getInt('gym.lastEpochMs') ?? DateTime.now().millisecondsSinceEpoch;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final effMs = running ? (baseMs + (nowMs - lastMs)) : baseMs;
      final capped = effMs.clamp(0, 360000);
      final d = Duration(milliseconds: capped);
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      FlutterForegroundTask.updateService(
        notificationTitle: 'Gym Timer — $mm:$ss',
        notificationText: running ? 'Chrono en cours' : 'En pause',
      );
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _timer?.cancel();
  }

  @override
  void onButtonPressed(String id) async {
    final p = await SharedPreferences.getInstance();
    if (id == 'toggle') {
      final running = p.getBool('gym.isRunning') ?? false;
      await gymSetRunning(!running);
    } else if (id == 'reset') {
      final now = DateTime.now().millisecondsSinceEpoch;
      await p.setInt('gym.elapsedMs', 0);
      await p.setInt('gym.lastEpochMs', now);
      await p.setBool('gym.isRunning', false);
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}
}

Future<void> gymSetRunning(bool running) async {
  final p = await SharedPreferences.getInstance();
  final now = DateTime.now().millisecondsSinceEpoch;
  if (running) {
    await p.setInt('gym.lastEpochMs', now);
    await p.setBool('gym.isRunning', true);
  } else {
    final base = p.getInt('gym.elapsedMs') ?? 0;
    final last = p.getInt('gym.lastEpochMs') ?? now;
    final delta = now - last;
    final newBase = (base + (delta > 0 ? delta : 0)).clamp(0, 360000);
    await p.setInt('gym.elapsedMs', newBase);
    await p.setInt('gym.lastEpochMs', now);
    await p.setBool('gym.isRunning', false);
  }
}
