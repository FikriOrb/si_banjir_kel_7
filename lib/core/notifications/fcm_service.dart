import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
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
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
          // TODO: Hubungkan ke LocalNotificationService jika ingin memunculkan banner manual
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
