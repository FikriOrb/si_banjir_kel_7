import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/notifications/local_notification_service.dart';
import '../../data/models/flood_report.dart';
import '../../data/repositories/flood_report_repository.dart';

class GeofencingService {
  GeofencingService({
    required FloodReportRepository reports,
    required LocalNotificationService notifications,
  })  : _reports = reports,
        _notifications = notifications;

  final FloodReportRepository _reports;
  final LocalNotificationService _notifications;
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
        await _notifications.showFloodAlert(
          reportId: report.id,
          distanceMeters: report.distanceMeters ?? radiusMeters.toDouble(),
        );
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
