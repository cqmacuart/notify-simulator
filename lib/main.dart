import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

// Must be top-level: called when a notification is tapped while app is terminated.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  // No-op: app will open on next launch.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load all timezone data, then set tz.local to the device's actual timezone.
  // Without setLocalLocation(), tz.local defaults to UTC, causing zonedSchedule
  // to fire at the wrong local time (e.g. 2h late in UTC+2).
  tzdata.initializeTimeZones();
  try {
    const channel = MethodChannel('noti_sim/miui');
    final String tzName = await channel.invokeMethod<String>('getTimezone') ?? 'UTC';
    tz.setLocalLocation(tz.getLocation(tzName));
  } catch (_) {
    // Fallback: UTC. User will see wrong schedule time but app won't crash.
  }

  // Initialize shared_preferences.
  await StorageService.init();

  // Create notification channel and initialize plugin.
  await NotificationService.init();

  runApp(const NotiSimApp());
}

class NotiSimApp extends StatelessWidget {
  const NotiSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotiSim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
