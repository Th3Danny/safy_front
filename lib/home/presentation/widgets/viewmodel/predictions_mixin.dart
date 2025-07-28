import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/prediction.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/usecases/get_predictions_use_case.dart';

/// Mixin para gestión de predicciones de zonas de peligro
mixin PredictionsMixin on ChangeNotifier {
  // Propiedades de predicciones
  final List<Marker> _predictionMarkers = [];
  List<Marker> get predictionMarkers => _predictionMarkers;

  bool _showPredictions = false;
  bool get showPredictions => _showPredictions;

  List<Prediction> _predictions = [];
  List<Prediction> get predictions => _predictions;

  bool _predictionsLoading = false;
  bool get predictionsLoading => _predictionsLoading;

  String? _predictionsError;
  String? get predictionsError => _predictionsError;

  Prediction? _selectedPrediction;
  Prediction? get selectedPrediction => _selectedPrediction;

  // Dependencia del caso de uso - debe ser implementado por el ViewModel
  GetPredictionsUseCase? get getPredictionsUseCase;

  // Cargar predicciones para una ubicación específica
  Future<void> loadPredictions({
    required LatLng location,
    required DateTime timestamp,
  }) async {
    if (_predictionsLoading) return;

    _predictionsLoading = true;
    _predictionsError = null;
    notifyListeners();

    try {
      print(
        '[PredictionsMixin] 🔮 Cargando predicciones para: ${location.latitude}, ${location.longitude}',
      );
      print('[PredictionsMixin] 📅 Timestamp: ${timestamp.toIso8601String()}');

      if (getPredictionsUseCase != null) {
        final locationEntity = Location(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: timestamp,
        );

        _predictions = await getPredictionsUseCase!.execute(
          location: locationEntity,
          timestamp: timestamp,
        );

        print(
          '[PredictionsMixin] ✅ Predicciones cargadas: ${_predictions.length}',
        );
        _createPredictionMarkers();
      } else {
        print('[PredictionsMixin] ⚠️ GetPredictionsUseCase no disponible');
        _predictionsError = 'Servicio de predicciones no disponible';
      }
    } catch (e) {
      print('[PredictionsMixin] ❌ Error cargando predicciones: $e');
      _predictionsError = 'Error cargando predicciones: $e';
    } finally {
      _predictionsLoading = false;
      notifyListeners();
    }
  }

  // Cargar predicciones para una ruta
  Future<void> loadPredictionsForRoute({
    required List<LatLng> waypoints,
    required DateTime estimatedArrivalTime,
  }) async {
    if (_predictionsLoading) return;

    _predictionsLoading = true;
    _predictionsError = null;
    notifyListeners();

    try {
      print(
        '[PredictionsMixin] 🔮 Cargando predicciones para ruta con ${waypoints.length} waypoints',
      );
      print(
        '[PredictionsMixin] 📅 Tiempo estimado de llegada: ${estimatedArrivalTime.toIso8601String()}',
      );

      if (getPredictionsUseCase != null) {
        final locationEntities =
            waypoints
                .map(
                  (point) => Location(
                    latitude: point.latitude,
                    longitude: point.longitude,
                    timestamp: estimatedArrivalTime,
                  ),
                )
                .toList();

        _predictions = await getPredictionsUseCase!.executeForRoute(
          waypoints: locationEntities,
          estimatedArrivalTime: estimatedArrivalTime,
        );

        print(
          '[PredictionsMixin] ✅ Predicciones de ruta cargadas: ${_predictions.length}',
        );
        _createPredictionMarkers();
      } else {
        print('[PredictionsMixin] ⚠️ GetPredictionsUseCase no disponible');
        _predictionsError = 'Servicio de predicciones no disponible';
      }
    } catch (e) {
      print('[PredictionsMixin] ❌ Error cargando predicciones de ruta: $e');
      _predictionsError = 'Error cargando predicciones de ruta: $e';
    } finally {
      _predictionsLoading = false;
      notifyListeners();
    }
  }

  // Crear marcadores para las predicciones
  void _createPredictionMarkers() {
    _predictionMarkers.clear();

    for (final prediction in _predictions) {
      final marker = Marker(
        point: LatLng(
          prediction.location.latitude,
          prediction.location.longitude,
        ),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _onPredictionSelected(prediction),
          child: Container(
            decoration: BoxDecoration(
              color: _getRiskColor(
                prediction.riskLevel,
              ), // 🎨 Color dinámico por severidad
              shape: BoxShape.circle,
              border: Border.all(
                color: _getBorderColor(prediction.riskLevel),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getRiskColor(prediction.riskLevel).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _getRiskIcon(prediction.riskLevel), // 🔮 Icono dinámico
              color: _getIconColor(prediction.riskLevel),
              size: 25,
            ),
          ),
        ),
      );

      _predictionMarkers.add(marker);
    }

    print(
      '[PredictionsMixin] 📍 Marcadores de predicciones creados: ${_predictionMarkers.length}',
    );
  }

  // Manejar selección de predicción
  void _onPredictionSelected(Prediction prediction) {
    _selectedPrediction = prediction;
    notifyListeners();
    print(
      '[PredictionsMixin] 🔮 Predicción seleccionada: ${prediction.riskLevel}',
    );
  }

  // Ocultar predicción seleccionada
  void hideSelectedPrediction() {
    _selectedPrediction = null;
    notifyListeners();
  }

  // Alternar visibilidad de predicciones
  void togglePredictions() {
    _showPredictions = !_showPredictions;
    notifyListeners();
    print(
      '[PredictionsMixin] 👁️ Predicciones ${_showPredictions ? 'mostradas' : 'ocultadas'}',
    );
  }

  // 🆕 NUEVO: Cargar predicciones automáticamente cuando se establece una ruta
  Future<void> loadPredictionsForRouteAutomatically(
    List<LatLng> routePoints,
  ) async {
    if (routePoints.isEmpty) return;

    print(
      '[PredictionsMixin] 🔮 Cargando predicciones automáticamente para ruta con ${routePoints.length} puntos',
    );

    try {
      // Tomar puntos estratégicos de la ruta (inicio, medio, fin)
      final strategicPoints = <LatLng>[];
      strategicPoints.add(routePoints.first); // Punto inicial

      if (routePoints.length > 2) {
        strategicPoints.add(
          routePoints[routePoints.length ~/ 2],
        ); // Punto medio
      }

      strategicPoints.add(routePoints.last); // Punto final

      // Convertir a entidades de Location
      final locationEntities =
          strategicPoints
              .map(
                (point) => Location(
                  latitude: point.latitude,
                  longitude: point.longitude,
                  timestamp: DateTime.now().add(
                    const Duration(hours: 2),
                  ), // 2 horas en el futuro
                ),
              )
              .toList();

      // Obtener predicciones para estos puntos
      if (getPredictionsUseCase != null) {
        _predictions = await getPredictionsUseCase!.executeForMultipleLocations(
          locations: locationEntities,
          timestamp: DateTime.now().add(const Duration(hours: 2)),
        );

        print(
          '[PredictionsMixin] ✅ Predicciones automáticas cargadas: ${_predictions.length}',
        );
        _createPredictionMarkers();

        // Mostrar predicciones automáticamente
        _showPredictions = true;
        notifyListeners();
      }
    } catch (e) {
      print('[PredictionsMixin] ❌ Error cargando predicciones automáticas: $e');
    }
  }

  // 🆕 NUEVO: Cargar predicciones para un destino específico
  Future<void> loadPredictionsForDestination(LatLng destination) async {
    print(
      '[PredictionsMixin] 🔮 Cargando predicciones para destino: ${destination.latitude}, ${destination.longitude}',
    );

    try {
      final location = Location(
        latitude: destination.latitude,
        longitude: destination.longitude,
        timestamp: DateTime.now().add(const Duration(hours: 2)),
      );

      if (getPredictionsUseCase != null) {
        _predictions = await getPredictionsUseCase!.execute(
          location: location,
          timestamp: DateTime.now().add(const Duration(hours: 2)),
        );

        print(
          '[PredictionsMixin] ✅ Predicciones para destino cargadas: ${_predictions.length}',
        );
        _createPredictionMarkers();

        // Mostrar predicciones automáticamente
        _showPredictions = true;
        notifyListeners();
      }
    } catch (e) {
      print(
        '[PredictionsMixin] ❌ Error cargando predicciones para destino: $e',
      );
    }
  }

  // Obtener predicciones críticas (alto riesgo y alta confiabilidad)
  List<Prediction> get criticalPredictions {
    return _predictions
        .where((prediction) => prediction.isHighRisk && prediction.isReliable)
        .toList();
  }

  // Obtener predicciones por nivel de riesgo
  List<Prediction> getPredictionsByRiskLevel(String riskLevel) {
    return _predictions
        .where(
          (prediction) =>
              prediction.riskLevel.toUpperCase() == riskLevel.toUpperCase(),
        )
        .toList();
  }

  // Obtener predicciones por confiabilidad mínima
  List<Prediction> getPredictionsByConfidence(double minConfidence) {
    return _predictions
        .where((prediction) => prediction.confidenceScore >= minConfidence)
        .toList();
  }

  // Limpiar predicciones
  void clearPredictions() {
    _predictions.clear();
    _predictionMarkers.clear();
    _selectedPrediction = null;
    _predictionsError = null;
    notifyListeners();
  }

  // Obtener color según nivel de riesgo
  Color _getRiskColor(String riskLevel) {
    // 🎨 COLORES POR SEVERIDAD PARA PREDICCIONES
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green.withOpacity(0.8); // 🟢 Verde para bajo riesgo
      case 'MEDIUM':
        return Colors.yellow.withOpacity(0.8); // 🟡 Amarillo para riesgo medio
      case 'HIGH':
        return Colors.orange.withOpacity(0.8); // 🟠 Naranja para alto riesgo
      case 'CRITICAL':
        return Colors.red.withOpacity(0.8); // 🔴 Rojo para riesgo crítico
      default:
        return Colors.grey.withOpacity(0.8); // ⚪ Gris para desconocido
    }
  }

  // Obtener icono según nivel de riesgo
  IconData _getRiskIcon(String riskLevel) {
    // 🔮 ICONOS POR SEVERIDAD PARA PREDICCIONES
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Icons.psychology; // 🔮 Psicología para bajo riesgo
      case 'MEDIUM':
        return Icons.psychology; // 🔮 Psicología para riesgo medio
      case 'HIGH':
        return Icons.psychology; // 🔮 Psicología para alto riesgo
      case 'CRITICAL':
        return Icons.psychology; // 🔮 Psicología para riesgo crítico
      default:
        return Icons.psychology; // 🔮 Psicología por defecto
    }
  }

  // Obtener color de borde según nivel de riesgo
  Color _getBorderColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green[700]!; // Verde oscuro
      case 'MEDIUM':
        return Colors.orange[700]!; // Naranja oscuro
      case 'HIGH':
        return Colors.red[700]!; // Rojo oscuro
      case 'CRITICAL':
        return Colors.purple[700]!; // Púrpura oscuro
      default:
        return Colors.grey[700]!; // Gris oscuro
    }
  }

  // Obtener color de icono según nivel de riesgo
  Color _getIconColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green[800]!; // Verde muy oscuro
      case 'MEDIUM':
        return Colors.orange[800]!; // Naranja muy oscuro
      case 'HIGH':
        return Colors.red[800]!; // Rojo muy oscuro
      case 'CRITICAL':
        return Colors.purple[800]!; // Púrpura muy oscuro
      default:
        return Colors.grey[800]!; // Gris muy oscuro
    }
  }

  // Callbacks abstractos
  void onPredictionSelected(Prediction prediction);
  void onPredictionsToggled(bool visible);
}
