import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../map/data/models/flood_report.dart';
import '../../../map/data/repositories/flood_report_repository.dart';
import '../../data/repositories/report_comment_repository.dart';
import '../widgets/report_comments_sheet.dart';
import 'report_map_detail_page.dart';
import '../widgets/notifications_sheet.dart';
import '../providers/nearby_alerts_provider.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/providers/notification_settings_provider.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/data/repositories/notification_repository.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final Map<String, GlobalKey> _itemKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(targetReportIdProvider, (prev, next) {
      if (next != null) {
        Future.delayed(const Duration(milliseconds: 350), () {
          final key = _itemKeys[next];
          if (key != null && key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutBack,
              alignment: 0.2, // Posisikan agak ke atas sedikit
            );
            
            // Hapus target ID setelah beberapa detik agar efek menghilang perlahan
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) ref.read(targetReportIdProvider.notifier).state = null;
            });
          }
        });
      }
    });

    // Listener untuk notifikasi laporan terdekat baru
    ref.listen<List<FloodReport>>(nearbyAlertReportsProvider, (previous, next) {
      if (previous == null || previous.isEmpty) return; // Jangan tembak saat pertama kali muat

      final isEnabled = ref.read(notificationSettingsProvider);
      if (!isEnabled) return;

      // Cari laporan baru di 'next' yang belum ada di 'previous'
      final previousIds = previous.map((r) => r.id).toSet();
      final newReports = next.where((r) => !previousIds.contains(r.id)).toList();

      for (final report in newReports) {
        // Tembakkan notifikasi lokal
        final distance = report.distanceMeters ?? 0.0;
        ref.read(localNotificationServiceProvider).showFloodAlert(
          reportId: report.id,
          distanceMeters: distance,
        );
      }
    });

    final reportsAsync = ref.watch(activeFloodReportsProvider);
    final nearbyReports = ref.watch(nearbyAlertReportsProvider);
    final userNotificationsAsync = ref.watch(userNotificationsProvider);
    
    final unreadCommentsCount = userNotificationsAsync.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      orElse: () => 0,
    );
    
    final alertsCount = nearbyReports.length + unreadCommentsCount;
    final isNotificationEnabled = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Banjir Aktif'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$alertsCount'),
              isLabelVisible: isNotificationEnabled && alertsCount > 0,
              backgroundColor: AppColors.medium,
              child: Icon(
                isNotificationEnabled ? LucideIcons.bell : LucideIcons.bellOff,
                color: isNotificationEnabled ? null : Colors.grey,
              ),
            ),
            tooltip: 'Pusat Notifikasi',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NotificationsSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.droplets, size: 72, color: Colors.blue.shade100),
                    const SizedBox(height: 16),
                    const Text(
                      'Situasi Aman & Kondusif',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada laporan banjir aktif saat ini di wilayah Medan.',
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
              ref.invalidate(activeFloodReportsProvider);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: reports.map((report) {
                    _itemKeys[report.id] ??= GlobalKey();
                    final key = _itemKeys[report.id]!;
                    final isTarget = ref.watch(targetReportIdProvider) == report.id;

                    return AnimatedContainer(
                      key: key,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isTarget ? AppColors.primary : Colors.transparent,
                          width: isTarget ? 3.0 : 0.0,
                        ),
                        boxShadow: isTarget ? [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 4)
                        ] : [],
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Halaman detail
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(
                            children: [
                              // Avatar with ⓘ badge overlay
                              GestureDetector(
                                onTap: report.userId == Supabase.instance.client.auth.currentUser?.id
                                    ? null
                                    : () => showReportPostDialog(context, report),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
                                        ),
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          backgroundImage: report.reporterAvatar != null ? NetworkImage(report.reporterAvatar!) : null,
                                          child: report.reporterAvatar == null ? const Icon(LucideIcons.user, color: Color(0xFF64748B)) : null,
                                        ),
                                      ),
                                      // ⓘ badge at bottom-right (only for other people's posts)
                                      if (report.userId != Supabase.instance.client.auth.currentUser?.id)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                LucideIcons.info,
                                                size: 10,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.reporterName ?? 'Warga Anonim',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (report.reporterUsername != null) ...[
                                          Flexible(
                                            child: Text(
                                              report.reporterUsername!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF94A3B8))),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          report.createdAt.toLocal().toString().split('.')[0].substring(0, 16),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Status pill with custom dot indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: report.reportType == 'flood' ? report.depthLevel.color.withOpacity(0.08) : Colors.amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: report.reportType == 'flood' ? report.depthLevel.color.withOpacity(0.24) : Colors.amber.withOpacity(0.24), width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: report.reportType == 'flood' ? report.depthLevel.color : Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      report.reportType == 'flood' ? report.depthLevel.label : 'Evakuasi Darurat',
                                      style: TextStyle(
                                        color: report.reportType == 'flood' ? report.depthLevel.color : Colors.amber.shade700,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Gambar (Inset rounded border)
                        if (report.photoUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImagePage(imageUrl: report.photoUrl),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: report.photoUrl,
                                  child: AspectRatio(
                                    aspectRatio: 16 / 10,
                                    child: Image.network(
                                      report.photoUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const ColoredBox(
                                        color: Color(0xFFF1F5F9),
                                        child: Center(child: Icon(LucideIcons.imageOff, size: 40, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Caption / Catatan / Lokasi
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lokasi Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9), // Slate 100
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (report.address != null && report.address!.isNotEmpty && report.address != 'null')
                                            ? report.address!
                                            : 'Titik Lokasi (Berdasarkan GPS)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReportLocationMapPage(report: report),
                                          ),
                                        );
                                      },
                                      icon: const Icon(LucideIcons.map, size: 14),
                                      label: const Text('Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                (report.note != null && report.note!.isNotEmpty && report.note != 'null') 
                                  ? report.note! 
                                  : (report.reportType == 'flood'
                                      ? 'Warga melaporkan genangan air setinggi ${report.depthLevel.label} di lokasi ini. Harap berhati-hati saat melintas.'
                                      : 'Warga menambahkan tempat evakuasi darurat di lokasi ini.'),
                                style: const TextStyle(
                                  fontSize: 13.5, 
                                  height: 1.45,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Tombol Validasi & Diskusi
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 6,
                                  children: [
                                    _VoteButton(
                                      onPressed: () => _handleVote(context, ref, report, true),
                                      onLongPress: () => _handleRemoveVote(context, ref, report),
                                      icon: report.reportType == 'flood' ? LucideIcons.alertTriangle : LucideIcons.mapPin,
                                      color: Colors.amber,
                                      label: report.reportType == 'flood' ? 'Masih Banjir' : 'Masih Nampung',
                                      count: report.upvoteCount,
                                    ),
                                    _VoteButton(
                                      onPressed: () => _handleVote(context, ref, report, false),
                                      onLongPress: () => _handleRemoveVote(context, ref, report),
                                      icon: report.reportType == 'flood' ? LucideIcons.checkCircle : LucideIcons.slash,
                                      color: report.reportType == 'flood' ? AppColors.safe : Colors.red,
                                      label: report.reportType == 'flood' ? 'Sudah Surut' : 'Sudah Penuh',
                                      count: report.downvoteCount,
                                    ),
                                  ],
                                ),
                              ),
                              _CommentButton(report: report),
                            ],
                          ),
                        ),
                        
                        // Progress Bar Validasi
                        if (report.upvoteCount > 0 || report.downvoteCount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: report.upvoteCount / (report.upvoteCount + report.downvoteCount)),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: report.reportType == 'flood' ? Colors.green.shade100 : Colors.red.shade100,
                                    color: Colors.amber,
                                    minHeight: 6,
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
        error: (error, _) => Center(child: Text('Gagal memuat: ${AppError.toMessage(error)}')),
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 3,
          itemBuilder: (context, index) => const _SkeletonCard(),
        ),
      ),
    ),
  ),
    );
  }

  Future<void> _handleVote(BuildContext context, WidgetRef ref, FloodReport report, bool isUpvote) async {
    final voteLabel = isUpvote 
        ? (report.reportType == 'flood' ? 'Masih Banjir' : 'Masih Nampung')
        : (report.reportType == 'flood' ? 'Sudah Surut' : 'Sudah Penuh');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Suara'),
        content: Text('Apakah kamu yakin ingin menyatakan bahwa area ini "$voteLabel"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isUpvote ? Colors.orange : Colors.green,
            ),
            child: const Text('Ya, Kirim Suara'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(floodReportRepositoryProvider).voteReport(report.id, isUpvote);
        ref.invalidate(activeFloodReportsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim suara: ${AppError.toMessage(e)}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleRemoveVote(BuildContext context, WidgetRef ref, FloodReport report) async {
    // Cek dulu apakah user sudah vote
    final hasVoted = await ref.read(floodReportRepositoryProvider).hasUserVoted(report.id);
    if (!hasVoted) return; // Jika belum vote, tidak terjadi apa-apa saat ditekan tahan
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Suara?'),
        content: const Text('Apakah kamu ingin menarik kembali (membatalkan) suaramu dari laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Tarik Suara'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(floodReportRepositoryProvider).removeVote(report.id);
        ref.invalidate(activeFloodReportsProvider);
      } catch (e) {
        // Ignored
      }
    }
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 10, color: Colors.grey.shade300),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 12, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Container(width: 200, height: 12, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _VoteButton({
    required this.onPressed,
    required this.onLongPress,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCount = _formatCount(count);
    return Tooltip(
      message: 'Tahan untuk membatalkan suara',
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        ),
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$label ($formattedCount)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
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

class _CommentButton extends ConsumerWidget {
  final FloodReport report;

  const _CommentButton({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(reportCommentsProvider(report.id));

    return commentsAsync.when(
      data: (comments) {
        final count = comments.length;
        final formattedCount = _formatCount(count);
        return IconButton(
          onPressed: () => showReportCommentsSheet(context, report),
          icon: Badge(
            label: Text(
              formattedCount,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            isLabelVisible: count > 0,
            backgroundColor: AppColors.medium,
            child: Icon(
              LucideIcons.messageSquare,
              color: count > 0 ? AppColors.primary : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          tooltip: 'Diskusi Laporan',
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          splashRadius: 20,
        );
      },
      loading: () => const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
      error: (_, __) => IconButton(
        onPressed: () => showReportCommentsSheet(context, report),
        icon: const Icon(LucideIcons.messageSquare, color: Color(0xFF64748B), size: 20),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

String _formatCount(int count) {
  if (count >= 1000) {
    final value = count / 1000;
    final formatted = value.toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      return '${formatted.substring(0, formatted.length - 2)}K+';
    }
    return '${formatted.replaceAll('.', ',')}K+';
  }
  return '$count';
}

// ─────────────────────────────────────────────────────────────
// Report Post Dialog
// ─────────────────────────────────────────────────────────────

void showReportPostDialog(BuildContext context, FloodReport report) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportPostSheet(report: report),
  );
}

class _ReportPostSheet extends StatefulWidget {
  final FloodReport report;
  const _ReportPostSheet({required this.report});

  @override
  State<_ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<_ReportPostSheet> {
  static const _categories = [
    _ReportCategory(
      icon: LucideIcons.alertTriangle,
      label: 'Informasi Palsu',
      desc: 'Laporan banjir tidak sesuai kenyataan di lapangan',
      color: Color(0xFFEF4444),
    ),
    _ReportCategory(
      icon: LucideIcons.imageOff,
      label: 'Foto Tidak Relevan',
      desc: 'Gambar tidak menunjukkan kondisi banjir yang dilaporkan',
      color: Color(0xFFF97316),
    ),
    _ReportCategory(
      icon: LucideIcons.mapPinOff,
      label: 'Lokasi Tidak Akurat',
      desc: 'Koordinat/alamat tidak sesuai dengan titik banjir sebenarnya',
      color: Color(0xFFEAB308),
    ),
    _ReportCategory(
      icon: LucideIcons.repeat,
      label: 'Duplikat Laporan',
      desc: 'Laporan yang sama sudah pernah dikirimkan sebelumnya',
      color: Color(0xFF8B5CF6),
    ),
    _ReportCategory(
      icon: LucideIcons.ban,
      label: 'Konten Tidak Pantas',
      desc: 'Berisi ujaran kebencian, spam, atau konten menyinggung',
      color: Color(0xFFEC4899),
    ),
    _ReportCategory(
      icon: LucideIcons.helpCircle,
      label: 'Lainnya',
      desc: 'Alasan lain yang tidak tercantum di atas',
      color: Color(0xFF64748B),
    ),
  ];

  static const _templates = [
    'Saya sudah cek langsung ke lokasi dan tidak ada genangan air.',
    'Foto ini diambil dari kejadian lama/berbeda, bukan kondisi saat ini.',
    'Titik koordinat jauh dari lokasi banjir yang sebenarnya.',
    'Laporan ini sudah ada duplikatnya dari pengguna lain.',
    'Konten tidak berhubungan dengan kondisi banjir.',
  ];

  int? _selectedCategory;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih kategori laporan terlebih dahulu'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Laporan berhasil dikirim. Terima kasih!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.flag, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporkan Postingan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Bantu kami menjaga keakuratan informasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(34, 34),
                    ),
                  ),
                ],
              ),
            ),

            // Report context card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: widget.report.reporterAvatar != null
                          ? NetworkImage(widget.report.reporterAvatar!)
                          : null,
                      child: widget.report.reporterAvatar == null
                          ? const Icon(LucideIcons.user, size: 16, color: Color(0xFF94A3B8))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.report.reporterName ?? 'Warga Anonim',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            widget.report.address ?? 'Lokasi tidak diketahui',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label
                    const Text(
                      'Pilih Kategori Laporan',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category list
                    ...List.generate(_categories.length, (i) {
                      final cat = _categories[i];
                      final selected = _selectedCategory == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? cat.color : const Color(0xFFE2E8F0),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(cat.icon, color: cat.color, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: selected ? cat.color : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      cat.desc,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(LucideIcons.checkCircle, color: cat.color, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Templates
                    const Text(
                      'Template Catatan Cepat',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _templates.map((t) {
                        return GestureDetector(
                          onTap: () {
                            _noteController.text = t;
                            _noteController.selection = TextSelection.fromPosition(
                              TextPosition(offset: t.length),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.zap, size: 11, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  t.length > 36 ? '${t.substring(0, 36)}…' : t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Notes field
                    const Text(
                      'Catatan Tambahan (opsional)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 4,
                        minLines: 3,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF1E293B),
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Jelaskan lebih detail alasan laporan Anda...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                          counterStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.flag, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Kirim Laporan',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCategory {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  const _ReportCategory({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });
}
