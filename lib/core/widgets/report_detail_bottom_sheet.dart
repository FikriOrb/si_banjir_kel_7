import 'package:sistem_peringatan_banjir_berbasis_komunitas/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../../features/map/data/models/flood_report.dart';
import '../../features/map/data/repositories/flood_report_repository.dart';
import '../../features/feed/data/repositories/report_comment_repository.dart';
import '../../features/feed/presentation/widgets/report_comments_sheet.dart';
import '../../features/feed/presentation/pages/feed_page.dart' show FullScreenImagePage, showReportPostDialog;

class ReportDetailBottomSheet extends ConsumerWidget {
  final FloodReport report;

  const ReportDetailBottomSheet({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(activeFloodReportsProvider);

    return reportsAsync.when(
      data: (reports) {
        final updatedReport = reports.firstWhere(
          (r) => r.id == report.id,
          orElse: () => report,
        );
        return _buildBottomSheetContent(context, ref, updatedReport);
      },
      loading: () => _buildBottomSheetContent(context, ref, report),
      error: (_, __) => _buildBottomSheetContent(context, ref, report),
    );
  }

  Widget _buildBottomSheetContent(BuildContext context, WidgetRef ref, FloodReport report) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
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

              // Header (User profile and status badge)
              Row(
                children: [
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
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (report.reporterUsername != null) ...[
                              Text(
                                report.reporterUsername!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF94A3B8)),
                              ),
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
                  // Depth badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: report.depthLevel.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: report.depthLevel.color.withOpacity(0.24), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: report.depthLevel.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${report.depthLevel.label} (± ${report.depthLevel.estimation})',
                          style: TextStyle(
                            color: report.depthLevel.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address Box
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Description Note
              Text(
                (report.note != null && report.note!.isNotEmpty && report.note != 'null') 
                  ? report.note! 
                  : 'Warga melaporkan genangan air setinggi ${report.depthLevel.label} di lokasi ini. Harap berhati-hati saat melintas.',
                style: const TextStyle(
                  fontSize: 13.5, 
                  height: 1.45,
                  color: Color(0xFF334155),
                ),
              ),

              // Image Box
              if (report.photoUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
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
              ],
              
              const Divider(height: 32, color: Color(0xFFE2E8F0)),

              // Progress Bar Validasi
              if (report.upvoteCount > 0 || report.downvoteCount > 0) ...[
                const Text(
                  'Validasi Laporan Warga',
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: report.upvoteCount / (report.upvoteCount + report.downvoteCount)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.green.shade100,
                        color: Colors.amber,
                        minHeight: 6,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Actions (Masih Banjir, Sudah Surut, Comments)
              Row(
                children: [
                  Expanded(
                    child: MapVoteButton(
                      onPressed: () => _handleVote(context, ref, report, true),
                      onLongPress: () => _handleRemoveVote(context, ref, report),
                      icon: LucideIcons.alertTriangle,
                      color: Colors.amber,
                      label: 'Masih Banjir',
                      count: report.upvoteCount,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MapVoteButton(
                      onPressed: () => _handleVote(context, ref, report, false),
                      onLongPress: () => _handleRemoveVote(context, ref, report),
                      icon: LucideIcons.checkCircle,
                      color: AppColors.safe,
                      label: 'Sudah Surut',
                      count: report.downvoteCount,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MapCommentButton(report: report),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVote(BuildContext context, WidgetRef ref, FloodReport report, bool isUpvote) async {
    final voteLabel = isUpvote ? 'Masih Banjir' : 'Sudah Surut';
    
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
    final hasVoted = await ref.read(floodReportRepositoryProvider).hasUserVoted(report.id);
    if (!hasVoted) return; 
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menarik suara: ${AppError.toMessage(e)}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class MapVoteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const MapVoteButton({
    super.key,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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

class MapCommentButton extends ConsumerWidget {
  final FloodReport report;

  const MapCommentButton({super.key, required this.report});

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
