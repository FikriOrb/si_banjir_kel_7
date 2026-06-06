class UserNotification {
  final String id;
  final String userId;
  final String actorId;
  final String type; // 'comment_on_report' or 'reply_to_comment'
  final String reportId;
  final String commentId;
  final bool isRead;
  final DateTime createdAt;
  final String? actorName;
  final String? actorAvatar;
  final String? actorUsername;

  UserNotification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    required this.reportId,
    required this.commentId,
    required this.isRead,
    required this.createdAt,
    this.actorName,
    this.actorAvatar,
    this.actorUsername,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String,
      reportId: json['report_id'] as String,
      commentId: json['comment_id'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actorName: json['actor'] != null ? json['actor']['full_name'] as String? : null,
      actorAvatar: json['actor'] != null ? json['actor']['avatar_url'] as String? : null,
      actorUsername: json['actor'] != null ? json['actor']['username'] as String? : null,
    );
  }
}
