import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/notification_settings_provider.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/notifications/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show a blank UI to immediately dismiss the native splash screen
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: Color(0xFF0F172A)),
    ),
  );

  await dotenv.load(fileName: ".env");

  if (Env.hasSupabaseConfig) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  await LocalNotificationService(
    FlutterLocalNotificationsPlugin(),
  ).initialize();

  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    ],
    child: const FloodWarningApp(),
  ));
}
