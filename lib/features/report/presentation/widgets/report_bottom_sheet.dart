import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/location_picker_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../map/data/repositories/flood_report_repository.dart';
import '../../data/repositories/report_submission_repository.dart';
import '../../../../core/widgets/app_notification.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Untuk keyboard
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lapor Genangan Banjir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),

              // 1. FOTO
              _PhotoSelectionBox(
                photo: _photo,
                onCapture: _capturePhoto,
              ),
              const SizedBox(height: 20),

              // 2. KETINGGIAN AIR
              const Text(
                'Estimasi Ketinggian Air',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WaterDepthLevel.values.map((level) {
                  final isSelected = _selectedDepth == level;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(level.label),
                    selectedColor: level.color.withOpacity(0.15),
                    side: BorderSide(
                      color: isSelected ? level.color : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? level.color : const Color(0xFF475569),
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedDepth = level),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 3. LOKASI MANUAL
              const Text(
                'Lokasi Kejadian',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _customLocation != null
                          ? Colors.amber.shade50
                          : Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _customLocation != null
                          ? LucideIcons.mapPin
                          : LucideIcons.locate,
                      color: _customLocation != null
                          ? Colors.amber.shade700
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _customLocation != null
                        ? 'Koordinat Disesuaikan'
                        : 'Lokasi GPS Saat Ini',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF1E293B)),
                  ),
                  subtitle: const Text(
                    'Geser pin jika titik kurang akurat',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  trailing: TextButton(
                    onPressed: _openLocationPicker,
                    child: const Text('Sesuaikan'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. DESKRIPSI / CATATAN
              const Text(
                'Detail / Informasi Tambahan (Opsional)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Air perlahan naik, jalan tidak bisa dilalui motor...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _noteTemplates.map((template) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        elevation: 0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        label: Text(template,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.bold)),
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

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.send, size: 18),
                label: const Text('Kirim Laporan Warga'),
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
        maxWidth: 800, // Resolusi lebih kecil untuk internet lambat
      );
      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context,
            type: AppNotificationType.error,
            title: 'Error',
            message: 'Gagal membuka kamera: ${AppError.toMessage(e)}');
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
          throw Exception(
              'Izin lokasi diblokir permanen. Aktifkan di pengaturan HP.');
        }

        _currentGpsPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        if (mounted) {
          AppNotification.show(context,
              type: AppNotificationType.error,
              title: 'Error',
              message: 'Gagal mendapatkan GPS: ${AppError.toMessage(e)}');
          setState(() {
            _isSubmitting = false;
          });
        }
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
      AppNotification.show(
        context,
        type: AppNotificationType.error,
        message: 'Ambil foto terlebih dahulu sebelum mengirim laporan.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kirim Laporan?'),
          content: const Text(
              'Apakah informasi ketinggian air dan foto sudah benar?'),
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
          throw Exception(
              'Izin lokasi diblokir permanen. Aktifkan di pengaturan HP.');
        }

        _currentGpsPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      final finalLatitude =
          _customLocation?.latitude ?? _currentGpsPosition!.latitude;
      final finalLongitude =
          _customLocation?.longitude ?? _currentGpsPosition!.longitude;
      final finalNote = _noteController.text.trim();

      // CEK ANTI-SPAM 1: Maksimal 1 laporan aktif per akun
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        final existingActiveReports = await Supabase.instance.client
            .from('flood_reports')
            .select('id')
            .eq('user_id', currentUserId)
            .eq('is_active', true)
            .limit(1);

        if (existingActiveReports.isNotEmpty) {
          if (mounted) {
            AppNotification.show(
              context,
              type: AppNotificationType.error,
              message:
                  'Anda masih memiliki laporan aktif! Tunggu hingga laporan sebelumnya selesai.',
            );
            setState(() => _isSubmitting = false);
          }
          return;
        }
      }

      // CEK ANTI-SPAM 2: Apakah sudah ada laporan di sekitar radius 100 meter?
      final nearbyReports = await ref
          .read(floodReportRepositoryProvider)
          .fetchReportsWithinRadius(
            latitude: finalLatitude,
            longitude: finalLongitude,
            radiusMeters: 100,
          );

      if (nearbyReports.isNotEmpty) {
        AppNotification.show(
          context,
          type: AppNotificationType.error,
          message:
              'Sudah ada laporan di radius 100m. Bantu konfirmasi "Masih Banjir" di Beranda.',
        );
        setState(() {
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

      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.submitReport,
          message: 'Laporan genangan air Anda berhasil dikirim ke sistem.',
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.error,
          message: 'Laporan gagal dikirim.',
        );
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
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: onCapture,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Slate 50
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  photo == null ? const Color(0xFFE2E8F0) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image.file(photo!, fit: BoxFit.cover)
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(LucideIcons.camera,
                            size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ambil Foto Bukti Banjir',
                        style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ketuk untuk membuka kamera handphone',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                if (photo != null)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.refreshCw,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
