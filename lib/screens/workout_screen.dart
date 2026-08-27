import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fft;
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as fow;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../services/workout_service.dart';
import 'history_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutPlan plan;
  const WorkoutScreen({super.key, required this.plan});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  late TimerService _timer;
  int _groupIndex = 0;
  int _exIndexInGroup = 0;
  final Set<String> _done = {};
  final AudioPlayer _player = AudioPlayer();
  bool _isAdvancing = false;
  bool _overlayShown = false;
  final _ln = FlutterLocalNotificationsPlugin();
  static const int _notifId = 1001;

  YoutubePlayerController? _ytController;
  VideoPlayerController? _mp4Controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = TimerService();
    _timer.onAutoAdvance = _onAutoAdvance;
    _timer.init();
    _initNotif();
    _ensureForegroundService();
    _loadMedia();
  }

  void _initNotif() {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    _ln.initialize(const InitializationSettings(android: androidInit));
  }

  Future<void> _ensureForegroundService() async {
    await fft.FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  MuscleGroup get currentGroup =>
      widget.plan.groups[_groupIndex.clamp(0, widget.plan.groups.length - 1)];
  PlannedExercise get currentExercise =>
      currentGroup.exercises[_exIndexInGroup.clamp(
        0,
        currentGroup.exercises.length - 1,
      )];
  PlannedExercise? get nextExercise {
    if (_exIndexInGroup + 1 < currentGroup.exercises.length) {
      return currentGroup.exercises[_exIndexInGroup + 1];
    }
    if (_groupIndex + 1 < widget.plan.groups.length) {
      return widget.plan.groups[_groupIndex + 1].exercises.first;
    }
    return null;
  }

  void _loadMedia() {
    _ytController?.dispose();
    _mp4Controller?.dispose();
    _ytController = null;
    _mp4Controller = null;

    final ex = currentExercise;
    if (ex.name.toLowerCase().contains('circuit') &&
        widget.plan.name.toLowerCase().contains('abdos')) {
      _mp4Controller = VideoPlayerController.asset('assets/abdos.mp4');
      _mp4Controller!.initialize().then((_) => setState(() {}));
    }
  }

  void _playBeep() async {
    try {
      await _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      await _player.setVolume(0.7);
      await _player.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }

  String _doneKey(int gi, int ei) => '$gi-$ei';
  bool _isDone(int gi, int ei) => _done.contains(_doneKey(gi, ei));

  void _markDoneCurrent() {
    _done.add(_doneKey(_groupIndex, _exIndexInGroup));
  }

  void _onAutoAdvance() {
    if (_isAdvancing) return;
    _isAdvancing = true;
    _markDoneCurrent();
    _playBeep();
    Future.delayed(const Duration(milliseconds: 200), () {
      _advanceExercise();
      _isAdvancing = false;
    });
  }

  void _advanceExercise() async {
    _timer.reset();
    if (_exIndexInGroup + 1 < currentGroup.exercises.length) {
      setState(() => _exIndexInGroup++);
      _loadMedia();
      return;
    }
    if (_groupIndex + 1 < widget.plan.groups.length) {
      setState(() {
        _groupIndex++;
        _exIndexInGroup = 0;
      });
      _loadMedia();
      return;
    }
    _playBeep();
    await _finishSession();
  }

  Future<void> _finishSession() async {
    final allExercises = widget.plan.groups.expand((g) => g.exercises).toList();
    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planName: widget.plan.name,
      date: DateTime.now(),
      durationSeconds: _timer.elapsed.inSeconds,
      exercises:
          allExercises
              .asMap()
              .entries
              .map(
                (e) => SessionExercise(
                  name: e.value.name,
                  weightUsed: e.value.targetWeight,
                  seriesCompleted:
                      _done.contains(_doneKey(0, e.key))
                          ? 4
                          : _timer.currentSerie,
                  durationSeconds: _timer.elapsed.inSeconds,
                ),
              )
              .toList(),
    );
    await WorkoutService.saveSession(session);
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: const Text('Séance terminée'),
              content: const Text('Bravo ! Séance enregistrée.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _goTo(int gi, int ei) {
    setState(() {
      _groupIndex = gi.clamp(0, widget.plan.groups.length - 1);
      _exIndexInGroup = ei.clamp(0, currentGroup.exercises.length - 1);
    });
    _timer.reset();
    _loadMedia();
  }

  void _switchGroup() {
    setState(() {
      if (_groupIndex + 1 < widget.plan.groups.length) {
        _groupIndex++;
      } else if (_groupIndex - 1 >= 0) {
        _groupIndex--;
      }
      _exIndexInGroup = 0;
    });
    _timer.reset();
    _loadMedia();
  }

  void _adjustWeight(double delta) {
    final ex = currentExercise;
    final settings = context.read<SettingsService>();
    final current = settings.getWeight(ex.name) ?? ex.targetWeight ?? 0;
    final newWeight = (current + delta).clamp(0.0, 999.0);
    settings.setWeight(ex.name, newWeight);
    setState(() => ex.targetWeight = newWeight);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _openOverlayIfNeeded();
    }
    if (state == AppLifecycleState.resumed) {
      _closeOverlayIfNeeded();
    }
  }

  Future<void> _openOverlayIfNeeded() async {
    try {
      final granted = await fow.FlutterOverlayWindow.isPermissionGranted();
      if (!granted) {
        final ok = await fow.FlutterOverlayWindow.requestPermission();
        if (ok != true) return;
      }
      bool active = await fow.FlutterOverlayWindow.isActive();
      if (active) {
        try {
          await fow.FlutterOverlayWindow.closeOverlay();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await fow.FlutterOverlayWindow.showOverlay(
        height: 72,
        width: 72,
        enableDrag: true,
        alignment: fow.OverlayAlignment.centerRight,
        flag: fow.OverlayFlag.defaultFlag,
        visibility: fow.NotificationVisibility.visibilityPublic,
        positionGravity: fow.PositionGravity.auto,
        overlayTitle: 'Gym Timer',
        overlayContent: 'Bulle active',
      );
      await Future.delayed(const Duration(milliseconds: 150));
      _overlayShown = await fow.FlutterOverlayWindow.isActive();
    } catch (_) {
      _overlayShown = false;
    }
  }

  Future<void> _closeOverlayIfNeeded() async {
    if (!_overlayShown) return;
    try {
      await fow.FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
    _overlayShown = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeOverlayIfNeeded();
    _timer.dispose();
    _ytController?.dispose();
    _mp4Controller?.dispose();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final next = nextExercise;
    final showNext =
        _timer.elapsed >= const Duration(minutes: 4, seconds: 30) &&
        next != null;
    final isAbdosDay = widget.plan.name.toLowerCase().contains('abdos');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
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
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await fow.FlutterOverlayWindow.closeOverlay();
              } catch (_) {}
              _overlayShown = false;
              await Future.delayed(const Duration(milliseconds: 300));
              await _openOverlayIfNeeded();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isAbdosDay &&
                _mp4Controller != null &&
                _mp4Controller!.value.isInitialized) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _mp4Controller!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_mp4Controller!),
                      _VideoControls(controller: _mp4Controller!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                currentGroup.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: currentGroup.exercises.length,
                itemBuilder: (context, i) {
                  final ex = currentGroup.exercises[i];
                  return _ExerciseListItem(
                    exercise: ex,
                    isActive: i == _exIndexInGroup,
                    isDone: _isDone(_groupIndex, i),
                    index: i,
                    total: currentGroup.exercises.length,
                    onTap: () => _goTo(_groupIndex, i),
                    onAdjustWeight: (delta) => _adjustWeight(delta),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _fmt(_timer.elapsed),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  onPressed: _timer.reset,
                  label: const Text('Réinitialiser'),
                ),
                OutlinedButton.icon(
                  icon: Icon(
                    _groupIndex + 1 < widget.plan.groups.length
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_left,
                  ),
                  onPressed: _switchGroup,
                  label: Text(
                    _groupIndex + 1 < widget.plan.groups.length
                        ? 'Muscle suivant'
                        : 'Muscle précédent',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: _timer.isRunning ? _timer.pause : _timer.start,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _timer.isRunning ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _timer.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 60,
                    color: const Color(0xFF121212),
                  ),
                ),
              ),
            ),
            if (showNext && next != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.green.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'À venir',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${next.name} • ${next.targetWeight?.toStringAsFixed(0) ?? '—'} kg',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final PlannedExercise exercise;
  final bool isActive;
  final bool isDone;
  final int index;
  final int total;
  final VoidCallback onTap;
  final ValueChanged<double> onAdjustWeight;

  const _ExerciseListItem({
    required this.exercise,
    required this.isActive,
    required this.isDone,
    required this.index,
    required this.total,
    required this.onTap,
    required this.onAdjustWeight,
  });

  @override
  Widget build(BuildContext context) {
    final target =
        context.select<SettingsService, double?>(
          (s) => s.getWeight(exercise.name),
        ) ??
        exercise.targetWeight;

    return Card(
      color:
          isDone
              ? Colors.green.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color:
              isActive
                  ? Colors.greenAccent.withOpacity(0.6)
                  : (isDone
                      ? Colors.greenAccent.withOpacity(0.35)
                      : Colors.white24),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (exercise.imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    exercise.imageAsset!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        isActive
                            ? Colors.green.withOpacity(0.25)
                            : Colors.white12,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image,
                    size: 20,
                    color: Colors.white38,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Poids: ${target?.toStringAsFixed(1) ?? '—'} kg',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => onAdjustWeight(-0.5),
                    ),
                    const Text(
                      'S1/4',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.greenAccent,
                      ),
                      onPressed: () => onAdjustWeight(0.5),
                    ),
                  ],
                ),
              ] else if (isDone)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                Text(
                  '${index + 1}/$total',
                  style: const TextStyle(color: Colors.white54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});
  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _show = true;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _show = !_show),
      child: Stack(
        children: [
          if (_show)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed:
                          () => setState(() {
                            widget.controller.value.isPlaying
                                ? widget.controller.pause()
                                : widget.controller.play();
                          }),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    Text(
                      _fmt(widget.controller.value.position) +
                          ' / ' +
                          _fmt(widget.controller.value.duration),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
