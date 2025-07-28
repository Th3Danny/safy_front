import 'package:safy/report/domain/value_objects/danger_zone_radius_calculator.dart';

class ClusterEntity {
  final String clusterId;
  final String clusterType;
  final String severity;
  final double centerLatitude;
  final double centerLongitude;
  final String zone;
  final int reportCount;
  final double averageSeverity;
  final int maxSeverity;
  final double distanceFromUser;
  final double relevanceScore;
  final String dominantIncidentType;
  final String dominantIncidentName;
  final String description;
  final String riskLevel;
  final List<String> tags;

  // Propiedades calculadas para el radio de la zona de peligro
  late final double _calculatedRadius;
  late final String _zoneColor;
  late final double _zoneOpacity;
  late final double _borderWidth;

  ClusterEntity({
    required this.clusterId,
    required this.clusterType,
    required this.severity,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.zone,
    required this.reportCount,
    required this.averageSeverity,
    required this.maxSeverity,
    required this.distanceFromUser,
    required this.relevanceScore,
    required this.dominantIncidentType,
    required this.dominantIncidentName,
    required this.description,
    required this.riskLevel,
    required this.tags,
  }) {
    // Calcular propiedades de la zona de peligro
    final radiusInfo = DangerZoneRadiusCalculator.calculateRecommendedRadius(
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      reportCount: reportCount,
      riskLevel: riskLevel,
      clusterType: clusterType,
    );

    _calculatedRadius = radiusInfo['radius'] as double;
    _zoneColor = radiusInfo['color'] as String;
    _zoneOpacity = radiusInfo['opacity'] as double;
    _borderWidth = radiusInfo['borderWidth'] as double;
  }

  // Mapear severidad de texto a número para visualización
  int get severityNumber {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 5;
      case 'HIGH':
        return 4;
      case 'MEDIUM':
        return 3;
      case 'LOW':
        return 2;
      default:
        return maxSeverity > 0 ? maxSeverity : 1;
    }
  }

  // Getters para las propiedades calculadas de la zona de peligro
  double get calculatedRadius => _calculatedRadius;
  String get zoneColor => _zoneColor;
  double get zoneOpacity => _zoneOpacity;
  double get borderWidth => _borderWidth;

  @override
  String toString() {
    return 'ClusterEntity(id: $clusterId, type: $dominantIncidentType, severity: $severity, reports: $reportCount, lat: $centerLatitude, lng: $centerLongitude, radius: ${_calculatedRadius.toStringAsFixed(1)}m)';
  }
}
