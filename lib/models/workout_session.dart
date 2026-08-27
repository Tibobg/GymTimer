class WorkoutSession {
  final String id;
  final String planName;
  final DateTime date;
  final int durationSeconds;
  final List<SessionExercise> exercises;

  WorkoutSession({
    required this.id,
    required this.planName,
    required this.date,
    required this.durationSeconds,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'planName': planName,
    'date': date.toIso8601String(),
    'durationSeconds': durationSeconds,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'],
    planName: json['planName'],
    date: DateTime.parse(json['date']),
    durationSeconds: json['durationSeconds'],
    exercises:
        (json['exercises'] as List)
            .map((e) => SessionExercise.fromJson(e))
            .toList(),
  );
}

class SessionExercise {
  final String name;
  final double? weightUsed;
  final int seriesCompleted;
  final int durationSeconds;

  SessionExercise({
    required this.name,
    this.weightUsed,
    required this.seriesCompleted,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weightUsed': weightUsed,
    'seriesCompleted': seriesCompleted,
    'durationSeconds': durationSeconds,
  };

  factory SessionExercise.fromJson(Map<String, dynamic> json) =>
      SessionExercise(
        name: json['name'],
        weightUsed:
            json['weightUsed'] != null
                ? (json['weightUsed'] as num).toDouble()
                : null,
        seriesCompleted: json['seriesCompleted'],
        durationSeconds: json['durationSeconds'],
      );
}
