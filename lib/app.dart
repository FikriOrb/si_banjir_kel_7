import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_notification.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/update_password_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/notifications/local_notification_service.dart';
import 'features/map/presentation/pages/emergency_alarm_page.dart';
import 'core/notifications/fcm_service.dart';

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
    
    // Setup Local Notification dengan Navigator untuk in-app pop-up
    _setupNotifications();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (_navigatorKey.currentState != null) {
            timer.cancel();
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
              (route) => false,
            );
          }
        });
      } else if (event == AuthChangeEvent.signedIn) {
        SharedPreferences.getInstance().then((prefs) {
          final isAwaiting = prefs.getBool('awaiting_verification') ?? false;
          if (isAwaiting) {
            prefs.remove('awaiting_verification');
            
            // Cegah SplashPage agar tidak berpindah layar sendiri
            prefs.setBool('is_verifying_deep_link', true);
            
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
              if (_navigatorKey.currentState != null && _navigatorKey.currentContext != null) {
                timer.cancel();
                
                // 1. Tampilkan loading dialog
                showDialog(
                  context: _navigatorKey.currentContext!,
                  barrierDismissible: false,
                  builder: (context) => WillPopScope(
                    onWillPop: () async => false,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 24),
                            Text(
                              'Memverifikasi Akun...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                // 2. Beri jeda agar terasa ada proses verifikasi, lalu sign out dan pindah
                Future.delayed(const Duration(seconds: 2), () async {
                  await Supabase.instance.client.auth.signOut();
                  await prefs.remove('is_verifying_deep_link'); // Selesai
                  
                  if (_navigatorKey.currentState != null) {
                    _navigatorKey.currentState?.pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const LoginPage(),
                        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                      ),
                      (route) => false,
                    );

                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (_navigatorKey.currentContext != null) {
                        AppNotification.show(
                          _navigatorKey.currentContext!,
                          type: AppNotificationType.success,
                          title: 'Verifikasi Berhasil',
                          message: 'Akun Anda sudah aktif. Silakan masuk!',
                        );
                      }
                    });
                  }
                });
              }
            });
          } else {
            // Jika login normal (bukan verifikasi), simpan FCM token
            FcmService.checkAndSaveToken();
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

  Future<void> _setupNotifications() async {
    final localService = LocalNotificationService(FlutterLocalNotificationsPlugin());
    await localService.initialize(navigatorKey: _navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SiBanjir',
      theme: AppTheme.light(),
      home: const SplashPage(),
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child!,
        );
      },
    );
  }
}
