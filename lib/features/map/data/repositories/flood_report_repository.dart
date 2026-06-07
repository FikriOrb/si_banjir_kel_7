import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flood_report.dart';

final floodReportRepositoryProvider = Provider<FloodReportRepository>((ref) {
  return FloodReportRepository(Supabase.instance.client);
});

final activeFloodReportsProvider =
    StreamProvider.autoDispose<List<FloodReport>>((ref) {
  return ref.watch(floodReportRepositoryProvider).watchActiveReports();
});

final historyReportsProvider =
    FutureProvider.autoDispose<List<FloodReport>>((ref) async {
  return ref.watch(floodReportRepositoryProvider).fetchUserHistory();
});

class FloodReportRepository {
  FloodReportRepository(this._client);

  final SupabaseClient _client;

  Future<List<FloodReport>> fetchActiveReports() async {
    try {
      // Panggil pembersihan otomatis laporan kedaluwarsa di background
      await _client.rpc('expire_stale_flood_reports');
    } catch (_) {}

    final response = await _client.rpc<List<dynamic>>('get_active_flood_reports');
    final reports = response.cast<Map<String, dynamic>>();
    
    if (reports.isEmpty) return [];

    final userIds = reports.map((r) => r['user_id'] as String).toSet().toList();
    final usersResponse = await _client
        .from('users')
        .select('id, full_name, username, avatar_url')
        .inFilter('id', userIds);

    final usersMap = {
      for (var u in usersResponse as List<dynamic>) 
        u['id']: u
    };

    return reports.map((json) {
      final mutableJson = Map<String, dynamic>.of(json);
      final userId = mutableJson['user_id'] as String;
      if (usersMap.containsKey(userId)) {
        final u = usersMap[userId] as Map<String, dynamic>;
        mutableJson['users'] = {
          'full_name': u['full_name'],
          'username': u['username'],
          'avatar_url': u['avatar_url']
        };
      }
      return FloodReport.fromJson(mutableJson);
    }).toList(growable: false);
  }

  Future<List<FloodReport>> fetchUserHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('flood_reports')
        .select('*, users(full_name, avatar_url, username)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FloodReport.fromJson)
        .toList(growable: false);
  }

  Future<void> deleteReport(String reportId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('flood_reports')
          .delete()
          .eq('id', reportId)
          .eq('user_id', userId);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> updateReport(String reportId, {required String depthLevel, String? note}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('flood_reports')
        .update({
          'depth_level': depthLevel,
          if (note != null) 'note': note,
        })
        .eq('id', reportId)
        .eq('user_id', userId);
  }

  Future<void> voteReport(String reportId, bool isUpvote) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Cek apakah user sudah pernah vote sebelumnya
    final existingVote = await _client
        .from('report_validations')
        .select('id')
        .eq('report_id', reportId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingVote != null) {
      // Jika sudah ada, perbarui suaranya (ubah upvote jadi downvote atau sebaliknya)
      await _client.from('report_validations').update({
        'vote_type': isUpvote ? 'upvote' : 'downvote',
      }).eq('id', existingVote['id']);
    } else {
      // Jika belum ada, buat suara baru
      await _client.from('report_validations').insert({
        'report_id': reportId,
        'user_id': userId,
        'vote_type': isUpvote ? 'upvote' : 'downvote',
      });
    }
  }

  Future<void> removeVote(String reportId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Kamu belum login.');

    final response = await _client
        .from('report_validations')
        .delete()
        .eq('report_id', reportId)
        .eq('user_id', userId)
        .select();

    if ((response as List).isEmpty) {
      throw Exception('Anda belum vote.');
    }
  }

  Future<void> reportPost(String reportId, String category, String? note) async {
    try {
      await _client.rpc('report_post', params: {
        'p_report_id': reportId,
        'p_category': category,
        'p_note': note,
      });
    } catch (e) {
      if (e.toString().contains('Anda sudah pernah melaporkan')) {
        throw Exception('Anda sudah pernah melaporkan postingan ini.');
      }
      rethrow;
    }
  }

  Future<bool> hasUserVoted(String reportId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('report_validations')
        .select('id')
        .eq('report_id', reportId)
        .eq('user_id', userId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  Stream<List<FloodReport>> watchActiveReports() {
    final controller = StreamController<List<FloodReport>>();

    Future<void> pushSnapshot() async {
      try {
        if (!controller.isClosed) {
          controller.add(await fetchActiveReports());
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    final channel = _client
        .channel('public:flood_reports_and_validations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'flood_reports',
          callback: (_) => pushSnapshot(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'report_validations',
          callback: (_) => pushSnapshot(),
        )
        .subscribe();

    pushSnapshot();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  Future<List<FloodReport>> fetchReportsWithinRadius({
    required double latitude,
    required double longitude,
    int radiusMeters = 500,
  }) async {
    final response = await _client.rpc<List<dynamic>>(
      'get_flood_reports_within_radius',
      params: {
        'user_latitude': latitude,
        'user_longitude': longitude,
        'radius_meters': radiusMeters,
      },
    );

    return response
        .cast<Map<String, dynamic>>()
        .map(FloodReport.fromJson)
        .toList(growable: false);
  }
}
