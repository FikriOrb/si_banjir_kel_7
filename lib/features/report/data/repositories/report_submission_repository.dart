import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../map/data/models/flood_report.dart';

final reportSubmissionRepositoryProvider =
    Provider<ReportSubmissionRepository>((ref) {
  return ReportSubmissionRepository(Supabase.instance.client);
});

class ReportSubmissionRepository {
  ReportSubmissionRepository(this._client);

  final SupabaseClient _client;

  Future<String> submitReport({
    required double latitude,
    required double longitude,
    required WaterDepthLevel depthLevel,
    required File photo,
    String? address,
    String? note,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Pengguna harus login sebelum membuat laporan.');
    }

    final objectPath =
        'flood_reports/$userId/${DateTime.now().microsecondsSinceEpoch}.jpg';

    await _client.storage.from('report-photos').upload(
          objectPath,
          photo,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final photoUrl = _client.storage.from('report-photos').getPublicUrl(
          objectPath,
        );

    // 🌟 Otomatis mencari nama jalan (Reverse Geocoding) jika tidak ada alamat
    String? finalAddress = address;
    if (finalAddress == null || finalAddress.trim().isEmpty) {
      try {
        final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude');
        final geoResponse = await http.get(url, headers: {
          'User-Agent': 'SistemPeringatanBanjir/1.0',
        });
        if (geoResponse.statusCode == 200) {
          final data = jsonDecode(geoResponse.body);
          if (data['display_name'] != null) {
            finalAddress = data['display_name'] as String;
          }
        }
      } catch (_) {
        // Abaikan jika pencarian alamat gagal (misal: tidak ada internet atau server OS map sedang down)
      }
    }

    final reportId = await _client.rpc<String>(
      'create_flood_report',
      params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_depth_level': depthLevel.name,
        'p_photo_url': photoUrl,
        'p_address': finalAddress,
        'p_note': note,
      },
    );

    return reportId;
  }
}
