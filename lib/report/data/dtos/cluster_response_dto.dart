
import 'package:safy/report/domain/entities/cluster_entity.dart';
class ClusterResponseDto {
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

  ClusterResponseDto({
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
  });

  factory ClusterResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      // Helper para obtener valores seguros
      T getValue<T>(String key, T defaultValue) {
        return json[key] as T? ?? defaultValue;
      }

      // Helper para convertir tags
      List<String> parseTags(dynamic tags) {
        if (tags is List) {
          return tags.map((tag) => tag.toString()).toList();
        }
        return [];
      }

      return ClusterResponseDto(
        clusterId: getValue('cluster_id', ''),
        clusterType: getValue('cluster_type', 'UNKNOWN'),
        severity: getValue('severity', 'LOW'),
        centerLatitude: getValue('center_latitude', 0.0),
        centerLongitude: getValue('center_longitude', 0.0),
        zone: getValue('zone', 'UNKNOWN'),
        reportCount: getValue('report_count', 0),
        averageSeverity: getValue('average_severity', 0.0),
        maxSeverity: getValue('max_severity', 0),
        distanceFromUser: getValue('distance_from_user', 0.0),
        relevanceScore: getValue('relevance_score', 0.0),
        dominantIncidentType: getValue('dominant_incident_type', 'UNKNOWN'),
        dominantIncidentName: getValue('dominant_incident_name', 'Desconocido'),
        description: getValue('description', 'Sin descripción'),
        riskLevel: getValue('risk_level', 'LOW'),
        tags: parseTags(json['tags']),
      );
    } catch (e) {
      print('[ClusterResponseDto] ❌ Error parsing cluster: $e');
      
      // Retornar cluster por defecto en caso de error
      return ClusterResponseDto(
        clusterId: 'error',
        clusterType: 'UNKNOWN',
        severity: 'LOW',
        centerLatitude: 0.0,
        centerLongitude: 0.0,
        zone: 'UNKNOWN',
        reportCount: 0,
        averageSeverity: 0.0,
        maxSeverity: 0,
        distanceFromUser: 0.0,
        relevanceScore: 0.0,
        dominantIncidentType: 'UNKNOWN',
        dominantIncidentName: 'Error',
        description: 'Error cargando cluster',
        riskLevel: 'LOW',
        tags: [],
      );
    }
  }

  // Convertir DTO a entidad de dominio
  ClusterEntity toDomainEntity() {
    return ClusterEntity(
      clusterId: clusterId,
      clusterType: clusterType,
      severity: severity,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      zone: zone,
      reportCount: reportCount,
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      distanceFromUser: distanceFromUser,
      relevanceScore: relevanceScore,
      dominantIncidentType: dominantIncidentType,
      dominantIncidentName: dominantIncidentName,
      description: description,
      riskLevel: riskLevel,
      tags: tags,
    );
  }

  @override
  String toString() {
    return 'ClusterResponseDto(id: $clusterId, type: $dominantIncidentType, severity: $severity, reports: $reportCount)';
  }
}