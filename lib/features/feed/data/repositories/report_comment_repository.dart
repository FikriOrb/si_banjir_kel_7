import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportComment {
  final String id;
  final String reportId;
  final String userId;
  final String? parentId;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userUsername;
  final String? userAvatar;
  final List<String> likesUserIds;

  ReportComment({
    required this.id,
    required this.reportId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userUsername,
    this.userAvatar,
    this.likesUserIds = const [],
  });

  factory ReportComment.fromJson(Map<String, dynamic> json) {
    return ReportComment(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['users'] != null ? json['users']['full_name'] as String? : null,
      userUsername: json['users'] != null ? json['users']['username'] as String? : null,
      userAvatar: json['users'] != null ? json['users']['avatar_url'] as String? : null,
      likesUserIds: json['likes_user_ids'] != null 
          ? List<String>.from(json['likes_user_ids'] as List)
          : const [],
    );
  }
}

final reportCommentRepositoryProvider = Provider<ReportCommentRepository>((ref) {
  return ReportCommentRepository(Supabase.instance.client);
});

final reportCommentsProvider = StreamProvider.family<List<ReportComment>, String>((ref, reportId) {
  return ref.watch(reportCommentRepositoryProvider).watchComments(reportId);
});

class ReportCommentRepository {
  final SupabaseClient _client;

  ReportCommentRepository(this._client);

  Stream<List<ReportComment>> watchComments(String reportId) {
    // Karena kita tidak bisa melakukan JOIN langsung di stream (karena OnPostgresChanges tidak support fetch relasi),
    // kita gunakan pendekatan hybrid: listen ke changes, lalu fetch ulang query full dengan JOIN.
    
    return _client
        .from('report_comments')
        .stream(primaryKey: ['id'])
        .eq('report_id', reportId)
        .order('created_at', ascending: true)
        .asyncMap((events) async {
          // Fetch full data with users info for this report
          final response = await _client
              .from('report_comments')
              .select('*, users(full_name, username, avatar_url)')
              .eq('report_id', reportId)
              .order('created_at', ascending: true);
              
          final comments = (response as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(ReportComment.fromJson)
              .toList();
          return comments;
        });
  }

  Future<void> submitComment({
    required String reportId,
    required String content,
    String? parentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Silakan login terlebih dahulu.');

    await _client.from('report_comments').insert({
      'report_id': reportId,
      'user_id': userId,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  Future<void> toggleLike(String commentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Silakan login terlebih dahulu.');

    await _client.rpc('toggle_comment_like', params: {
      'p_comment_id': commentId,
    });
  }

  Future<void> deleteComment(String commentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Silakan login terlebih dahulu.');

    final response = await _client
        .from('report_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', userId)
        .select();

    if (response.isEmpty) {
      throw Exception('Gagal menghapus (Mungkin karena delay jaringan atau ditolak server).');
    }
  }
}
