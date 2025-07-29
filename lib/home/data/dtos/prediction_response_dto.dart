import 'package:safy/home/domain/entities/prediction.dart';
import 'package:safy/home/domain/entities/location.dart';

class PredictionResponseDto {
  final double latitude;
  final double longitude;
  final String timestamp;
  final double highActivityRisk;
  final double predictedCrimeCount;
  final String riskLevel;
  final int zoneId;
  final String modelVersion;
  final double confidenceScore;

  PredictionResponseDto({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.highActivityRisk,
    required this.predictedCrimeCount,
    required this.riskLevel,
    required this.zoneId,
    required this.modelVersion,
    required this.confidenceScore,
  });

  factory PredictionResponseDto.fromJson(Map<String, dynamic> json) {
    return PredictionResponseDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      highActivityRisk: (json['high_activity_risk'] as num).toDouble(),
      predictedCrimeCount: (json['predicted_crime_count'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      zoneId: json['zone_id'] as int,
      modelVersion: json['model_version'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'high_activity_risk': highActivityRisk,
      'predicted_crime_count': predictedCrimeCount,
      'risk_level': riskLevel,
      'zone_id': zoneId,
      'model_version': modelVersion,
      'confidence_score': confidenceScore,
    };
  }

  @override
  String toString() {
    return 'PredictionResponseDto(latitude: $latitude, longitude: $longitude, riskLevel: $riskLevel, confidence: $confidenceScore)';
  }

  // Mapeo a entidad de dominio
  Prediction toDomainEntity() {
    return Prediction(
      id: zoneId.toString(),
      location: Location(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.parse(timestamp),
      ),
      timestamp: DateTime.parse(timestamp),
      highActivityRisk: highActivityRisk,
      predictedCrimeCount: predictedCrimeCount,
      riskLevel: riskLevel,
      zoneId: zoneId,
      modelVersion: modelVersion,
      confidenceScore: confidenceScore,
    );
  }
}
