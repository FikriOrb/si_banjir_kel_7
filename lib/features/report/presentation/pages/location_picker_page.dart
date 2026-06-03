import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerPage extends StatefulWidget {
  final Position currentPosition;
  final double maxRadiusMeters;

  const LocationPickerPage({
    super.key,
    required this.currentPosition,
    this.maxRadiusMeters = 100.0,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late GoogleMapController _mapController;
  late LatLng _centerPosition;
  late LatLng _currentCameraPosition;
  bool _isOutOfRange = false;
  double _currentDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _centerPosition = LatLng(
      widget.currentPosition.latitude,
      widget.currentPosition.longitude,
    );
    _currentCameraPosition = _centerPosition;
  }

  void _onCameraMove(CameraPosition position) {
    _currentCameraPosition = position.target;
    _checkDistance();
  }

  void _checkDistance() {
    final distance = Geolocator.distanceBetween(
      _centerPosition.latitude,
      _centerPosition.longitude,
      _currentCameraPosition.latitude,
      _currentCameraPosition.longitude,
    );

    setState(() {
      _currentDistance = distance;
      _isOutOfRange = distance > widget.maxRadiusMeters;
    });
  }

  void _confirmLocation() {
    if (_isOutOfRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Titik lokasi terlalu jauh! Maksimal ${widget.maxRadiusMeters.toInt()} meter dari posisi aslimu.'),
          backgroundColor: Colors.red,
        ),
      );
      // Snap kembali ke tengah
      _mapController.animateCamera(CameraUpdate.newLatLng(_centerPosition));
      return;
    }

    Navigator.pop(context, _currentCameraPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesuaikan Titik Banjir'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _centerPosition,
              zoom: 18.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            circles: {
              Circle(
                circleId: const CircleId('radius_circle'),
                center: _centerPosition,
                radius: widget.maxRadiusMeters,
                fillColor: Colors.blue.withOpacity(0.15),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            },
          ),
          // Indikator Titik Tengah
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36.0), // Offset ikon sedikit ke atas supaya pas titik bawahnya
              child: Icon(
                Icons.location_on,
                size: 40,
                color: _isOutOfRange ? Colors.red : Colors.blue,
              ),
            ),
          ),
          // Info Jarak & Peringatan
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: _isOutOfRange ? Colors.red.shade50 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _isOutOfRange ? Icons.warning_amber_rounded : Icons.info_outline,
                      color: _isOutOfRange ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isOutOfRange
                            ? 'Lokasi di luar jangkauan! Jarak: ${_currentDistance.toStringAsFixed(1)}m'
                            : 'Geser peta untuk memindahkan titik. Jarak: ${_currentDistance.toStringAsFixed(1)}m',
                        style: TextStyle(
                          color: _isOutOfRange ? Colors.red.shade900 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tombol Konfirmasi
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: FilledButton.icon(
              onPressed: _confirmLocation,
              style: FilledButton.styleFrom(
                backgroundColor: _isOutOfRange ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Pilih Titik Ini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Tombol Kembali ke Lokasi Saya
          Positioned(
            bottom: 90,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              onPressed: () {
                _mapController.animateCamera(CameraUpdate.newLatLng(_centerPosition));
              },
              child: const Icon(Icons.my_location),
            ),
          )
        ],
      ),
    );
  }
}
