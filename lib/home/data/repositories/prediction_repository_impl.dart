import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/data/datasources/prediction_api_client.dart';
import 'package:safy/home/data/dtos/prediction_request_dto.dart';
import 'package:safy/home/domain/entities/prediction.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/repositories/prediction_repository.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  final PredictionApiClient _apiClient;

  PredictionRepositoryImpl(this._apiClient);

  @override
  Future<List<Prediction>> getPredictions({
    required Location location,
    required DateTime timestamp,
  }) async {
    try {
      print(
        '[PredictionRepository] 🔮 Obteniendo predicciones para ubicación: ${location.latitude}, ${location.longitude}',
      );
      print(
        '[PredictionRepository] 📅 Timestamp: ${timestamp.toIso8601String()}',
      );

      final request = PredictionRequestDto(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: timestamp.toIso8601String(),
      );

      final predictionDtos = await _apiClient.getPredictions(request: request);

      final predictions =
          predictionDtos.map((dto) => dto.toDomainEntity()).toList();

      print(
        '[PredictionRepository] ✅ Predicciones obtenidas: ${predictions.length}',
      );
      for (final prediction in predictions) {
        print(
          '[PredictionRepository] 📍 Predicción: ${prediction.riskLevel} (${prediction.confidenceDescription})',
        );
      }

      return predictions;
    } catch (e) {
      print('[PredictionRepository] ❌ Error obteniendo predicciones: $e');
      throw ServerFailure('Error obteniendo predicciones: $e');
    }
  }

  @override
  Future<List<Prediction>> getPredictionsForMultipleLocations({
    required List<Location> locations,
    required DateTime timestamp,
  }) async {
    try {
      print(
        '[PredictionRepository] 🔮 Obteniendo predicciones para ${locations.length} ubicaciones',
      );

      final requests =
          locations
              .map(
                (location) => PredictionRequestDto(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  timestamp: timestamp.toIso8601String(),
                ),
              )
              .toList();

      final predictionDtos = await _apiClient
          .getPredictionsForMultipleLocations(requests: requests);

      final predictions =
          predictionDtos.map((dto) => dto.toDomainEntity()).toList();

      print(
        '[PredictionRepository] ✅ Predicciones obtenidas: ${predictions.length}',
      );

      return predictions;
    } catch (e) {
      print(
        '[PredictionRepository] ❌ Error obteniendo predicciones múltiples: $e',
      );
      throw ServerFailure('Error obteniendo predicciones múltiples: $e');
    }
  }

  @override
  Future<List<Prediction>> getPredictionsForRoute({
    required List<Location> waypoints,
    required DateTime estimatedArrivalTime,
  }) async {
    try {
      print(
        '[PredictionRepository] 🔮 Obteniendo predicciones para ruta con ${waypoints.length} waypoints',
      );
      print(
        '[PredictionRepository] 📅 Tiempo estimado de llegada: ${estimatedArrivalTime.toIso8601String()}',
      );

      // Filtrar waypoints para no enviar demasiados puntos (máximo 10)
      final filteredWaypoints = _filterWaypointsForPrediction(waypoints);

      final requests =
          filteredWaypoints
              .map(
                (location) => PredictionRequestDto(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  timestamp: estimatedArrivalTime.toIso8601String(),
                ),
              )
              .toList();

      final predictionDtos = await _apiClient
          .getPredictionsForMultipleLocations(requests: requests);

      final predictions =
          predictionDtos.map((dto) => dto.toDomainEntity()).toList();

      print(
        '[PredictionRepository] ✅ Predicciones de ruta obtenidas: ${predictions.length}',
      );

      return predictions;
    } catch (e) {
      print(
        '[PredictionRepository] ❌ Error obteniendo predicciones de ruta: $e',
      );
      throw ServerFailure('Error obteniendo predicciones de ruta: $e');
    }
  }

  /// Filtra waypoints para enviar solo los más relevantes para predicción
  List<Location> _filterWaypointsForPrediction(List<Location> waypoints) {
    if (waypoints.length <= 10) return waypoints;

    // Tomar puntos estratégicos: inicio, fin y puntos intermedios espaciados
    final filtered = <Location>[];
    filtered.add(waypoints.first); // Punto inicial

    // Agregar puntos intermedios espaciados
    final step = (waypoints.length - 2) / 8; // 8 puntos intermedios
    for (int i = 1; i < 9; i++) {
      final index = (step * i).round();
      if (index < waypoints.length - 1) {
        filtered.add(waypoints[index]);
      }
    }

    filtered.add(waypoints.last); // Punto final
    return filtered;
  }
}
