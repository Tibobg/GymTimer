import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  DateTime _focusedMonth = DateTime.now();

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

  bool _hasSession(DateTime day) {
    return _history.any(
      (s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day,
    );
  }

  void _showProgressChart() {
    final allExercises = <String>{};
    for (final s in _history) {
      for (final e in s.exercises) {
        allExercises.add(e.name);
      }
    }
    if (allExercises.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune donnée')));
      return;
    }

    String selected = allExercises.first;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setSt) {
              final spots = <FlSpot>[];
              int idx = 0;
              for (final session in _history.reversed) {
                final ex = session.exercises.firstWhere(
                  (e) => e.name == selected,
                  orElse:
                      () => SessionExercise(
                        name: '',
                        seriesCompleted: 0,
                        durationSeconds: 0,
                      ),
                );
                if (ex.weightUsed != null && ex.weightUsed! > 0) {
                  spots.add(FlSpot(idx.toDouble(), ex.weightUsed!));
                  idx++;
                }
              }

              return AlertDialog(
                title: const Text('Progression'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 320,
                  child: Column(
                    children: [
                      DropdownButton<String>(
                        value: selected,
                        isExpanded: true,
                        items:
                            allExercises
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setSt(() => selected = v!),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            spots.length < 2
                                ? const Center(
                                  child: Text('Pas assez de données'),
                                )
                                : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        barWidth: 3,
                                        color: Colors.greenAccent,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.greenAccent.withOpacity(
                                            0.15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: _showProgressChart,
          ),
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
      body: Column(
        children: [
          _CalendarHeader(
            focusedMonth: _focusedMonth,
            onPrevious:
                () => setState(
                  () =>
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      ),
                ),
            onNext:
                () => setState(
                  () =>
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      ),
                ),
          ),
          _CalendarGrid(focusedMonth: _focusedMonth, hasSession: _hasSession),
          const Divider(),
          Expanded(
            child:
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
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _CalendarHeader({
    required this.focusedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            '${monthNames[focusedMonth.month - 1]} ${focusedMonth.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final bool Function(DateTime) hasSession;
  const _CalendarGrid({required this.focusedMonth, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    int weekdayOffset = firstDay.weekday - 1;
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 7,
            childAspectRatio: 1,
            children: List.generate(weekdayOffset + daysInMonth, (index) {
              if (index < weekdayOffset) return const SizedBox.shrink();
              final day = index - weekdayOffset + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final done = hasSession(date);

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color:
                      done
                          ? Colors.green.withOpacity(0.3)
                          : (isToday ? Colors.white.withOpacity(0.1) : null),
                  shape: BoxShape.circle,
                  border:
                      isToday ? Border.all(color: Colors.greenAccent) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: done ? Colors.greenAccent : Colors.white,
                    fontWeight:
                        done || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
