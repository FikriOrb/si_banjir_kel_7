import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  static const _channel = AndroidNotificationChannel(
    'flood_geofence_alerts',
    'Peringatan Banjir',
    description: 'Notifikasi saat pengguna mendekati laporan banjir aktif.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
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
    );
  }
}
