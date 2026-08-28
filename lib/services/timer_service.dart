import 'dart:async';
import 'dart:math';
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
  int _restMs = 90000;

  Duration get elapsed => _elapsed;
  bool get isRunning => _isRunning;
  int get pausesDone => _pausesDone;
  int get capMs => _restMs * 3;

  int get currentSerie {
    final secs = _elapsed.inSeconds;
    final restSec = _restMs ~/ 1000;
    if (secs < restSec) return 1;
    if (secs < restSec * 2) return 2;
    if (secs < restSec * 3) return 3;
    return 4;
  }

  Future<void> _loadState() async {
    final p = await SharedPreferences.getInstance();
    _lastStopIdx = p.getInt(_kLastStopIdx) ?? 0;
    _restMs = (p.getInt('rest_seconds') ?? 90) * 1000;
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
    final newBase = (base + (delta > 0 ? delta : 0)).clamp(0, capMs);
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

  void init() async {
    await _loadState();
    _poll = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final running = p.getBool(_kIsRunning) ?? false;
      final baseMs = p.getInt(_kElapsedMs) ?? 0;
      final lastMs =
          p.getInt(_kLastEpochMs) ?? DateTime.now().millisecondsSinceEpoch;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final effMs = running ? (baseMs + (nowMs - lastMs)) : baseMs;
      final capped = min(effMs, capMs);
      final secs = capped ~/ 1000;
      final restSec = _restMs ~/ 1000;

      _pausesDone =
          (secs >= restSec * 3)
              ? 3
              : (secs >= restSec * 2)
              ? 2
              : (secs >= restSec)
              ? 1
              : 0;

      final stops = [_restMs, _restMs * 2];
      if (_lastStopIdx < stops.length &&
          capped >= stops[_lastStopIdx] &&
          capped < capMs) {
        _lastStopIdx++;
        await p.setInt(_kLastStopIdx, _lastStopIdx);
        await pause();
        onPause?.call();
      }

      if (secs >= restSec * 3 && running) {
        await pause();
        _elapsed = Duration(milliseconds: capMs);
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
  VoidCallback? onPause;
}
