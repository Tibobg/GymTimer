import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import 'catalog_service.dart';
import '../models/exercise.dart';

class WorkoutService {
  static const _kPlans = 'workout_plans_v2';
  static const _kHistory = 'workout_history_v2';

  static Future<List<WorkoutPlan>> loadPlans() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kPlans);
    if (raw == null || raw.isEmpty) {
      final defaults = _defaultPlans();
      await savePlans(defaults);
      return defaults;
    }
    try {
      final list = jsonDecode(raw) as List;
      final plans = list.map((e) => WorkoutPlan.fromJson(e)).toList();

      bool migrated = false;
      for (int i = 0; i < plans.length; i++) {
        final plan = plans[i];
        if (plan.groups.length == 1 && plan.groups.first.name == 'Séance') {
          final map = <String, List<PlannedExercise>>{};
          for (final ex in plan.groups.first.exercises) {
            final cat = CatalogService.byId(ex.exerciseId)?.category ?? 'Autre';
            map.putIfAbsent(cat, () => []).add(ex);
          }
          if (map.length > 1) {
            plans[i] = WorkoutPlan(
              id: plan.id,
              name: plan.name,
              weekday: plan.weekday,
              groups:
                  map.entries
                      .map((e) => MuscleGroup(name: e.key, exercises: e.value))
                      .toList(),
              createdAt: plan.createdAt,
              isCustom: plan.isCustom,
            );
            migrated = true;
          }
        }
      }
      if (migrated) await savePlans(plans);
      return plans;
    } catch (_) {
      final defaults = _defaultPlans();
      await savePlans(defaults);
      return defaults;
    }
  }

  static Future<void> savePlans(List<WorkoutPlan> plans) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kPlans,
      jsonEncode(plans.map((p) => p.toJson()).toList()),
    );
  }

  static Future<void> deletePlan(String id) async {
    final plans = await loadPlans();
    plans.removeWhere((p) => p.id == id);
    await savePlans(plans);
  }

  static Future<void> addPlan(WorkoutPlan plan) async {
    final plans = await loadPlans();
    plans.add(plan);
    await savePlans(plans);
  }

  static Future<void> updatePlan(WorkoutPlan plan) async {
    final plans = await loadPlans();
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      plans[idx] = plan;
      await savePlans(plans);
    }
  }

  static List<WorkoutPlan> _defaultPlans() {
    final ex = CatalogService.all;
    Exercise find(String id) => ex.firstWhere((e) => e.id == id);
    PlannedExercise p(String id) {
      final e = find(id);
      return PlannedExercise(
        exerciseId: e.id,
        name: e.name,
        imageAsset: e.imageAsset,
        targetWeight: e.defaultWeight,
      );
    }

    return [
      WorkoutPlan(
        id: 'default_monday',
        name: 'Lundi • Jambes',
        weekday: DateTime.monday,
        groups: [
          MuscleGroup(
            name: 'Jambes',
            exercises: [
              p('leg_press'),
              p('leg_extension'),
              p('leg_curl'),
              p('hip_thrust'),
              p('adductor'),
              p('abductor'),
              p('mollet_press'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      WorkoutPlan(
        id: 'default_tuesday',
        name: 'Mardi • Abdos',
        weekday: DateTime.tuesday,
        groups: [
          MuscleGroup(name: 'Abdos', exercises: [p('circuit_abdos')]),
        ],
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      WorkoutPlan(
        id: 'default_wednesday',
        name: 'Mercredi • Pecs/Dos',
        weekday: DateTime.wednesday,
        groups: [
          MuscleGroup(
            name: 'Pectoraux',
            exercises: [
              p('dev_incline_hal'),
              p('chest_press'),
              p('dev_decline_hal'),
              p('ecarte_poulie'),
            ],
          ),
          MuscleGroup(
            name: 'Dos',
            exercises: [
              p('tirage_vert'),
              p('rowing_uni'),
              p('low_row'),
              p('tirage_horiz'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      WorkoutPlan(
        id: 'default_friday',
        name: 'Vendredi • Épaules/Biceps',
        weekday: DateTime.friday,
        groups: [
          MuscleGroup(
            name: 'Épaules',
            exercises: [
              p('shoulder_press'),
              p('ele_lat_hal'),
              p('ele_front_hal'),
              p('oiseau_incline'),
              p('shrugs'),
            ],
          ),
          MuscleGroup(
            name: 'Biceps',
            exercises: [
              p('curl_incline'),
              p('curl_marteau'),
              p('curl_poulie_basse'),
              p('curl_inverse'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isCustom: false,
      ),
      WorkoutPlan(
        id: 'default_sunday',
        name: 'Dimanche • Triceps/Avant-bras',
        weekday: DateTime.sunday,
        groups: [
          MuscleGroup(
            name: 'Triceps',
            exercises: [
              p('overhead_poulie'),
              p('poulie_barre'),
              p('poulie_corde'),
              p('poulie_mousqueton'),
            ],
          ),
          MuscleGroup(
            name: 'Avant-bras',
            exercises: [
              p('curl_conc_prone'),
              p('flex_poignet_dos'),
              p('ext_poignet'),
              p('rot_poignet'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isCustom: false,
      ),
    ];
  }

  static Future<List<WorkoutSession>> loadHistory() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kHistory);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => WorkoutSession.fromJson(e)).toList();
  }

  static Future<void> saveSession(WorkoutSession session) async {
    final history = await loadHistory();
    history.insert(0, session);
    if (history.length > 200) history.removeRange(200, history.length);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kHistory,
      jsonEncode(history.map((s) => s.toJson()).toList()),
    );
  }

  static Future<void> clearHistory() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kHistory);
  }
}
