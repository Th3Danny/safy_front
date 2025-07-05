

import 'package:safy/home/data/dtos/location_dto.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/value_objects/safety_level.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';

class RouteDto {
  final String id;
  final String name;
  final List<LocationDto> waypoints;
  final LocationDto startPoint;
  final LocationDto endPoint;
  final double distanceKm;
  final int durationMinutes;
  final double safetyPercentage;
  final String safetyDescription;
  final String transportMode;
  final bool isRecommended;
  final String createdAt;
  final List<String> warnings;

  RouteDto({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.startPoint,
    required this.endPoint,
    required this.distanceKm,
    required this.durationMinutes,
    required this.safetyPercentage,
    required this.safetyDescription,
    required this.transportMode,
    required this.isRecommended,
    required this.createdAt,
    required this.warnings,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    return RouteDto(
      id: json['id'] as String,
      name: json['name'] as String,
      waypoints: (json['waypoints'] as List)
          .map((e) => LocationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      startPoint: LocationDto.fromJson(json['start_point'] as Map<String, dynamic>),
      endPoint: LocationDto.fromJson(json['end_point'] as Map<String, dynamic>),
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      safetyPercentage: (json['safety_percentage'] as num).toDouble(),
      safetyDescription: json['safety_description'] as String,
      transportMode: json['transport_mode'] as String,
      isRecommended: json['is_recommended'] as bool,
      createdAt: json['created_at'] as String,
      warnings: List<String>.from(json['warnings'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
      'start_point': startPoint.toJson(),
      'end_point': endPoint.toJson(),
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'safety_percentage': safetyPercentage,
      'safety_description': safetyDescription,
      'transport_mode': transportMode,
      'is_recommended': isRecommended,
      'created_at': createdAt,
      'warnings': warnings,
    };
  }

  // Mapeo a entidad de dominio
  RouteEntity toDomainEntity() {
    return RouteEntity(
      id: id,
      name: name,
      waypoints: waypoints.map((e) => e.toDomainEntity()).toList(),
      startPoint: startPoint.toDomainEntity(),
      endPoint: endPoint.toDomainEntity(),
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      safetyLevel: SafetyLevel(
        percentage: safetyPercentage,
        description: safetyDescription,
      ),
      transportMode: TransportMode.fromString(transportMode),
      isRecommended: isRecommended,
      createdAt: DateTime.parse(createdAt),
      warnings: warnings,
    );
  }

  // Mapeo desde entidad de dominio
  factory RouteDto.fromDomainEntity(RouteEntity entity) {
    return RouteDto(
      id: entity.id,
      name: entity.name,
      waypoints: entity.waypoints.map((e) => LocationDto.fromDomainEntity(e)).toList(),
      startPoint: LocationDto.fromDomainEntity(entity.startPoint),
      endPoint: LocationDto.fromDomainEntity(entity.endPoint),
      distanceKm: entity.distanceKm,
      durationMinutes: entity.durationMinutes,
      safetyPercentage: entity.safetyLevel.percentage,
      safetyDescription: entity.safetyLevel.description,
      transportMode: entity.transportMode.apiIdentifier,
      isRecommended: entity.isRecommended,
      createdAt: entity.createdAt.toIso8601String(),
      warnings: entity.warnings,
    );
  }
}
