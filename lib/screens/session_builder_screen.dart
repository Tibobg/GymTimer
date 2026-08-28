import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise.dart';
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

  Future<void> _showAddExerciseDialog() async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    String? imagePath;

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setSt) {
              return AlertDialog(
                title: const Text('Nouvel exercice'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      TextField(
                        controller: catCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                        ),
                      ),
                      TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Poids par défaut (kg)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (imagePath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imagePath!),
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.image),
                        label: Text(
                          imagePath != null
                              ? 'Changer l\'image'
                              : 'Choisir une image',
                        ),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            final saved =
                                await CatalogService.saveImageToAppDir(
                                  File(picked.path),
                                );
                            setSt(() => imagePath = saved);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final cat = catCtrl.text.trim();
                      if (name.isEmpty || cat.isEmpty) return;
                      final w =
                          double.tryParse(
                            weightCtrl.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      final ex = Exercise(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        category: cat,
                        imageAsset: imagePath,
                        defaultWeight: w > 0 ? w : null,
                      );
                      await CatalogService.addCustom(ex);
                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                    child: const Text('Ajouter'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _exerciseImage(String? path, {double size = 40}) {
    if (path == null) return const Icon(Icons.fitness_center, size: 20);
    if (path.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(path, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: 'Nouvel exercice',
            onPressed: _showAddExerciseDialog,
          ),
        ],
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
                  leading: _exerciseImage(ex.imageAsset, size: 40),
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
