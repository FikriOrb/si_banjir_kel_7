import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../map/data/models/flood_report.dart';

class ReportLocationMapPage extends StatefulWidget {
  const ReportLocationMapPage({super.key, required this.report});

  final FloodReport report;

  @override
  State<ReportLocationMapPage> createState() => _ReportLocationMapPageState();
}

class _ReportLocationMapPageState extends State<ReportLocationMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription<Position>? _positionStream;
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.report.latitude,
            widget.report.longitude,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final initialCameraPosition = CameraPosition(
      target: LatLng(report.latitude, report.longitude),
      zoom: 16,
    );

    String distanceText = 'Menghitung jarak...';
    if (_distanceInMeters != null) {
      if (_distanceInMeters! > 1000) {
        distanceText = 'Berjarak ${(_distanceInMeters! / 1000).toStringAsFixed(1)} km dari lokasimu';
      } else {
        distanceText = 'Berjarak ${_distanceInMeters!.toStringAsFixed(0)} meter dari lokasimu';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Banjir'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: MarkerId(report.id),
                position: LatLng(report.latitude, report.longitude),
                infoWindow: InfoWindow(
                  title: 'Banjir ${report.depthLevel.label}',
                  snippet: report.address ?? 'Lokasi banjir',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(report.depthLevel.markerHue),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            distanceText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (report.address != null && report.address!.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              report.address!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
