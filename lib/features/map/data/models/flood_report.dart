import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';

enum WaterDepthLevel {
  ankle,
  calf,
  knee,
  waist,
  chest;

  String get label {
    return switch (this) {
      WaterDepthLevel.ankle => 'Mata kaki',
      WaterDepthLevel.calf => 'Betis',
      WaterDepthLevel.knee => 'Lutut',
      WaterDepthLevel.waist => 'Pinggang',
      WaterDepthLevel.chest => 'Dada / Ekstrem',
    };
  }

  String get estimation {
    return switch (this) {
      WaterDepthLevel.ankle => '10-20 cm',
      WaterDepthLevel.calf => '30-40 cm',
      WaterDepthLevel.knee => '50-60 cm',
      WaterDepthLevel.waist => '80-100 cm',
      WaterDepthLevel.chest => '> 100 cm',
    };
  }

  Color get color {
    return switch (this) {
      WaterDepthLevel.ankle => AppColors.low,
      WaterDepthLevel.calf => AppColors.medium,
      WaterDepthLevel.knee => AppColors.danger,
      WaterDepthLevel.waist => AppColors.danger,
      WaterDepthLevel.chest => AppColors.extreme,
    };
  }

  double get markerHue {
    return switch (this) {
      WaterDepthLevel.ankle => BitmapDescriptor.hueYellow,
      WaterDepthLevel.calf => BitmapDescriptor.hueOrange,
      WaterDepthLevel.knee => BitmapDescriptor.hueRed,
      WaterDepthLevel.waist => BitmapDescriptor.hueRed,
      WaterDepthLevel.chest => BitmapDescriptor.hueMagenta,
    };
  }

  static WaterDepthLevel fromJson(String value) {
    return WaterDepthLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => WaterDepthLevel.ankle,
    );
  }
}

class FloodReport {
  const FloodReport({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.depthLevel,
    required this.photoUrl,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.expiresAt,
    required this.createdAt,
    required this.isActive,
    this.address,
    this.note,
    this.distanceMeters,
    this.reporterName,
    this.reporterUsername,
    this.reporterAvatar,
  });

  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final WaterDepthLevel depthLevel;
  final String photoUrl;
  final int upvoteCount;
  final int downvoteCount;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool isActive;
  final String? address;
  final String? note;
  final double? distanceMeters;
  final String? reporterName;
  final String? reporterUsername;
  final String? reporterAvatar;

  LatLng get latLng => LatLng(latitude, longitude);

  factory FloodReport.fromJson(Map<String, dynamic> json) {
    return FloodReport(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      depthLevel: WaterDepthLevel.fromJson(json['depth_level'] as String),
      photoUrl: (json['photo_url'] as String?) ?? '',
      upvoteCount: (json['upvote_count'] as num?)?.toInt() ?? 0,
      downvoteCount: (json['downvote_count'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      isActive: (json['is_active'] as bool?) ?? true,
      address: json['address'] as String?,
      note: json['note'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      reporterName: json['users'] != null ? json['users']['full_name'] as String? : null,
      reporterUsername: json['users'] != null ? json['users']['username'] as String? : null,
      reporterAvatar: json['users'] != null ? json['users']['avatar_url'] as String? : null,
    );
  }
}
