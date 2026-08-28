import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fft;
import 'package:provider/provider.dart';
import 'services/settings_service.dart';
import 'screens/day_picker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  fft.FlutterForegroundTask.init(
    androidNotificationOptions: fft.AndroidNotificationOptions(
      channelId: 'gym_timer_channel',
      channelName: 'Gym Timer',
      channelDescription: 'Chrono en cours',
      isSticky: true,
      buttons: [
        fft.NotificationButton(id: 'toggle', text: '⏯ Lecture/Pause'),
        fft.NotificationButton(id: 'reset', text: '↺ Reset'),
      ],
    ),
    iosNotificationOptions: fft.IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: fft.ForegroundTaskOptions(
      interval: 1000,
      isOnceEvent: false,
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()..load()),
      ],
      child: fft.WithForegroundTask(child: const GymTimerApp()),
    ),
  );
}

class GymTimerApp extends StatelessWidget {
  const GymTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Timer',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DayPickerScreen(),
    );
  }
}
