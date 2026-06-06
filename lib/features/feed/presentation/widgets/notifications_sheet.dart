import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/report_detail_bottom_sheet.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/providers/notification_settings_provider.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/data/repositories/notification_repository.dart';
import '../providers/nearby_alerts_provider.dart';
import 'report_comments_sheet.dart';
import '../../../map/data/models/flood_report.dart';

class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
            
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pusat Notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              tabs: const [
                Tab(text: 'Peringatan Banjir'),
                Tab(text: 'Komentar & Balasan'),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _NearbyAlertsTab(),
                  _CommentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyAlertsTab extends ConsumerStatefulWidget {
  const _NearbyAlertsTab();

  @override
  ConsumerState<_NearbyAlertsTab> createState() => _NearbyAlertsTabState();
}

class _NearbyAlertsTabState extends ConsumerState<_NearbyAlertsTab> {
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
            content: Text('Gagal mendeteksi lokasi: ${AppError.toMessage(e)}'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Terima peringatan terdekat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
              Switch(
                value: isNotificationEnabled,
                onChanged: (val) async {
                  if (val == true) {
                    final granted = await ref.read(localNotificationServiceProvider).requestPermission();
                    if (!granted) {
                      if (mounted) {
                        AppNotification.show(
                          context,
                          type: AppNotificationType.error,
                          message: 'Izin notifikasi ditolak. Anda harus mengizinkannya di pengaturan perangkat.',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '*Fitur peringatan aktif saat aplikasi terbuka.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              _isRefreshing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : TextButton.icon(
                      onPressed: _fetchLocation,
                      icon: const Icon(LucideIcons.refreshCw, size: 12),
                      label: const Text(
                        'Segarkan GPS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // List
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
    );
  }
}

class _CommentsTab extends ConsumerWidget {
  const _CommentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Interaksi Laporan',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(notificationRepositoryProvider).markAllAsRead();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.messageCircle, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum Ada Interaksi',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isReply = notif.type == 'reply_to_comment';
                  final title = notif.actorName ?? 'Warga Anonim';
                  final subtitle = isReply
                      ? 'Membalas komentar Anda di sebuah laporan banjir.'
                      : 'Mengomentari laporan banjir Anda.';
                      
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: notif.actorAvatar != null ? NetworkImage(notif.actorAvatar!) : null,
                          child: notif.actorAvatar == null ? const Icon(LucideIcons.user, size: 20, color: Colors.grey) : null,
                        ),
                        if (!notif.isRead)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: notif.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                    onTap: () async {
                      if (!notif.isRead) {
                        await ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                      }
                      if (context.mounted) {
                        Navigator.pop(context); // Tutup sheet notifikasi
                        
                        // Fake a flood report to open the comment sheet
                        // We only need the report ID for the comment sheet
                        final dummyReport = FloodReport(
                          id: notif.reportId,
                          userId: '',
                          latitude: 0,
                          longitude: 0,
                          depthLevel: WaterDepthLevel.ankle,
                          photoUrl: '',
                          upvoteCount: 0,
                          downvoteCount: 0,
                          expiresAt: DateTime.now(),
                          createdAt: DateTime.now(),
                          isActive: true,
                        );
                        
                        showReportCommentsSheet(context, dummyReport);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat: ${AppError.toMessage(e)}')),
          ),
        ),
      ],
    );
  }
}
