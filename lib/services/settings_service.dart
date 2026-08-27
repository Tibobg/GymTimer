import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _kWeights = 'weights_by_exercise';
  static const _kRestSec = 'rest_seconds';
  static const _kDays = 'training_days';

  Map<String, double> _weights = {};
  int _restSeconds = 0;
  Set<int> _trainingDays = {1, 2, 3, 5, 7};

  double? getWeight(String name) => _weights[name];
  int get restSeconds => _restSeconds;
  Set<int> get trainingDays => _trainingDays;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final w = sp.getString(_kWeights);
    if (w != null && w.isNotEmpty) {
      final raw = jsonDecode(w) as Map<String, dynamic>;
      _weights = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    _restSeconds = sp.getInt(_kRestSec) ?? 0;
    final d = sp.getString(_kDays);
    if (d != null) _trainingDays = Set<int>.from(jsonDecode(d));
    notifyListeners();
  }

  Future<void> setWeight(String name, double? kg) async {
    final sp = await SharedPreferences.getInstance();
    if (kg == null) {
      _weights.remove(name);
    } else {
      _weights[name] = double.parse(kg.toStringAsFixed(1));
    }
    await sp.setString(_kWeights, jsonEncode(_weights));
    notifyListeners();
  }

  Future<void> adjustWeight(String name, double delta) async {
    final current = getWeight(name) ?? 0;
    final newWeight = (current + delta).clamp(0.0, 999.0);
    await setWeight(name, newWeight);
  }

  Future<void> setRestSeconds(int s) async {
    final sp = await SharedPreferences.getInstance();
    _restSeconds = s.clamp(0, 600);
    await sp.setInt(_kRestSec, _restSeconds);
    notifyListeners();
  }

  Future<void> toggleTrainingDay(int d) async {
    final sp = await SharedPreferences.getInstance();
    _trainingDays.contains(d) ? _trainingDays.remove(d) : _trainingDays.add(d);
    await sp.setString(_kDays, jsonEncode(_trainingDays.toList()..sort()));
    notifyListeners();
  }
}
