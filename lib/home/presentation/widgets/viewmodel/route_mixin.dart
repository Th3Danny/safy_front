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
      calculateRoutes();
    }
    notifyListeners();
  }

  void setTransportMode(String mode) {
    _selectedTransportMode = mode;
    if (_startPoint != null && _endPoint != null) {
      calculateRoutes();
    }
    notifyListeners();
  }

  // Calcular rutas seguras
  Future<void> calculateRoutes() async {
    if (_startPoint == null || _endPoint == null) return;

    try {
      _routeOptions.clear();

      // Ruta real usando OpenRouteService
      final realRoute = await _calculateRealRoute(_startPoint!, _endPoint!);
      final realSafety = calculateRouteSafety(realRoute);

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Directa',
          points: realRoute,
          distance: _calculateDistance(realRoute),
          duration: _calculateDuration(realRoute, _selectedTransportMode),
          safetyLevel: realSafety,
          isRecommended: realSafety >= 70,
        ),
      );

      // Ruta segura (evita zonas peligrosas)
      final safeRoute = await _calculateSafeRouteReal(_startPoint!, _endPoint!);
      final safeSafety = calculateRouteSafety(safeRoute);

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Segura',
          points: safeRoute,
          distance: _calculateDistance(safeRoute),
          duration: _calculateDuration(safeRoute, _selectedTransportMode),
          safetyLevel: safeSafety,
          isRecommended: true,
        ),
      );

      // Ruta alternativa
      final altRoute = await _calculateAlternativeRouteReal(_startPoint!, _endPoint!);
      final altSafety = calculateRouteSafety(altRoute);

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Alternativa',
          points: altRoute,
          distance: _calculateDistance(altRoute),
          duration: _calculateDuration(altRoute, _selectedTransportMode),
          safetyLevel: altSafety,
          isRecommended: false,
        ),
      );

      // Establecer la ruta recomendada como actual
      final recommendedRoute = _routeOptions.firstWhere(
        (route) => route.isRecommended,
        orElse: () => _routeOptions.first,
      );

      selectRoute(recommendedRoute);
      onRoutesPanelShow();
    } catch (e) {
      onRouteError('Error calculando rutas: $e');
    }

    notifyListeners();
  }

  Future<List<LatLng>> _calculateRealRoute(LatLng start, LatLng end) async {
    try {
      if (getOpenRouteUseCase != null) {
        final coordinates = await getOpenRouteUseCase!.call(
          start: [start.longitude, start.latitude],
          end: [end.longitude, end.latitude],
        );
        return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
      }
    } catch (e) {
      print('Error calculating real route: $e');
    }
    return [start, end];
  }

  Future<List<LatLng>> _calculateSafeRouteReal(LatLng start, LatLng end) async {
    final directRoute = await _calculateRealRoute(start, end);
    final directSafety = calculateRouteSafety(directRoute);

    if (directSafety >= 75) {
      return directRoute;
    }

    final safeWaypoints = _findSafeWaypoints(start, end);
    if (safeWaypoints.isEmpty) {
      return directRoute;
    }

    try {
      final safeRoute = <LatLng>[start];

      if (safeWaypoints.isNotEmpty) {
        final firstSegment = await _calculateRealRoute(start, safeWaypoints.first);
        safeRoute.addAll(firstSegment.skip(1));
      }

      for (int i = 0; i < safeWaypoints.length - 1; i++) {
        final segment = await _calculateRealRoute(safeWaypoints[i], safeWaypoints[i + 1]);
        safeRoute.addAll(segment.skip(1));
      }

      if (safeWaypoints.isNotEmpty) {
        final lastSegment = await _calculateRealRoute(safeWaypoints.last, end);
        safeRoute.addAll(lastSegment.skip(1));
      }

      return safeRoute;
    } catch (e) {
      return directRoute;
    }
  }

  Future<List<LatLng>> _calculateAlternativeRouteReal(LatLng start, LatLng end) async {
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final altPoint = LatLng(midLat - 0.001, midLng + 0.003);

    try {
      final firstSegment = await _calculateRealRoute(start, altPoint);
      final secondSegment = await _calculateRealRoute(altPoint, end);
      return [...firstSegment, ...secondSegment.skip(1)];
    } catch (e) {
      return await _calculateRealRoute(start, end);
    }
  }

  List<LatLng> _findSafeWaypoints(LatLng start, LatLng end) {
    final waypoints = <LatLng>[];
    final checkPoints = _getPointsAlongPath(start, end, intervalMeters: 300);

    for (final point in checkPoints) {
      if (isPointInDangerZone(point)) {
        final safePoint = _findNearestSafePoint(point);
        if (safePoint != null && !waypoints.contains(safePoint)) {
          waypoints.add(safePoint);
        }
      }
    }

    return _optimizeWaypoints(waypoints, start, end);
  }

  LatLng? _findNearestSafePoint(LatLng dangerousPoint) {
    const maxSearchRadius = 800;
    const searchStep = 100;
    const angleStep = 30;

    for (int radius = searchStep; radius <= maxSearchRadius; radius += searchStep) {
      for (int angle = 0; angle < 360; angle += angleStep) {
        final candidate = _getPointAtDistance(dangerousPoint, radius.toDouble(), angle.toDouble());
        if (!isPointInDangerZone(candidate)) {
          return candidate;
        }
      }
    }
    return null;
  }

  LatLng _getPointAtDistance(LatLng center, double distanceMeters, double angleDegrees) {
    const earthRadius = 6371000;
    final distRad = distanceMeters / earthRadius;
    final bearingRad = angleDegrees * (3.14159 / 180);

    final lat1Rad = center.latitude * (3.14159 / 180);
    final lon1Rad = center.longitude * (3.14159 / 180);

    final lat2Rad = math.asin(
      math.sin(lat1Rad) * math.cos(distRad) +
          math.cos(lat1Rad) * math.sin(distRad) * math.cos(bearingRad),
    );

    final lon2Rad = lon1Rad +
        math.atan2(
          math.sin(bearingRad) * math.sin(distRad) * math.cos(lat1Rad),
          math.cos(distRad) - math.sin(lat1Rad) * math.sin(lat2Rad),
        );

    return LatLng(lat2Rad * (180 / 3.14159), lon2Rad * (180 / 3.14159));
  }

  List<LatLng> _getPointsAlongPath(LatLng start, LatLng end, {double intervalMeters = 500}) {
    final points = <LatLng>[];
    final totalDistance = Distance().as(LengthUnit.Meter, start, end);

    if (totalDistance < intervalMeters) {
      return [];
    }

    final numPoints = (totalDistance / intervalMeters).ceil();

    for (int i = 1; i < numPoints; i++) {
      final fraction = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  List<LatLng> _optimizeWaypoints(List<LatLng> waypoints, LatLng start, LatLng end) {
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
      totalDistance += Distance().as(LengthUnit.Kilometer, route[i], route[i + 1]);
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
    _startPoint = null;
    _endPoint = null;
    _currentRoute.clear();
    _routeOptions.clear();
    onRoutesCleared();
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