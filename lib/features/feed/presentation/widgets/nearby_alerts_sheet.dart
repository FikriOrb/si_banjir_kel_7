import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/report_detail_bottom_sheet.dart';
import '../../../../core/providers/notification_settings_provider.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../providers/nearby_alerts_provider.dart';

class NearbyAlertsBottomSheet extends ConsumerStatefulWidget {
  const NearbyAlertsBottomSheet({super.key});

  @override
  ConsumerState<NearbyAlertsBottomSheet> createState() => _NearbyAlertsBottomSheetState();
}

class _NearbyAlertsBottomSheetState extends ConsumerState<NearbyAlertsBottomSheet> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentPos = ref.read(currentAlertPositionProvider);
      if (currentPos == null) {
        _fetchLocation();
      }
    });
  }

  Future<void> _fetchLocation() async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan GPS perangkat belum aktif.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin GPS ditolak oleh pengguna.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin GPS ditolak permanen. Aktifkan di pengaturan.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      ref.read(currentAlertPositionProvider.notifier).state = position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendeteksi lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(currentAlertPositionProvider);
    final nearbyReports = ref.watch(nearbyAlertReportsProvider);
    final isNotificationEnabled = ref.watch(notificationSettingsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
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

            // Header Row (Title and Refresh button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(LucideIcons.bell, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Pemberitahuan Banjir Terdekat',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  _isRefreshing
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _fetchLocation,
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          label: const Text(
                            'Segarkan',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Terima notifikasi laporan masuk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
                  Switch(
                    value: isNotificationEnabled,
                    onChanged: (val) async {
                      if (val == true) {
                        final granted = await ref.read(localNotificationServiceProvider).requestPermission();
                        if (!granted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Izin notifikasi ditolak. Anda harus mengizinkannya di pengaturan perangkat.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return; // Batalkan jika ditolak
                        }
                      }
                      ref.read(notificationSettingsProvider.notifier).toggle();
                    },
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '*Fitur notifikasi 24 jam (FCM) masih dalam tahap pemeliharaan. Saat ini peringatan hanya masuk saat aplikasi sedang dibuka atau berjalan di latar.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Content List
            Expanded(
              child: position == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.mapPin, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'Menunggu Izin Lokasi...',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Gunakan tombol Segarkan di atas untuk meminta koordinat lokasi Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : nearbyReports.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.checkCircle, size: 48, color: Colors.green.shade200),
                                const SizedBox(height: 16),
                                const Text(
                                  'Wilayah Aman',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tidak ada laporan banjir aktif yang terdeteksi dalam radius 5 km di sekitar lokasi Anda saat ini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: nearbyReports.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final report = nearbyReports[index];
                            final distance = report.distanceMeters;
                            final String distanceText = distance != null
                                ? (distance >= 1000
                                    ? '${(distance / 1000).toStringAsFixed(1).replaceAll('.', ',')} km dari Anda'
                                    : '${distance.round()} m dari Anda')
                                : 'Radius Terdekat';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: report.depthLevel.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.alertTriangle,
                                  color: report.depthLevel.color,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                (report.address != null && report.address!.isNotEmpty && report.address != 'null')
                                    ? report.address!
                                    : 'Titik Banjir Warga',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    distanceText,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFCBD5E1))),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Level ${report.depthLevel.label}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: report.depthLevel.color,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ReportDetailBottomSheet(report: report),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
