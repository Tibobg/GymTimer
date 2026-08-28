import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService extends ChangeNotifier {
  static const _kIsRunning = 'gym.isRunning';
  static const _kElapsedMs = 'gym.elapsedMs';
  static const _kLastEpochMs = 'gym.lastEpochMs';
  static const _kLastStopIdx = 'gym.lastStopIdx';

  Timer? _poll;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  int _lastStopIdx = 0;
  int _pausesDone = 0;

  Duration get elapsed => _elapsed;
  bool get isRunning => _isRunning;
  int get pausesDone => _pausesDone;

  static const totalCycle = Duration(minutes: 6);
  int get capMs => totalCycle.inMilliseconds;

  int get currentSerie {
    final secs = _elapsed.inSeconds;
    if (secs < 90) return 1;
    if (secs < 180) return 2;
    if (secs < 270) return 3;
    return 4;
  }

  Future<void> _loadState() async {
    final p = await SharedPreferences.getInstance();
    _lastStopIdx = p.getInt(_kLastStopIdx) ?? 0;
  }

  Future<void> start() async {
    if (_isRunning) return;
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await p.setInt(_kLastEpochMs, now);
    await p.setBool(_kIsRunning, true);
    _isRunning = true;
    notifyListeners();
  }

  Future<void> pause() async {
    if (!_isRunning) return;
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = p.getInt(_kElapsedMs) ?? 0;
    final last = p.getInt(_kLastEpochMs) ?? now;
    final delta = now - last;
    final newBase = (base + (delta > 0 ? delta : 0)).clamp(0, 360000);
    await p.setInt(_kElapsedMs, newBase);
    await p.setInt(_kLastEpochMs, now);
    await p.setBool(_kIsRunning, false);
    _isRunning = false;
    notifyListeners();
  }

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await p.setInt(_kElapsedMs, 0);
    await p.setInt(_kLastEpochMs, now);
    await p.setBool(_kIsRunning, false);
    await p.setInt(_kLastStopIdx, 0);
    _elapsed = Duration.zero;
    _isRunning = false;
    _lastStopIdx = 0;
    _pausesDone = 0;
    notifyListeners();
  }

  void init() {
    _loadState();
    _poll = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final running = p.getBool(_kIsRunning) ?? false;
      final baseMs = p.getInt(_kElapsedMs) ?? 0;
      final lastMs =
          p.getInt(_kLastEpochMs) ?? DateTime.now().millisecondsSinceEpoch;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final effMs = running ? (baseMs + (nowMs - lastMs)) : baseMs;
      final capped = effMs > capMs ? capMs : effMs;
      final secs = capped ~/ 1000;

      _pausesDone =
          (secs >= 360)
              ? 4
              : (secs >= 270)
              ? 3
              : (secs >= 180)
              ? 2
              : (secs >= 90)
              ? 1
              : 0;

      const stops = [90 * 1000, 180 * 1000, 270 * 1000];
      if (_lastStopIdx < stops.length &&
          capped >= stops[_lastStopIdx] &&
          capped < capMs) {
        _lastStopIdx++;
        await p.setInt(_kLastStopIdx, _lastStopIdx);
        await pause();
      }

      if (secs >= 360 && running) {
        await pause();
        _elapsed = totalCycle;
        notifyListeners();
        onAutoAdvance?.call();
        return;
      }

      _elapsed = Duration(milliseconds: capped);
      _isRunning = running;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  VoidCallback? onAutoAdvance;
}
