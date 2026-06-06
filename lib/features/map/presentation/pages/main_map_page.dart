import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
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
  BitmapDescriptor? _evacuationIcon;

  @override
  void initState() {
    super.initState();
    _initCustomIcon();
  }

  Future<void> _initCustomIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100.0; // Ukuran dibesarkan sedikit

    // Draw Stick (tiang pin)
    final Paint stickPaint = Paint()
      ..color = const Color(0xFF2B3A4A) // Dark blue/slate stick
      ..style = PaintingStyle.fill;
    
    // Tiang lebih ramping
    final RRect stick = RRect.fromRectAndRadius(
      Rect.fromLTWH(size / 2 - 3, size * 0.4, 6, size * 0.6), 
      const Radius.circular(2),
    );
    canvas.drawRRect(stick, stickPaint);

    // Draw Head (kepala bulat)
    final Paint headPaint = Paint()..color = Colors.amber.shade500;
    // Lingkaran di atas tiang, radius diperkecil
    canvas.drawCircle(Offset(size / 2, size * 0.3), size * 0.3, headPaint);
    
    // Draw Highlight (pantulan cahaya)
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size * 0.65, size * 0.15), size * 0.07, highlightPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (mounted && byteData != null) {
      setState(() {
        _evacuationIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      });
    }
  }

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
            error: (error, _) => _MapFallback(message: AppError.toMessage(error)),
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
    );
  }

  Marker _markerForReport(FloodReport report) {
    return Marker(
      markerId: MarkerId(report.id),
      position: report.latLng,
      icon: report.reportType == 'evacuation' 
          ? (_evacuationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)) 
          : BitmapDescriptor.defaultMarkerWithHue(report.depthLevel.markerHue),
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
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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


