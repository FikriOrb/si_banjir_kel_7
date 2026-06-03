import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../report/presentation/widgets/report_bottom_sheet.dart';
import '../../../weather/data/services/bmkg_weather_service.dart';
import '../../data/models/flood_report.dart';
import '../../data/repositories/flood_report_repository.dart';

import 'package:geolocator/geolocator.dart';

class MainMapPage extends ConsumerStatefulWidget {
  const MainMapPage({super.key});

  @override
  ConsumerState<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends ConsumerState<MainMapPage> {
  static const _medanCenter = LatLng(3.5952, 98.6722);
  GoogleMapController? _mapController;

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(activeFloodReportsProvider);
    final weatherAsync = ref.watch(bmkgMedanWarningProvider);

    return Scaffold(
      body: Stack(
        children: [
          reportsAsync.when(
            data: (reports) => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _medanCenter,
                zoom: 12.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false, // Matikan tombol bawaan
              myLocationEnabled: true,
              padding: const EdgeInsets.only(bottom: 90, top: 20),
              markers: reports.map(_markerForReport).toSet(),
            ),
            error: (error, _) => _MapFallback(message: error.toString()),
            loading: () => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _medanCenter,
                zoom: 12.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              padding: const EdgeInsets.only(bottom: 90, top: 20),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: _WeatherHeader(
                  text: weatherAsync.when(
                    data: (warning) => warning?.headline ?? 'Medan: cuaca normal',
                    loading: () => 'Memuat peringatan BMKG...',
                    error: (_, __) => 'BMKG belum tersedia',
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 100, // Di atas bottom navigation, di kiri
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showReportBottomSheet(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Lapor'),
      ),
    );
  }

  Marker _markerForReport(FloodReport report) {
    return Marker(
      markerId: MarkerId(report.id),
      position: report.latLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(report.depthLevel.markerHue),
      infoWindow: InfoWindow(
        title: 'Banjir ${report.depthLevel.label}',
        snippet: report.address ?? 'Laporan warga aktif',
      ),
    );
  }
}

class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.thunderstorm, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
