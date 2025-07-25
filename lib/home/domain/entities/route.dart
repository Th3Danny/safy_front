

import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/value_objects/safety_level.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';

class RouteEntity {
  final String id;
  final String name;
  final List<Location> waypoints;
  final Location startPoint;
  final Location endPoint;
  final double distanceKm;
  final int durationMinutes;
  final SafetyLevel safetyLevel;
  final TransportMode transportMode;
  final bool isRecommended;
  final DateTime createdAt;
  final List<String> warnings;

  RouteEntity({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.startPoint,
    required this.endPoint,
    required this.distanceKm,
    required this.durationMinutes,
    required this.safetyLevel,
    required this.transportMode,
    this.isRecommended = false,
    DateTime? createdAt,
    this.warnings = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // Métodos de negocio
  bool get isSafe => safetyLevel.percentage >= 70;
  bool get hasDangerWarnings => warnings.isNotEmpty;
  
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationMinutes min';

  double get estimatedArrivalTime {
    final now = DateTime.now();
    return now.add(Duration(minutes: durationMinutes)).millisecondsSinceEpoch.toDouble();
  }

  RouteEntity copyWith({
    String? id,
    String? name,
    List<Location>? waypoints,
    Location? startPoint,
    Location? endPoint,
    double? distanceKm,
    int? durationMinutes,
    SafetyLevel? safetyLevel,
    TransportMode? transportMode,
    bool? isRecommended,
    DateTime? createdAt,
    List<String>? warnings,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      waypoints: waypoints ?? this.waypoints,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      transportMode: transportMode ?? this.transportMode,
      isRecommended: isRecommended ?? this.isRecommended,
      createdAt: createdAt ?? this.createdAt,
      warnings: warnings ?? this.warnings,
    );
  }
}