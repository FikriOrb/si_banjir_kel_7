import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/notifications/local_notification_service.dart';
import '../../data/models/flood_report.dart';
import '../../data/repositories/flood_report_repository.dart';

final activeGeofenceAlertProvider = StateProvider<FloodReport?>((ref) => null);

final geofencingServiceProvider = Provider<GeofencingService>((ref) {
  final reports = ref.read(floodReportRepositoryProvider);
  final notifications = LocalNotificationService(FlutterLocalNotificationsPlugin());
  return GeofencingService(reports: reports, notifications: notifications, ref: ref);
});

class GeofencingService {
  GeofencingService({
    required FloodReportRepository reports,
    required LocalNotificationService notifications,
    required Ref ref,
  })  : _reports = reports,
        _notifications = notifications,
        _ref = ref;

  final FloodReportRepository _reports;
  final LocalNotificationService _notifications;
  final Ref _ref;
  final Set<String> _notifiedReportIds = <String>{};
  StreamSubscription<Position>? _subscription;

  Future<void> start({int radiusMeters = 500}) async {
    await _ensurePermission();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      _checkNearbyReports(position, radiusMeters);
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _checkNearbyReports(Position position, int radiusMeters) async {
    final nearbyReports = await _reports.fetchReportsWithinRadius(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: radiusMeters,
    );

    for (final report in nearbyReports) {
      if (_notifiedReportIds.add(report.id)) {
        // 1. Tampilkan notifikasi lokal sistem
        await _notifications.showFloodAlert(
          reportId: report.id,
          distanceMeters: report.distanceMeters ?? radiusMeters.toDouble(),
        );

        // 2. Set provider agar UI bisa menampilkan pop up in-app elegan
        _ref.read(activeGeofenceAlertProvider.notifier).state = report;
      }
    }
  }

  Future<void> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Layanan lokasi perangkat belum aktif.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Izin lokasi dibutuhkan untuk peringatan geofence.');
    }
  }
}
