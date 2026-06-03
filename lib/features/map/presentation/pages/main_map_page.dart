import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../report/presentation/widgets/report_bottom_sheet.dart';
import '../../../weather/data/services/bmkg_weather_service.dart';
import '../../data/models/flood_report.dart';
import '../../data/repositories/flood_report_repository.dart';
import '../../../../core/widgets/report_detail_bottom_sheet.dart';

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
              myLocationButtonEnabled: false, 
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
                    data: (warning) => warning?.headline ?? 'Medan: Cuaca Normal',
                    loading: () => 'Memuat peringatan BMKG...',
                    error: (_, __) => 'BMKG belum tersedia',
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 100, 
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                heroTag: 'my_location_btn',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: _goToMyLocation,
                child: const Icon(LucideIcons.locate),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'main_map_lapor_fab',
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          onPressed: () => showReportBottomSheet(context),
          icon: const Icon(LucideIcons.mapPin),
          label: const Text('Lapor Banjir'),
        ),
      ),
    );
  }

  Marker _markerForReport(FloodReport report) {
    return Marker(
      markerId: MarkerId(report.id),
      position: report.latLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(report.depthLevel.markerHue),
      onTap: () => _showReportDetailBottomSheet(context, report),
    );
  }

  void _showReportDetailBottomSheet(BuildContext context, FloodReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportDetailBottomSheet(report: report),
    );
  }
}

class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cloudLightning, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.message});

  final String message;

  @override
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


