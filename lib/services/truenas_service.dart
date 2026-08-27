import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_session.dart';

class TrueNasService {
  final String baseUrl;
  final String? apiKey;

  TrueNasService({required this.baseUrl, this.apiKey});

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (apiKey != null && apiKey!.isNotEmpty)
      h['Authorization'] = 'Bearer $apiKey';
    return h;
  }

  Future<bool> syncHistory(List<WorkoutSession> sessions) async {
    try {
      final body = jsonEncode(sessions.map((s) => s.toJson()).toList());
      final response = await http.post(
        Uri.parse('$baseUrl/api/history'),
        headers: _headers,
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<WorkoutSession>> fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => WorkoutSession.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
