class WorkoutPlan {
  final String id;
  final String name;
  final int? weekday;
  final List<MuscleGroup> groups;
  final DateTime createdAt;
  final bool isCustom;

  WorkoutPlan({
    required this.id,
    required this.name,
    this.weekday,
    required this.groups,
    required this.createdAt,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weekday': weekday,
    'groups': groups.map((g) => g.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'isCustom': isCustom,
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    id: json['id'],
    name: json['name'],
    weekday: json['weekday'],
    groups:
        (json['groups'] as List).map((e) => MuscleGroup.fromJson(e)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
    isCustom: json['isCustom'] ?? false,
  );
}

class MuscleGroup {
  final String name;
  final List<PlannedExercise> exercises;
  MuscleGroup({required this.name, required this.exercises});

  Map<String, dynamic> toJson() => {
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory MuscleGroup.fromJson(Map<String, dynamic> json) => MuscleGroup(
    name: json['name'],
    exercises:
        (json['exercises'] as List)
            .map((e) => PlannedExercise.fromJson(e))
            .toList(),
  );
}

class PlannedExercise {
  final String exerciseId;
  final String name;
  final String? imageAsset;
  double? targetWeight;

  PlannedExercise({
    required this.exerciseId,
    required this.name,
    this.imageAsset,
    this.targetWeight,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'imageAsset': imageAsset,
    'targetWeight': targetWeight,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) =>
      PlannedExercise(
        exerciseId: json['exerciseId'],
        name: json['name'],
        imageAsset: json['imageAsset'],
        targetWeight:
            json['targetWeight'] != null
                ? (json['targetWeight'] as num).toDouble()
                : null,
      );
}
