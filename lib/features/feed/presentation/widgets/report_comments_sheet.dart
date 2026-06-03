import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../map/data/models/flood_report.dart';
import '../../data/repositories/report_comment_repository.dart';

Future<void> showReportCommentsSheet(BuildContext context, FloodReport report) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReportCommentsSheet(report: report),
  );
}

class ReportCommentsSheet extends ConsumerStatefulWidget {
  final FloodReport report;
  const ReportCommentsSheet({super.key, required this.report});

  @override
  ConsumerState<ReportCommentsSheet> createState() => _ReportCommentsSheetState();
}

class _ReportCommentsSheetState extends ConsumerState<ReportCommentsSheet>
    with SingleTickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  ReportComment? _replyingTo;
  bool _isSubmitting = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(reportCommentRepositoryProvider).submitComment(
            reportId: widget.report.id,
            content: text,
            parentId: _replyingTo?.id,
          );
      ref.invalidate(reportCommentsProvider(widget.report.id));
      _commentController.clear();
      setState(() => _replyingTo = null);
      // Scroll to bottom after posting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final commentsAsync = ref.watch(reportCommentsProvider(widget.report.id));

    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag Handle ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),

              // ── Header ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.messageCircle, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: commentsAsync.maybeWhen(
                        data: (comments) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diskusi Laporan',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              comments.isEmpty
                                  ? 'Belum ada komentar'
                                  : '${comments.length} komentar',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        orElse: () => const Text(
                          'Diskusi Laporan',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──────────────────────────────────────
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, const Color(0xFFE2E8F0), Colors.transparent],
                  ),
                ),
              ),

              // ── Comments List ────────────────────────────────
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.messageCircle, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada diskusi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Jadilah yang pertama berkomentar!',
                              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      );
                    }

                    final topLevel = comments.where((c) => c.parentId == null).toList();
                    final replies = comments.where((c) => c.parentId != null).toList();

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(reportCommentsProvider(widget.report.id));
                        await Future.delayed(const Duration(milliseconds: 400));
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: topLevel.length,
                        itemBuilder: (context, index) {
                          final comment = topLevel[index];
                          final commentReplies =
                              replies.where((r) => r.parentId == comment.id).toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CommentTile(
                                  comment: comment,
                                  onReply: () {
                                    setState(() => _replyingTo = comment);
                                    _focusNode.requestFocus();
                                  },
                                ),
                                if (commentReplies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48),
                                    child: Column(
                                      children: commentReplies.map((reply) {
                                        return _CommentTile(
                                          comment: reply,
                                          isReply: true,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 40, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Gagal memuat diskusi', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  loading: () => Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  ),
                ),
              ),

              // ── Input Area ───────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reply indicator
                    if (_replyingTo != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.cornerDownRight, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Membalas ${_replyingTo!.userUsername ?? _replyingTo!.userName ?? "Warga"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _replyingTo = null),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(LucideIcons.x, size: 14, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Input row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              controller: _commentController,
                              focusNode: _focusNode,
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Tulis komentar...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedScale(
                          scale: _commentController.text.trim().isNotEmpty ? 1.0 : 0.85,
                          duration: const Duration(milliseconds: 200),
                          child: GestureDetector(
                            onTap: _isSubmitting ? null : _submitComment,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _commentController.text.trim().isNotEmpty
                                      ? [AppColors.primary, AppColors.primaryLight]
                                      : [const Color(0xFFCBD5E1), const Color(0xFFCBD5E1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _commentController.text.trim().isNotEmpty
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment Tile Widget
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends ConsumerStatefulWidget {
  final ReportComment comment;
  final VoidCallback? onReply;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    this.onReply,
    this.isReply = false,
  });

  @override
  ConsumerState<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<_CommentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = Tween<double>(begin: 1, end: 1.4)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_likeController);
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;
    final isLiked = currentUserId != null &&
        widget.comment.likesUserIds.contains(currentUserId);
    final isOwner = currentUserId == widget.comment.userId;
    final double avatarRadius = widget.isReply ? 14 : 18;

    return GestureDetector(
      onLongPress: isOwner
          ? () {
              HapticFeedback.mediumImpact();
              _showDeleteDialog(context, ref);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: widget.comment.userAvatar != null
                  ? NetworkImage(widget.comment.userAvatar!)
                  : null,
              child: widget.comment.userAvatar == null
                  ? Icon(LucideIcons.user,
                      size: avatarRadius, color: const Color(0xFF94A3B8))
                  : null,
            ),
            const SizedBox(width: 10),
            // Content bubble
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: const Radius.circular(16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + username + time
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              widget.comment.userName ?? 'Warga Anonim',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (widget.comment.userUsername != null)
                              Text(
                                widget.comment.userUsername!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              _formatTime(widget.comment.createdAt.toLocal()),
                              style: const TextStyle(
                                color: Color(0xFFADB8C9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Comment text
                        Text(
                          widget.comment.content,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions row
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Row(
                      children: [
                        if (widget.onReply != null) ...[
                          GestureDetector(
                            onTap: widget.onReply,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Balas',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Like button
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            _likeController.forward(from: 0);
                            await ref
                                .read(reportCommentRepositoryProvider)
                                .toggleLike(widget.comment.id);
                            ref.invalidate(reportCommentsProvider(widget.comment.reportId));
                          },
                          child: ScaleTransition(
                            scale: _likeScale,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLiked
                                      ? LucideIcons.heart
                                      : LucideIcons.heart,
                                  size: 14,
                                  color: isLiked ? Colors.red.shade500 : const Color(0xFFADB8C9),
                                ),
                                if (widget.comment.likesUserIds.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.comment.likesUserIds.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isLiked
                                          ? Colors.red.shade500
                                          : const Color(0xFFADB8C9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(context, ref),
                            child: const Icon(
                              LucideIcons.trash2,
                              size: 13,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ],
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

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Komentar?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Komentar dan semua balasannya akan dihapus secara permanen.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(reportCommentRepositoryProvider)
            .deleteComment(widget.comment.id);
        ref.invalidate(reportCommentsProvider(widget.comment.reportId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${time.day}/${time.month}/${time.year}';
  }
}
