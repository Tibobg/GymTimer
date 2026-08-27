import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/workout_service.dart';
import '../services/truenas_service.dart';

class HistoryScreen extends StatefulWidget {
  final TrueNasService? nasService;
  const HistoryScreen({super.key, this.nasService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutSession> _history = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await WorkoutService.loadHistory();
    setState(() => _history = h);
  }

  Future<void> _syncToNas() async {
    if (widget.nasService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('NAS non configuré')));
      return;
    }
    setState(() => _syncing = true);
    final ok = await widget.nasService!.syncHistory(_history);
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Sync NAS OK' : 'Échec sync NAS')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          if (widget.nasService != null)
            IconButton(
              icon:
                  _syncing
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.cloud_upload),
              onPressed: _syncing ? null : _syncToNas,
            ),
        ],
      ),
      body:
          _history.isEmpty
              ? const Center(child: Text('Aucune séance enregistrée'))
              : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, i) {
                  final s = _history[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(s.planName),
                      subtitle: Text(
                        '${s.date.day.toString().padLeft(2, '0')}/${s.date.month.toString().padLeft(2, '0')}/${s.date.year} — ${s.durationSeconds ~/ 60}min ${s.durationSeconds % 60}s',
                      ),
                      trailing: Text('${s.exercises.length} exos'),
                    ),
                  );
                },
              ),
    );
  }
}
