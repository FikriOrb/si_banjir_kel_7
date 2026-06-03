import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/location_picker_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../map/data/repositories/flood_report_repository.dart';
import '../../data/repositories/report_submission_repository.dart';

Future<void> showReportBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ReportBottomSheet(),
  );
}

class ReportBottomSheet extends ConsumerStatefulWidget {
  const ReportBottomSheet({super.key});

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  File? _photo;
  WaterDepthLevel _selectedDepth = WaterDepthLevel.ankle;
  bool _isSubmitting = false;
  String? _error;

  final _noteController = TextEditingController();
  final List<String> _noteTemplates = [
    'Jalan terputus',
    'Air masuk rumah',
    'Akses jalan lumpuh',
    'Banyak kendaraan mogok',
  ];

  LatLng? _customLocation;
  Position? _currentGpsPosition;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Untuk keyboard
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DDE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Laporan banjir',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              
              // 1. FOTO
              _PhotoSelectionBox(
                photo: _photo,
                onCapture: _capturePhoto,
              ),
              const SizedBox(height: 14),

              // 2. KETINGGIAN AIR
              Text(
                'Tinggi air',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WaterDepthLevel.values.map((level) {
                  return ChoiceChip(
                    selected: _selectedDepth == level,
                    label: Text(level.label),
                    selectedColor: level.color.withOpacity(0.24),
                    side: BorderSide(color: level.color),
                    onSelected: (_) => setState(() => _selectedDepth = level),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 3. LOKASI MANUAL
              Text(
                'Lokasi Banjir',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: const Color(0xFFF3F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: Icon(
                    _customLocation != null ? Icons.pin_drop : Icons.my_location,
                    color: Colors.blue,
                  ),
                  title: Text(
                    _customLocation != null ? 'Titik Lokasi Disesuaikan' : 'Titik GPS Saat Ini',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  trailing: TextButton(
                    onPressed: _openLocationPicker,
                    child: const Text('Ubah'),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. DESKRIPSI / CATATAN
              Text(
                'Catatan (Opsional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan kondisi di lokasi...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _noteTemplates.map((template) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(template, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            if (_noteController.text.isNotEmpty) {
                              _noteController.text += ', $template';
                            } else {
                              _noteController.text = template;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: const Text('Kirim laporan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Kompresi ekstra agar lebih ringan
        maxWidth: 800,    // Resolusi lebih kecil untuk internet lambat
      );
      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Gagal membuka kamera: $e');
      }
    }
  }

  Future<void> _openLocationPicker() async {
    // Pastikan kita sudah punya GPS awal
    if (_currentGpsPosition == null) {
      setState(() => _isSubmitting = true);
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Izin lokasi ditolak oleh pengguna.');
          }
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Izin lokasi diblokir permanen. Aktifkan di pengaturan HP.');
        }

        _currentGpsPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        setState(() {
          _error = 'Gagal mendapatkan GPS: $e';
          _isSubmitting = false;
        });
        return;
      }
      setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    final selectedLatLng = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          currentPosition: _currentGpsPosition!,
          maxRadiusMeters: 100.0,
        ),
      ),
    );

    if (selectedLatLng != null) {
      setState(() {
        _customLocation = selectedLatLng;
      });
    }
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) {
      setState(() => _error = 'Ambil foto terlebih dahulu sebelum mengirim laporan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kirim Laporan?'),
          content: const Text('Apakah informasi ketinggian air dan foto sudah benar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kirim'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _isSubmitting = false);
        return;
      }

      if (_currentGpsPosition == null) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Izin lokasi ditolak oleh pengguna.');
          }
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Izin lokasi diblokir permanen. Aktifkan di pengaturan HP.');
        }

        _currentGpsPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      final finalLatitude = _customLocation?.latitude ?? _currentGpsPosition!.latitude;
      final finalLongitude = _customLocation?.longitude ?? _currentGpsPosition!.longitude;
      final finalNote = _noteController.text.trim();

      // CEK ANTI-SPAM: Apakah sudah ada laporan di sekitar radius 100 meter?
      final nearbyReports = await ref.read(floodReportRepositoryProvider).fetchReportsWithinRadius(
        latitude: finalLatitude,
        longitude: finalLongitude,
        radiusMeters: 100,
      );

      if (nearbyReports.isNotEmpty) {
        setState(() {
          _error = 'Sudah ada laporan aktif di radius 100m dari titik ini. Bantu konfirmasi "Masih Banjir" di Beranda untuk mengurangi spam laporan ganda.';
          _isSubmitting = false;
        });
        return;
      }

      await ref.read(reportSubmissionRepositoryProvider).submitReport(
            latitude: finalLatitude,
            longitude: finalLongitude,
            depthLevel: _selectedDepth,
            photo: photo,
            note: finalNote.isNotEmpty ? finalNote : null,
          );

      ref.invalidate(historyReportsProvider);
      ref.invalidate(activeFloodReportsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Laporan gagal dikirim: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _PhotoSelectionBox extends StatelessWidget {
  const _PhotoSelectionBox({
    required this.photo,
    required this.onCapture,
  });

  final File? photo;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: const Color(0xFFE9EEF5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo != null)
                Image.file(photo!, fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FilledButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(photo == null ? 'Buka Kamera' : 'Ganti Foto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
