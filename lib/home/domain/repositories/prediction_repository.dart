import 'package:safy/home/domain/entities/prediction.dart';
import 'package:safy/home/domain/entities/location.dart';

abstract class PredictionRepository {
  /// Obtiene predicciones de zonas de peligro para una ubicación y tiempo específicos
  Future<List<Prediction>> getPredictions({
    required Location location,
    required DateTime timestamp,
  });

  /// Obtiene predicciones para múltiples ubicaciones
  Future<List<Prediction>> getPredictionsForMultipleLocations({
    required List<Location> locations,
    required DateTime timestamp,
  });

  /// Obtiene predicciones para una ruta completa
  Future<List<Prediction>> getPredictionsForRoute({
    required List<Location> waypoints,
    required DateTime estimatedArrivalTime,
  });
}
