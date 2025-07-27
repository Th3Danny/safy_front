import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'dart:math' as math;

/// Mixin para gestión de rutas y navegación
mixin RouteMixin on ChangeNotifier {
  // Propiedades de rutas
  LatLng? _startPoint;
  LatLng? get startPoint => _startPoint;

  LatLng? _endPoint;
  LatLng? get endPoint => _endPoint;

  List<LatLng> _currentRoute = [];
  List<LatLng> get currentRoute => _currentRoute;

  String _selectedTransportMode = 'walk';
  String get selectedTransportMode => _selectedTransportMode;

  final List<RouteOption> _routeOptions = [];
  List<RouteOption> get routeOptions => _routeOptions;

  // Dependencias abstractas
  GetOpenRouteUseCase? get getOpenRouteUseCase;

  // Sistema de rutas
  void setStartPoint(LatLng point) {
    _startPoint = point;
    onStartPointChanged(point);
    if (_endPoint != null) {
      calculateRoutes();
    }
    notifyListeners();
  }

  // 🎯 NUEVO: Establecer automáticamente la posición actual como punto de inicio
  void setCurrentLocationAsStart() {
    // Obtener la ubicación actual del LocationMixin
    final currentLocation = (this as dynamic).currentLocation;
    if (currentLocation != null) {
      _startPoint = currentLocation;
      onStartPointChanged(currentLocation);
      if (_endPoint != null) {
        _calculateRoutesAsync();
      }
      notifyListeners();
      print('[RouteMixin] 🎯 Punto de inicio establecido en ubicación actual');
    }
  }

  void clearStartPoint() {
    _startPoint = null;
    onStartPointCleared();
    notifyListeners();
  }

  void clearEndPoint() {
    _endPoint = null;
    onEndPointCleared();
    notifyListeners();
  }

  void setEndPoint(LatLng point) {
    _endPoint = point;
    onEndPointChanged(point);
    if (_startPoint != null) {
      // Llamar calculateRoutes de forma asíncrona para evitar bloqueos
      _calculateRoutesAsync();
    }
    notifyListeners();
  }

  void setTransportMode(String mode) {
    _selectedTransportMode = mode;
    if (_startPoint != null && _endPoint != null) {
      _calculateRoutesAsync();
    }
    notifyListeners();
  }

  // 🚀 NUEVO: Método para calcular rutas de forma asíncrona sin bloquear la UI
  void _calculateRoutesAsync() {
    // Usar Future.microtask para evitar bloqueos en la UI
    Future.microtask(() async {
      try {
        await calculateRoutes();
      } catch (e) {
        print('[RouteMixin] ❌ Error calculando rutas: $e');
        // Crear una ruta simple como fallback
        _createSimpleRoute();
        onRouteError('Error calculando rutas: $e');
      }
    });
  }

  // 🛡️ NUEVO: Método para crear una ruta simple como fallback
  void _createSimpleRoute() {
    if (_startPoint == null || _endPoint == null) return;

    print('[RouteMixin] 🛡️ Creando ruta simple como fallback...');

    final simpleRoute = [_startPoint!, _endPoint!];

    _routeOptions.clear();
    _routeOptions.add(
      RouteOption(
        name: 'Ruta Directa (Fallback)',
        points: simpleRoute,
        distance: _calculateDistance(simpleRoute),
        duration: _calculateDuration(simpleRoute, _selectedTransportMode),
        safetyLevel: 85.0,
        isRecommended: true,
      ),
    );

    selectRoute(_routeOptions.first);
    onRoutesPanelShow();
    notifyListeners();
  }

  // Calcular rutas
  Future<void> calculateRoutes() async {
    if (_startPoint == null || _endPoint == null) {
      print('[RouteMixin] ⚠️ Puntos de inicio o fin no definidos');
      return;
    }

    print('[RouteMixin] 🧭 Iniciando cálculo de rutas...');
    print(
      '[RouteMixin] 📍 Inicio: ${_startPoint!.latitude}, ${_startPoint!.longitude}',
    );
    print(
      '[RouteMixin] 🎯 Fin: ${_endPoint!.latitude}, ${_endPoint!.longitude}',
    );

    try {
      _routeOptions.clear();

      // Solo calcular una ruta directa
      print('[RouteMixin] 🌐 Llamando a OpenRouteService...');
      final realRoute = await _calculateRealRoute(_startPoint!, _endPoint!);
      print('[RouteMixin] ✅ Ruta calculada: ${realRoute.length} puntos');

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Directa',
          points: realRoute,
          distance: _calculateDistance(realRoute),
          duration: _calculateDuration(realRoute, _selectedTransportMode),
          safetyLevel: 85.0,
          isRecommended: true,
        ),
      );

      // Seleccionar la ruta
      selectRoute(_routeOptions.first);
      onRoutesPanelShow();
      print('[RouteMixin] ✅ Rutas calculadas exitosamente');
    } catch (e) {
      print('[RouteMixin] ❌ Error calculando rutas: $e');
      onRouteError('Error calculando rutas: $e');
    }

    notifyListeners();
  }

  Future<List<LatLng>> _calculateRealRoute(LatLng start, LatLng end) async {
    try {
      print('[RouteMixin] 🔍 Verificando GetOpenRouteUseCase...');
      if (getOpenRouteUseCase != null) {
        print('[RouteMixin] ✅ GetOpenRouteUseCase disponible');
        print(
          '[RouteMixin] 📡 Enviando coordenadas: [${start.longitude}, ${start.latitude}] -> [${end.longitude}, ${end.latitude}]',
        );

        // Agregar timeout de 8 segundos para evitar bloqueos
        final coordinates = await getOpenRouteUseCase!
            .call(
              start: [start.longitude, start.latitude],
              end: [end.longitude, end.latitude],
            )
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                print('[RouteMixin] ⏰ Timeout en GetOpenRouteUseCase');
                throw Exception('Timeout: La API no respondió en tiempo');
              },
            );

        print(
          '[RouteMixin] 📊 Coordenadas recibidas: ${coordinates.length} puntos',
        );
        final route =
            coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        print('[RouteMixin] ✅ Ruta convertida: ${route.length} puntos');
        return route;
      } else {
        print(
          '[RouteMixin] ⚠️ GetOpenRouteUseCase no disponible, usando ruta directa',
        );
      }
    } catch (e) {
      print('[RouteMixin] ❌ Error calculating real route: $e');
    }
    print('[RouteMixin] 🔄 Usando ruta directa como fallback');
    return [start, end];
  }

  Future<List<LatLng>> _calculateSafeRouteReal(LatLng start, LatLng end) async {
    // Simplemente devolver la ruta directa
    return await _calculateRealRoute(start, end);
  }

  Future<List<LatLng>> _calculateAlternativeRouteReal(
    LatLng start,
    LatLng end,
  ) async {
    // Simplemente devolver la ruta directa
    return await _calculateRealRoute(start, end);
  }

  // Métodos simplificados - no se usan en la versión básica
  List<LatLng> _findSafeWaypoints(LatLng start, LatLng end) {
    return [];
  }

  LatLng? _findNearestSafePoint(LatLng dangerousPoint) {
    return null;
  }

  LatLng _getPointAtDistance(
    LatLng center,
    double distanceMeters,
    double angleDegrees,
  ) {
    const earthRadius = 6371000;
    final distRad = distanceMeters / earthRadius;
    final bearingRad = angleDegrees * (3.14159 / 180);

    final lat1Rad = center.latitude * (3.14159 / 180);
    final lon1Rad = center.longitude * (3.14159 / 180);

    final lat2Rad = math.asin(
      math.sin(lat1Rad) * math.cos(distRad) +
          math.cos(lat1Rad) * math.sin(distRad) * math.cos(bearingRad),
    );

    final lon2Rad =
        lon1Rad +
        math.atan2(
          math.sin(bearingRad) * math.sin(distRad) * math.cos(lat1Rad),
          math.cos(distRad) - math.sin(lat1Rad) * math.sin(lat2Rad),
        );

    return LatLng(lat2Rad * (180 / 3.14159), lon2Rad * (180 / 3.14159));
  }

  List<LatLng> _getPointsAlongPath(
    LatLng start,
    LatLng end, {
    double intervalMeters = 500,
  }) {
    final points = <LatLng>[];
    final totalDistance = Distance().as(LengthUnit.Meter, start, end);

    if (totalDistance < intervalMeters) {
      return [];
    }

    final numPoints = (totalDistance / intervalMeters).ceil();

    for (int i = 1; i < numPoints; i++) {
      final fraction = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng =
          start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  List<LatLng> _optimizeWaypoints(
    List<LatLng> waypoints,
    LatLng start,
    LatLng end,
  ) {
    if (waypoints.isEmpty) return waypoints;

    final optimized = <LatLng>[];
    const minDistance = 150.0;

    for (final waypoint in waypoints) {
      bool tooClose = false;

      if (Distance().as(LengthUnit.Meter, waypoint, start) < minDistance ||
          Distance().as(LengthUnit.Meter, waypoint, end) < minDistance) {
        continue;
      }

      for (final existing in optimized) {
        if (Distance().as(LengthUnit.Meter, waypoint, existing) < minDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        optimized.add(waypoint);
      }
    }

    optimized.sort((a, b) {
      final distA = Distance().as(LengthUnit.Meter, start, a);
      final distB = Distance().as(LengthUnit.Meter, start, b);
      return distA.compareTo(distB);
    });

    return optimized.take(3).toList();
  }

  double _calculateDistance(List<LatLng> route) {
    double totalDistance = 0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += Distance().as(
        LengthUnit.Kilometer,
        route[i],
        route[i + 1],
      );
    }
    return totalDistance;
  }

  int _calculateDuration(List<LatLng> route, String transportMode) {
    final distance = _calculateDistance(route);
    final speeds = {'walk': 5.0, 'car': 40.0, 'bus': 25.0};
    final speed = speeds[transportMode] ?? 5.0;
    return (distance / speed * 60).round();
  }

  void selectRoute(RouteOption route) {
    _currentRoute = route.points;
    onRouteSelected(route);
    notifyListeners();
  }

  void clearRoute() {
    print('[RouteMixin] 🧹 Limpiando ruta actual...');
    _startPoint = null;
    _endPoint = null;
    _currentRoute.clear();
    _routeOptions.clear();
    onRoutesCleared();
    notifyListeners();
  }

  // 🧹 NUEVO: Método para limpiar rutas sin recursión
  void clearRouteSilently() {
    print('[RouteMixin] 🧹 Limpiando ruta silenciosamente...');
    _startPoint = null;
    _endPoint = null;
    _currentRoute.clear();
    _routeOptions.clear();
    notifyListeners();
  }

  // Callbacks abstractos
  double calculateRouteSafety(List<LatLng> route);
  bool isPointInDangerZone(LatLng point);
  void onStartPointChanged(LatLng point);
  void onEndPointChanged(LatLng point);
  void onStartPointCleared();
  void onEndPointCleared();
  void onRouteSelected(RouteOption route);
  void onRoutesCleared();
  void onRouteError(String error);
  void onRoutesPanelShow();
}

// Clase RouteOption
class RouteOption {
  final String name;
  final List<LatLng> points;
  final double distance;
  final int duration;
  final double safetyLevel;
  final bool isRecommended;

  RouteOption({
    required this.name,
    required this.points,
    required this.distance,
    required this.duration,
    required this.safetyLevel,
    required this.isRecommended,
  });

  Color get safetyColor {
    if (safetyLevel >= 80) return Colors.green;
    if (safetyLevel >= 60) return Colors.orange;
    return Colors.red;
  }

  String get safetyText {
    if (safetyLevel >= 80) return 'Segura';
    if (safetyLevel >= 60) return 'Moderada';
    return 'Peligrosa';
  }
}
