import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../map/data/repositories/flood_report_repository.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../report/data/repositories/report_submission_repository.dart';
import '../../../report/presentation/pages/location_picker_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan Saya'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: historyAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(LucideIcons.history, size: 64, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Belum ada riwayat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Laporan banjir yang kamu kirimkan secara personal akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyReportsProvider);
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final isActive = report.isActive && report.expiresAt.isAfter(DateTime.now());

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: report.depthLevel.color.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.droplets,
                            color: report.depthLevel.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Banjir ${report.depthLevel.label} (± ${report.depthLevel.estimation})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (report.address != null && report.address!.isNotEmpty && report.address != 'null')
                                    ? report.address!
                                    : 'Titik Lokasi GPS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Status tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isActive ? Colors.green.shade200 : Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Laporan Aktif' : 'Laporan Tidak Aktif',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    report.createdAt.toLocal().toString().split('.')[0].substring(0, 16),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isActive) Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.edit3, color: Colors.blueAccent),
                              tooltip: 'Edit Laporan',
                              onPressed: () => _showEditReportSheet(context, ref, report),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                              tooltip: 'Hapus Laporan',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Hapus Laporan?'),
                                    content: const Text('Apakah kamu yakin ingin menghapus laporan banjir ini dari publik?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await ref.read(floodReportRepositoryProvider).deleteReport(report.id);
                                    ref.invalidate(historyReportsProvider);
                                    ref.invalidate(activeFloodReportsProvider);
                                    if (context.mounted) {
                                      AppNotification.show(
                                        context,
                                        type: AppNotificationType.deleteHistory,
                                        message: 'Laporan banjir berhasil dihapus dari riwayat.',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppNotification.show(
                                        context,
                                        type: AppNotificationType.error,
                                        message: 'Gagal menghapus laporan: $e',
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (error, _) => Center(child: Text('Gagal memuat: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ))),
    );
  }
}

void _showEditReportSheet(BuildContext context, WidgetRef ref, FloodReport report) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditReportSheet(report: report, ref: ref),
  );
}

class _EditReportSheet extends StatefulWidget {
  final FloodReport report;
  final WidgetRef ref;

  const _EditReportSheet({required this.report, required this.ref});

  @override
  State<_EditReportSheet> createState() => _EditReportSheetState();
}

class _EditReportSheetState extends State<_EditReportSheet> {
  late WaterDepthLevel _selectedDepth;
  late TextEditingController _noteController;
  File? _newPhoto;
  LatLng? _newLocation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDepth = widget.report.depthLevel;
    _noteController = TextEditingController(text: widget.report.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _newPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, type: AppNotificationType.error, title: 'Error', message: 'Gagal membuka kamera: $e');
      }
    }
  }

  Future<void> _openLocationPicker() async {
    Position? gpsPosition;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        gpsPosition = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      }
    } catch (_) {}

    final startPosition = _newLocation ?? LatLng(widget.report.latitude, widget.report.longitude);
    
    if (!mounted) return;
    final selectedLatLng = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          currentPosition: gpsPosition ?? Position(
            longitude: startPosition.longitude,
            latitude: startPosition.latitude,
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
          ),
          maxRadiusMeters: 500.0,
        ),
      ),
    );

    if (selectedLatLng != null) {
      setState(() {
        _newLocation = selectedLatLng;
      });
    }
  }

  Future<void> _updateReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.ref.read(reportSubmissionRepositoryProvider).updateFullReport(
        reportId: widget.report.id,
        depthLevel: _selectedDepth,
        newPhoto: _newPhoto,
        newLatitude: _newLocation?.latitude,
        newLongitude: _newLocation?.longitude,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      widget.ref.invalidate(historyReportsProvider);
      widget.ref.invalidate(activeFloodReportsProvider);

      if (mounted) {
        Navigator.pop(context);
        AppNotification.show(
          context,
          type: AppNotificationType.submitReport,
          title: 'Laporan Diperbarui',
          message: 'Laporan Anda berhasil diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          type: AppNotificationType.error,
          message: 'Gagal memperbarui laporan.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
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
                  width: 40, height: 4.5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Text(
                'Edit Laporan Banjir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              
              // FOTO
              AspectRatio(
                aspectRatio: 16 / 9,
                child: GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_newPhoto != null)
                            Image.file(_newPhoto!, fit: BoxFit.cover)
                          else if (widget.report.photoUrl.isNotEmpty)
                            Image.network(widget.report.photoUrl, fit: BoxFit.cover)
                          else
                            const Center(child: Icon(LucideIcons.image, size: 40, color: Colors.grey)),
                          Positioned(
                            right: 12, bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.camera, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // KETINGGIAN AIR
              const Text('Ketinggian Air', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: WaterDepthLevel.values.map((level) {
                  final isSelected = _selectedDepth == level;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(level.label),
                    selectedColor: level.color.withValues(alpha: 0.15),
                    side: BorderSide(color: isSelected ? level.color : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
                    labelStyle: TextStyle(
                      color: isSelected ? level.color : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedDepth = level),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // LOKASI
              const Text('Lokasi Kejadian', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _newLocation != null ? Colors.amber.shade50 : Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.mapPin, color: _newLocation != null ? Colors.amber.shade700 : AppColors.primary, size: 20),
                  ),
                  title: Text(
                    _newLocation != null ? 'Titik Lokasi Baru' : (widget.report.address ?? 'Lokasi Semula'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  trailing: TextButton(
                    onPressed: _openLocationPicker,
                    child: const Text('Ubah Lokasi'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CATATAN
              const Text('Catatan Tambahan', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Perbarui deskripsi jika ada perubahan...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 2,
              ),
              

              
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _updateReport,
                icon: _isSubmitting
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.save, size: 18),
                label: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

