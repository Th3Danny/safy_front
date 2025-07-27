import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Mixin para seguimiento de navegación y actualización dinámica de rutas
mixin NavigationTrackingMixin on ChangeNotifier {
  // Propiedades de seguimiento de navegación
  List<LatLng> _originalRoute = [];
  List<LatLng> _remainingRoute = [];
  LatLng? _currentPosition;
  bool _isNavigating = false;

  // Distancia de tolerancia para considerar que se pasó un punto (en metros)
  static const double _toleranceDistance = 50.0;

  // Getters
  List<LatLng> get originalRoute => _originalRoute;
  List<LatLng> get remainingRoute => _remainingRoute;
  bool get isNavigating => _isNavigating;

  // Iniciar seguimiento de navegación
  void startNavigationTracking(List<LatLng> route, LatLng startPosition) {
    print(
      '[NavigationTrackingMixin] 🧭 Iniciando seguimiento de navegación...',
    );

    _originalRoute = List.from(route);
    _remainingRoute = List.from(route);
    _currentPosition = startPosition;
    _isNavigating = true;

    // Actualizar la ruta mostrada con la ruta completa inicialmente
    updateRouteDisplay(_remainingRoute);

    notifyListeners();
  }

  // Detener seguimiento de navegación
  void stopNavigationTracking() {
    print(
      '[NavigationTrackingMixin] ⏹️ Deteniendo seguimiento de navegación...',
    );

    _isNavigating = false;
    _originalRoute.clear();
    _remainingRoute.clear();
    _currentPosition = null;

    // Limpiar la ruta mostrada
    updateRouteDisplay([]);

    notifyListeners();
  }

  // Actualizar posición durante navegación
  void updateNavigationPosition(LatLng newPosition) {
    if (!_isNavigating || _remainingRoute.isEmpty) return;

    _currentPosition = newPosition;

    // Verificar si se pasó algún punto de la ruta
    _checkAndUpdateRouteProgress();

    notifyListeners();
  }

  // Verificar progreso en la ruta y actualizar la ruta restante
  void _checkAndUpdateRouteProgress() {
    if (_remainingRoute.length < 2) return;

    final updatedRemainingRoute = <LatLng>[];
    bool routeUpdated = false;

    for (int i = 0; i < _remainingRoute.length; i++) {
      final routePoint = _remainingRoute[i];
      final distanceToPoint = _calculateDistance(_currentPosition!, routePoint);

      // Si estamos muy cerca del punto, considerarlo como "pasado"
      if (distanceToPoint <= _toleranceDistance) {
        print(
          '[NavigationTrackingMixin] ✅ Pasando punto ${i + 1}/${_remainingRoute.length}',
        );
        routeUpdated = true;
        continue; // Saltar este punto
      }

      // Si no hemos pasado este punto, agregarlo a la ruta restante
      updatedRemainingRoute.add(routePoint);
    }

    // Si se actualizó la ruta, actualizar la visualización
    if (routeUpdated) {
      _remainingRoute = updatedRemainingRoute;
      updateRouteDisplay(_remainingRoute);

      print(
        '[NavigationTrackingMixin] 📍 Ruta actualizada: ${_remainingRoute.length} puntos restantes',
      );

      // Verificar si llegamos al destino
      if (_remainingRoute.isEmpty) {
        print('[NavigationTrackingMixin] 🎯 ¡Destino alcanzado!');
        onDestinationReached();
      }
    }
  }

  // Calcular distancia entre dos puntos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Obtener progreso de la navegación (0.0 a 1.0)
  double get navigationProgress {
    if (_originalRoute.isEmpty) return 0.0;

    final totalPoints = _originalRoute.length;
    final remainingPoints = _remainingRoute.length;
    final completedPoints = totalPoints - remainingPoints;

    return completedPoints / totalPoints;
  }

  // Obtener distancia restante
  double get remainingDistance {
    if (_remainingRoute.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < _remainingRoute.length - 1; i++) {
      totalDistance += _calculateDistance(
        _remainingRoute[i],
        _remainingRoute[i + 1],
      );
    }

    return totalDistance;
  }

  // Obtener tiempo estimado restante (en minutos)
  int get estimatedTimeRemaining {
    const double averageSpeed = 5.0; // km/h para caminar
    final distanceKm = remainingDistance / 1000;
    return (distanceKm / averageSpeed * 60).round();
  }

  // Obtener información de progreso
  String get progressInfo {
    final progress = (navigationProgress * 100).toInt();
    final distanceKm = (remainingDistance / 1000).toStringAsFixed(1);
    final timeMinutes = estimatedTimeRemaining;

    return '$progress% completado • $distanceKm km restantes • $timeMinutes min';
  }

  // Callbacks abstractos para implementar en el ViewModel
  void updateRouteDisplay(List<LatLng> route);
  void onDestinationReached();
}
