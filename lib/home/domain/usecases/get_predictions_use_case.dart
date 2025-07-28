import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/prediction.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/repositories/prediction_repository.dart';

class GetPredictionsUseCase {
  final PredictionRepository _predictionRepository;

  GetPredictionsUseCase(this._predictionRepository);

  /// Obtiene predicciones para una ubicación específica
  Future<List<Prediction>> execute({
    required Location location,
    required DateTime timestamp,
  }) async {
    try {
      return await _predictionRepository.getPredictions(
        location: location,
        timestamp: timestamp,
      );
    } catch (e) {
      throw ServerFailure('Error obteniendo predicciones: $e');
    }
  }

  /// Obtiene predicciones para múltiples ubicaciones
  Future<List<Prediction>> executeForMultipleLocations({
    required List<Location> locations,
    required DateTime timestamp,
  }) async {
    try {
      return await _predictionRepository.getPredictionsForMultipleLocations(
        locations: locations,
        timestamp: timestamp,
      );
    } catch (e) {
      throw ServerFailure('Error obteniendo predicciones múltiples: $e');
    }
  }

  /// Obtiene predicciones para una ruta completa
  Future<List<Prediction>> executeForRoute({
    required List<Location> waypoints,
    required DateTime estimatedArrivalTime,
  }) async {
    try {
      return await _predictionRepository.getPredictionsForRoute(
        waypoints: waypoints,
        estimatedArrivalTime: estimatedArrivalTime,
      );
    } catch (e) {
      throw ServerFailure('Error obteniendo predicciones de ruta: $e');
    }
  }

  /// Filtra predicciones por nivel de riesgo
  List<Prediction> filterByRiskLevel(
    List<Prediction> predictions,
    String riskLevel,
  ) {
    return predictions
        .where(
          (prediction) =>
              prediction.riskLevel.toUpperCase() == riskLevel.toUpperCase(),
        )
        .toList();
  }

  /// Filtra predicciones por confiabilidad mínima
  List<Prediction> filterByConfidence(
    List<Prediction> predictions,
    double minConfidence,
  ) {
    return predictions
        .where((prediction) => prediction.confidenceScore >= minConfidence)
        .toList();
  }

  /// Obtiene las predicciones más críticas (alto riesgo y alta confiabilidad)
  List<Prediction> getCriticalPredictions(List<Prediction> predictions) {
    return predictions
        .where((prediction) => prediction.isHighRisk && prediction.isReliable)
        .toList();
  }
}
