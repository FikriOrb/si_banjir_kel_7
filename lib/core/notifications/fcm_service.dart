import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase sudah diinisialisasi untuk isolate background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }

  // Cek apakah ini pesan geofencing peringatan banjir
  if (message.data['type'] == 'flood_alert') {
    final double floodLat = double.tryParse(message.data['latitude']?.toString() ?? '0') ?? 0;
    final double floodLng = double.tryParse(message.data['longitude']?.toString() ?? '0') ?? 0;

    // Dapatkan lokasi pengguna (background)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    // Pakai getLastKnownPosition agar lebih hemat baterai dan cepat
    Position? position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Hitung jarak
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude, position.longitude, floodLat, floodLng
    );

    // Radius bahaya: misal 100 meter
    if (distanceInMeters <= 100) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final localService = LocalNotificationService(flutterLocalNotificationsPlugin);
      await localService.initialize();
      await localService.showFloodAlert(
        reportId: message.data['report_id'] ?? 'unknown',
        distanceMeters: distanceInMeters,
      );
    }
  }
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 1. Meminta Izin Notifikasi (terutama untuk iOS dan Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission for notifications');
      }
      
      // 2. Dapatkan Token FCM saat pertama kali
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await saveTokenToSupabase(fcmToken);
      }

      // 3. Dengarkan jika token diperbarui oleh Firebase
      _messaging.onTokenRefresh.listen((newToken) {
        saveTokenToSupabase(newToken);
      }).onError((err) {
        if (kDebugMode) {
          print('Error getting refreshed token: $err');
        }
      });
      
      // 4. Pengaturan penerimaan pesan saat aplikasi aktif (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        // Cek apakah ini pesan peringatan banjir geofencing
        if (message.data['type'] == 'flood_alert') {
          final double floodLat = double.tryParse(message.data['latitude']?.toString() ?? '0') ?? 0;
          final double floodLng = double.tryParse(message.data['longitude']?.toString() ?? '0') ?? 0;

          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
              Position? position = await Geolocator.getLastKnownPosition();
              position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
              
              double distanceInMeters = Geolocator.distanceBetween(
                position.latitude, position.longitude, floodLat, floodLng
              );

              if (distanceInMeters <= 100) {
                final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
                final localService = LocalNotificationService(flutterLocalNotificationsPlugin);
                await localService.initialize();
                await localService.showFloodAlert(
                  reportId: message.data['report_id'] ?? 'unknown',
                  distanceMeters: distanceInMeters,
                );
              }
            }
          }
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
        }
      });
      
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  static Future<void> checkAndSaveToken() async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await saveTokenToSupabase(fcmToken);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checkAndSaveToken: $e');
      }
    }
  }

  static Future<void> saveTokenToSupabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return; // Belum login

      // Simpan token FCM ke tabel users (pastikan kolom fcm_token sudah ada di database)
      await Supabase.instance.client.from('users').update({
        'fcm_token': token,
      }).eq('id', userId);
      
      if (kDebugMode) {
        print('FCM Token berhasil disimpan ke Supabase: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gagal menyimpan FCM token ke Supabase: $e');
      }
    }
  }
}
