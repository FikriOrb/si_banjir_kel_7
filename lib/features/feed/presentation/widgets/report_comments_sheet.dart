import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _ReportCommentsSheetState extends ConsumerState<ReportCommentsSheet> {
  final _commentController = TextEditingController();
  ReportComment? _replyingTo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(reportCommentRepositoryProvider).submitComment(
            reportId: widget.report.id,
            content: text,
            parentId: _replyingTo?.id,
          );
      ref.invalidate(reportCommentsProvider(widget.report.id));
      _commentController.clear();
      setState(() {
        _replyingTo = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e')),
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

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Diskusi Laporan${commentsAsync.hasValue && commentsAsync.value!.isNotEmpty ? ' (${commentsAsync.value!.length})' : ''}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(child: Text('Belum ada diskusi. Mulai percakapan pertama!'));
                    }

                    // Pisahkan komentar utama dan balasan
                    final topLevel = comments.where((c) => c.parentId == null).toList();
                    final replies = comments.where((c) => c.parentId != null).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(reportCommentsProvider(widget.report.id));
                        // Tambahkan sedikit delay agar animasi loading terlihat natural
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: topLevel.length,
                      itemBuilder: (context, index) {
                        final comment = topLevel[index];
                        final commentReplies = replies.where((r) => r.parentId == comment.id).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CommentTile(
                              comment: comment,
                              onReply: () => setState(() => _replyingTo = comment),
                            ),
                            if (commentReplies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0),
                                child: Column(
                                  children: commentReplies.map((reply) {
                                    return _CommentTile(
                                      comment: reply,
                                      isReply: true,
                                    );
                                  }).toList(),
                                ),
                              ),
                            const Divider(height: 24),
                          ],
                        );
                      },
                    ),
                  );
                },
                error: (error, _) => Center(child: Text('Gagal memuat diskusi: $error')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 4),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_replyingTo != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Membalas ${_replyingTo!.userUsername ?? _replyingTo!.userName ?? "Warga"}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                          InkWell(
                            onTap: () => setState(() => _replyingTo = null),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Tambahkan komentar...',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSubmitting ? null : _submitComment,
                          icon: _isSubmitting
                              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.blue),
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

class _CommentTile extends ConsumerWidget {
  final ReportComment comment;
  final VoidCallback? onReply;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;
    final isLiked = currentUserId != null && comment.likesUserIds.contains(currentUserId);
    final isOwner = currentUserId == comment.userId;

    return GestureDetector(
      onLongPress: isOwner ? () => _showDeleteDialog(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isReply ? 12 : 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: comment.userAvatar != null ? NetworkImage(comment.userAvatar!) : null,
              child: comment.userAvatar == null ? Icon(Icons.person, size: isReply ? 16 : 20, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName ?? 'Warga Anonim',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      if (comment.userUsername != null)
                        Text(
                          comment.userUsername!,
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(comment.createdAt.toLocal()),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(comment.content, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (onReply != null)
                        InkWell(
                          onTap: onReply,
                          child: const Text('Balas', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      if (onReply != null) const SizedBox(width: 16),
                      InkWell(
                        onTap: () async {
                          await ref.read(reportCommentRepositoryProvider).toggleLike(comment.id);
                          ref.invalidate(reportCommentsProvider(comment.reportId));
                        },
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            if (comment.likesUserIds.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesUserIds.length}',
                                style: TextStyle(color: isLiked ? Colors.red : Colors.grey, fontSize: 12),
                              ),
                            ]
                          ],
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
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar?'),
        content: const Text('Apakah kamu yakin ingin menghapus komentar ini? Balasan dari komentar ini juga akan terhapus.'),
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
        await ref.read(reportCommentRepositoryProvider).deleteComment(comment.id);
        ref.invalidate(reportCommentsProvider(comment.reportId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return '${diff.inHours}j lalu';
    return '${time.day}/${time.month}';
  }
}
