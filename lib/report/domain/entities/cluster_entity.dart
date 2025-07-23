
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
  });

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

  @override
  String toString() {
    return 'ClusterEntity(id: $clusterId, type: $dominantIncidentType, severity: $severity, reports: $reportCount, lat: $centerLatitude, lng: $centerLongitude)';
  }
}