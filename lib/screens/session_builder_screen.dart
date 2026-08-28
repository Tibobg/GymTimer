import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../services/catalog_service.dart';
import '../services/workout_service.dart';

class SessionBuilderScreen extends StatefulWidget {
  final WorkoutPlan? planToEdit;
  const SessionBuilderScreen({super.key, this.planToEdit});
  @override
  State<SessionBuilderScreen> createState() => _SessionBuilderScreenState();
}

class _SessionBuilderScreenState extends State<SessionBuilderScreen> {
  final List<PlannedExercise> _selected = [];
  final _nameCtrl = TextEditingController();
  int? _weekday;
  String _selectedCategory = 'Tous';

  @override
  void initState() {
    super.initState();
    final edit = widget.planToEdit;
    if (edit != null) {
      _nameCtrl.text = edit.name;
      _weekday = edit.weekday;
      for (final g in edit.groups) {
        _selected.addAll(g.exercises);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Tous', ...CatalogService.categories];
    final exercises =
        _selectedCategory == 'Tous'
            ? CatalogService.all
            : CatalogService.byCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.planToEdit != null ? 'Modifier la séance' : 'Créer une séance',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la séance',
                    hintText: 'Ex: Lundi • Jambes',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Jour (optionnel)',
                  ),
                  value: _weekday,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Libre')),
                    ...List.generate(
                      7,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          [
                            'Lundi',
                            'Mardi',
                            'Mercredi',
                            'Jeudi',
                            'Vendredi',
                            'Samedi',
                            'Dimanche',
                          ][i],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _weekday = v),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child:
                _selected.isEmpty
                    ? const Center(
                      child: Text(
                        'Ajoute des exercices depuis le catalogue',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                    : ReorderableListView(
                      onReorder:
                          (oldI, newI) => setState(() {
                            if (newI > oldI) newI--;
                            final item = _selected.removeAt(oldI);
                            _selected.insert(newI, item);
                          }),
                      children:
                          _selected
                              .asMap()
                              .entries
                              .map(
                                (e) => ListTile(
                                  key: ValueKey(e.value.exerciseId),
                                  dense: true,
                                  title: Text(
                                    e.value.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () => _selected.removeAt(e.key),
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              children:
                  categories
                      .map(
                        (cat) => ChoiceChip(
                          label: Text(
                            cat,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _selectedCategory == cat,
                          onSelected:
                              (_) => setState(() => _selectedCategory = cat),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, i) {
                final ex = exercises[i];
                final alreadyAdded = _selected.any(
                  (s) => s.exerciseId == ex.id,
                );
                return ListTile(
                  dense: true,
                  leading:
                      ex.imageAsset != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              ex.imageAsset!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(Icons.fitness_center, size: 20),
                  title: Text(ex.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    ex.category,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  trailing:
                      alreadyAdded
                          ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                          : IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            onPressed:
                                () => setState(
                                  () => _selected.add(
                                    PlannedExercise(
                                      exerciseId: ex.id,
                                      name: ex.name,
                                      imageAsset: ex.imageAsset,
                                      targetWeight: ex.defaultWeight,
                                    ),
                                  ),
                                ),
                          ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder la séance'),
                onPressed:
                    _selected.isEmpty || _nameCtrl.text.trim().isEmpty
                        ? null
                        : () async {
                          final plan = WorkoutPlan(
                            id:
                                widget.planToEdit?.id ??
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            name: _nameCtrl.text.trim(),
                            weekday: _weekday,
                            groups: [
                              MuscleGroup(
                                name: 'Séance',
                                exercises: List.from(_selected),
                              ),
                            ],
                            createdAt:
                                widget.planToEdit?.createdAt ?? DateTime.now(),
                            isCustom: true,
                          );
                          if (widget.planToEdit != null) {
                            await WorkoutService.updatePlan(plan);
                          } else {
                            await WorkoutService.addPlan(plan);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Séance sauvegardée'),
                              ),
                            );
                          }
                        },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
