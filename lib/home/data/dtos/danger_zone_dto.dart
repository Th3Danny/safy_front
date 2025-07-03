

import 'package:safy/home/data/dtos/location_dto.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/value_objects/danger_level.dart';

class DangerZoneDto {
  final String id;
  final LocationDto center;
  final double radiusMeters;
  final String dangerLevel;
  final int reportCount;
  final String lastReportAt;
  final List<String> incidentTypes;
  final bool isActive;

  DangerZoneDto({
    required this.id,
    required this.center,
    required this.radiusMeters,
    required this.dangerLevel,
    required this.reportCount,
    required this.lastReportAt,
    required this.incidentTypes,
    required this.isActive,
  });

  factory DangerZoneDto.fromJson(Map<String, dynamic> json) {
    return DangerZoneDto(
      id: json['id'] as String,
      center: LocationDto.fromJson(json['center'] as Map<String, dynamic>),
      radiusMeters: (json['radius_meters'] as num).toDouble(),
      dangerLevel: json['danger_level'] as String,
      reportCount: json['report_count'] as int,
      lastReportAt: json['last_report_at'] as String,
      incidentTypes: List<String>.from(json['incident_types'] as List),
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center': center.toJson(),
      'radius_meters': radiusMeters,
      'danger_level': dangerLevel,
      'report_count': reportCount,
      'last_report_at': lastReportAt,
      'incident_types': incidentTypes,
      'is_active': isActive,
    };
  }

  DangerZone toDomainEntity() {
    return DangerZone(
      id: id,
      center: center.toDomainEntity(),
      radiusMeters: radiusMeters,
      dangerLevel: _parseDangerLevel(dangerLevel),
      reportCount: reportCount,
      lastReportAt: DateTime.parse(lastReportAt),
      incidentTypes: incidentTypes,
      isActive: isActive,
    );
  }

  DangerLevel _parseDangerLevel(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return DangerLevel.low;
      case 'medium':
        return DangerLevel.medium;
      case 'high':
        return DangerLevel.high;
      case 'critical':
        return DangerLevel.critical;
      default:
        return DangerLevel.low;
    }
  }
}