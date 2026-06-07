import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/update_password_page.dart';

class FloodWarningApp extends StatefulWidget {
  const FloodWarningApp({super.key});

  @override
  State<FloodWarningApp> createState() => _FloodWarningAppState();
}

class _FloodWarningAppState extends State<FloodWarningApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Gunakan timer untuk memastikan NavigatorState sudah siap
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (_navigatorKey.currentState != null) {
            timer.cancel();
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
              (route) => false,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SiBanjir',
      theme: AppTheme.light(),
      home: const SplashPage(),
    );
  }
}
