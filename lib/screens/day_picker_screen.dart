import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../services/workout_service.dart';
import 'workout_screen.dart';
import 'session_builder_screen.dart';
import 'settings_page.dart';
import 'history_screen.dart';

class DayPickerScreen extends StatefulWidget {
  const DayPickerScreen({super.key});
  @override
  State<DayPickerScreen> createState() => _DayPickerScreenState();
}

class _DayPickerScreenState extends State<DayPickerScreen> {
  List<WorkoutPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await WorkoutService.loadPlans();
    setState(() => _plans = plans);
  }

  Future<void> _deletePlan(String id) async {
    await WorkoutService.deletePlan(id);
    _load();
  }

  Future<void> _confirmDelete(BuildContext context, WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Supprimer la séance'),
            content: Text('Supprimer "${plan.name}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await _deletePlan(plan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <int, List<WorkoutPlan>>{};
    for (final p in _plans.where((p) => p.weekday != null)) {
      byDay.putIfAbsent(p.weekday!, () => []).add(p);
    }
    final freePlans = _plans.where((p) => p.weekday == null).toList();
    const dayNames = [
      '',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une séance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            ...(byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
                .map((e) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          dayNames[e.key],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      ...e.value.map(
                        (plan) => _PlanTile(
                          plan: plan,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutScreen(plan: plan),
                                ),
                              ),
                          onEdit:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SessionBuilderScreen(
                                        planToEdit: plan,
                                      ),
                                ),
                              ).then((_) => _load()),
                          onLongPress:
                              plan.isCustom
                                  ? () => _confirmDelete(context, plan)
                                  : null,
                        ),
                      ),
                    ],
                  );
                }),
            if (freePlans.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Séances libres',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              ...freePlans.map(
                (plan) => _PlanTile(
                  plan: plan,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(plan: plan),
                        ),
                      ),
                  onEdit:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SessionBuilderScreen(planToEdit: plan),
                        ),
                      ).then((_) => _load()),
                  onLongPress:
                      plan.isCustom
                          ? () => _confirmDelete(context, plan)
                          : null,
                ),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.greenAccent),
              title: const Text('Créer une séance'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SessionBuilderScreen(),
                    ),
                  ).then((_) => _load()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  const _PlanTile({
    required this.plan,
    required this.onTap,
    this.onEdit,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.fitness_center),
      title: Text(plan.name),
      subtitle: Text(
        '${plan.groups.expand((g) => g.exercises).length} exercices',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
              onPressed: onEdit,
            ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
