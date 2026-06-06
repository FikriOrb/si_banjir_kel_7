import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final userNotificationsProvider = StreamProvider.autoDispose<List<UserNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchNotifications();
});

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  Stream<List<UserNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    // Hybrid approach: watch changes, fetch full joined data
    return _client
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((events) async {
      try {
        final response = await _client
            .from('user_notifications')
            .select('*, actor:users!user_notifications_actor_id_fkey(full_name, avatar_url, username)')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
            
        return (response as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(UserNotification.fromJson)
            .toList();
      } catch (e) {
        // Fallback to basic relation if fkey syntax fails
        try {
          final fallbackResponse = await _client
              .from('user_notifications')
              .select('*, actor:actor_id(full_name, avatar_url, username)')
              .eq('user_id', userId)
              .order('created_at', ascending: false);
              
          return (fallbackResponse as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(UserNotification.fromJson)
              .toList();
        } catch (_) {
          return [];
        }
      }
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
