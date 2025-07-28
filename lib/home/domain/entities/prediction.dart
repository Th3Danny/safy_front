import 'package:safy/home/domain/entities/location.dart';

class Prediction {
  final String id;
  final Location location;
  final DateTime timestamp;
  final double highActivityRisk;
  final double predictedCrimeCount;
  final String riskLevel;
  final int zoneId;
  final String modelVersion;
  final double confidenceScore;

  Prediction({
    required this.id,
    required this.location,
    required this.timestamp,
    required this.highActivityRisk,
    required this.predictedCrimeCount,
    required this.riskLevel,
    required this.zoneId,
    required this.modelVersion,
    required this.confidenceScore,
  });

  // Métodos de negocio
  bool get isHighRisk =>
      riskLevel.toUpperCase() == 'HIGH' ||
      riskLevel.toUpperCase() == 'CRITICAL';
  bool get isReliable => confidenceScore >= 0.7;

  String get riskDescription {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return 'Riesgo bajo';
      case 'MEDIUM':
        return 'Riesgo medio';
      case 'HIGH':
        return 'Riesgo alto';
      case 'CRITICAL':
        return 'Riesgo crítico';
      default:
        return 'Riesgo desconocido';
    }
  }

  String get confidenceDescription {
    if (confidenceScore >= 0.9) return 'Muy alta';
    if (confidenceScore >= 0.7) return 'Alta';
    if (confidenceScore >= 0.5) return 'Media';
    return 'Baja';
  }

  @override
  String toString() {
    return 'Prediction(id: $id, location: ${location.latitude}, ${location.longitude}, riskLevel: $riskLevel, confidence: $confidenceScore)';
  }
}
