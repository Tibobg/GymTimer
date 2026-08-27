import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/catalog_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final exercises = CatalogService.all;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Entraînement',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Repos entre exercices'),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              showValueIndicator: ShowValueIndicator.always,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Builder(
              builder: (_) {
                final minutes = s.restSeconds / 60.0;
                String label(double m) {
                  final total = (m * 60).round();
                  final mm = total ~/ 60;
                  final ss = total % 60;
                  return ss == 0
                      ? '${mm}m'
                      : '${mm}m${ss.toString().padLeft(2, '0')}s';
                }

                return Slider(
                  value: minutes.clamp(0, 10),
                  min: 0,
                  max: 10,
                  divisions: 40,
                  label: label(minutes),
                  onChanged: (m) => s.setRestSeconds((m * 60).round()),
                );
              },
            ),
          ),
          const Divider(),
          const Text(
            'Jours d\'entraînement',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
              final d = i + 1;
              return ChoiceChip(
                label: Text(labels[i]),
                selected: s.trainingDays.contains(d),
                onSelected: (_) => s.toggleTrainingDay(d),
              );
            }),
          ),
          const Divider(),
          const Text(
            'Poids cibles par exercice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...exercises.map((ex) {
            final current = s.getWeight(ex.name)?.toStringAsFixed(1) ?? '—';
            return ListTile(
              dense: true,
              leading:
                  ex.imageAsset != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          ex.imageAsset!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                      : const Icon(Icons.fitness_center, size: 18),
              title: Text(ex.name, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                'Poids cible : $current kg',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () async {
                  final newKg = await _askKg(
                    context,
                    s.getWeight(ex.name) ?? 0,
                  );
                  if (newKg == double.negativeInfinity) {
                    await s.setWeight(ex.name, null);
                  } else if (newKg != null) {
                    await s.setWeight(ex.name, newKg);
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Future<double?> _askKg(BuildContext ctx, double initial) async {
  final ctrl = TextEditingController(text: initial.toStringAsFixed(1));
  double kg = initial;

  String normalize(String v) {
    v = v.replaceAll(',', '.').trim();
    return v;
  }

  return showDialog<double>(
    context: ctx,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSt) {
          void applyDelta(double d) {
            setSt(() {
              kg = (double.tryParse(normalize(ctrl.text)) ?? kg) + d;
              kg = kg.clamp(0, 999);
              ctrl.text = kg.toStringAsFixed(1);
              ctrl.selection = TextSelection.collapsed(
                offset: ctrl.text.length,
              );
            });
          }

          return AlertDialog(
            title: const Text('Définir poids cible'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                  ],
                  decoration: const InputDecoration(
                    prefixText: 'kg ',
                    hintText: 'Ex. 37,5',
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(normalize(v));
                    setSt(() {
                      if (val != null) kg = val.clamp(0, 999);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '-0,5 kg',
                      onPressed: () => applyDelta(-0.5),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '${kg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      tooltip: '+0,5 kg',
                      onPressed: () => applyDelta(0.5),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, double.negativeInfinity),
                child: const Text('Effacer'),
              ),
              FilledButton(
                onPressed: () {
                  final val = double.tryParse(normalize(ctrl.text)) ?? kg;
                  Navigator.pop(context, val.clamp(0, 999));
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}
