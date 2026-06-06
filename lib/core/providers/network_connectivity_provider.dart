import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/map/data/repositories/flood_report_repository.dart';
import '../../features/weather/data/services/bmkg_weather_service.dart';
import '../../features/profile/presentation/pages/report_statistics_page.dart';
import '../../features/feed/data/repositories/report_comment_repository.dart';

final networkAutoRefreshProvider = Provider<void>((ref) {
  final subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
      // Reconnected! Give the OS a moment to actually establish the internet route.
      Future.delayed(const Duration(milliseconds: 1500), () {
        ref.invalidate(activeFloodReportsProvider);
        ref.invalidate(historyReportsProvider);
        ref.invalidate(bmkgMedanWarningProvider);
        ref.invalidate(communityStatisticsProvider);
        ref.invalidate(reportCommentsProvider);
      });
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });
});
