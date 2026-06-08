import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/map/presentation/pages/emergency_alarm_page.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService(FlutterLocalNotificationsPlugin());
});

class LocalNotificationService {
  LocalNotificationService(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  static const _channel = AndroidNotificationChannel(
    'flood_geofence_alerts',
    'Peringatan Banjir',
    description: 'Notifikasi saat pengguna mendekati laporan banjir aktif.',
    importance: Importance.high,
  );

  static const _emergencyChannel = AndroidNotificationChannel(
    'flood_emergency_alerts_v3', // v3 agar benar-benar fresh
    'Alarm Darurat Banjir',
    description: 'Alarm paksa layar penuh untuk bahaya jarak dekat (<50m).',
    importance: Importance.max,
    playSound: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.startsWith('emergency_')) {
          final reportId = response.payload!.replaceFirst('emergency_', '');
          if (navigatorKey != null && navigatorKey.currentState != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => EmergencyAlarmPage(reportId: reportId),
              ),
            );
          }
        }
      },
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
        
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_emergencyChannel);
  }

  Future<void> showFloodAlert({
    required String reportId,
    required double distanceMeters,
  }) {
    return _notifications.show(
      reportId.hashCode,
      'Awas, area banjir di dekat Anda',
      'Laporan aktif terdeteksi sekitar ${distanceMeters.round()} meter. Cari rute alternatif.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flood_geofence_alerts',
          'Peringatan Banjir',
          channelDescription:
              'Notifikasi saat pengguna mendekati laporan banjir aktif.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: reportId,
    );
  }

  Future<void> showEmergencyAlarm({
    required String reportId,
    required double distanceMeters,
  }) {
    return _notifications.show(
      reportId.hashCode + 100, // Beda ID agar tidak menimpa notif biasa
      '🚨 BAHAYA BANJIR SANGAT DEKAT 🚨',
      'Anda berada ${distanceMeters.round()} meter dari titik banjir! Segera menjauh!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'flood_emergency_alerts_v3', // v3
          'Alarm Darurat Banjir',
          channelDescription: 'Alarm paksa layar penuh untuk bahaya jarak dekat (<50m).',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm, // Paksa gunakan volume alarm
          playSound: true,
          additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT (bunyi loop)
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'emergency_$reportId', // Payload khusus untuk buka halaman alarm
    );
  }

  Future<bool> requestPermission() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted != null) return granted;
    }

    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(alert: true, badge: true, sound: true);
      if (granted != null) return granted;
    }

    return true; // Asumsi default granted untuk OS versi lama
  }
}
