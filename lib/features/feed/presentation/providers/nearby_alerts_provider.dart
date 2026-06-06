import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../map/data/repositories/flood_report_repository.dart';

final currentAlertPositionProvider = StateProvider<Position?>((ref) => null);

final nearbyAlertReportsProvider = Provider.autoDispose<List<FloodReport>>((ref) {
  final position = ref.watch(currentAlertPositionProvider);
  final reportsAsync = ref.watch(activeFloodReportsProvider);
  
  return reportsAsync.maybeWhen(
    data: (reports) {
      if (position == null) return [];
      
      final List<MapEntry<FloodReport, double>> listWithDistance = [];
      for (final r in reports) {
        final dist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          r.latitude,
          r.longitude,
        );
        if (dist <= 5000) { // Radius 5km
          listWithDistance.add(MapEntry(r, dist));
        }
      }
      
      // Sort nearest to farthest
      listWithDistance.sort((a, b) => a.value.compareTo(b.value));
      
      return listWithDistance.map((entry) {
        final report = entry.key;
        final distance = entry.value;
        return FloodReport(
          id: report.id,
          userId: report.userId,
          latitude: report.latitude,
          longitude: report.longitude,
          depthLevel: report.depthLevel,
          photoUrl: report.photoUrl,
          upvoteCount: report.upvoteCount,
          downvoteCount: report.downvoteCount,
          expiresAt: report.expiresAt,
          createdAt: report.createdAt,
          isActive: report.isActive,
          address: report.address,
          note: report.note,
          distanceMeters: distance,
          reporterName: report.reporterName,
          reporterUsername: report.reporterUsername,
          reporterAvatar: report.reporterAvatar,
          reportType: report.reportType,
        );
      }).toList();
    },
    orElse: () => [],
  );
});
