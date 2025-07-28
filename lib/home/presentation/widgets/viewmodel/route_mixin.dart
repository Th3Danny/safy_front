import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/home/data/datasources/mapbox_directions_client.dart';
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

  // Dependencias abstractas (ahora usando Mapbox directamente)

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

    // 🆕 NUEVO: Cargar predicciones automáticamente cuando se establece un destino
    if (this is MapViewModel) {
      final mapViewModel = this as MapViewModel;
      print(
        '[RouteMixin] 🔮 Cargando predicciones para destino establecido: ${point.latitude}, ${point.longitude}',
      );
      mapViewModel.loadPredictionsForDestination(point);
    }

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
        // Crear una ruta simple como fallback
        _createSimpleRoute();
        onRouteError('Error calculando rutas: $e');
      }
    });
  }

  // 🛡️ NUEVO: Método para crear una ruta simple como fallback
  void _createSimpleRoute() {
    if (_startPoint == null || _endPoint == null) return;

    final simpleRoute = [_startPoint!, _endPoint!];
    final safetyLevel = _calculateRouteSafety(simpleRoute);

    _routeOptions.clear();
    _routeOptions.add(
      RouteOption(
        name: 'Ruta Directa (Fallback)',
        points: simpleRoute,
        distance: _calculateDistance(simpleRoute),
        duration: _calculateDuration(simpleRoute, _selectedTransportMode),
        safetyLevel: safetyLevel,
        isRecommended: safetyLevel >= 70.0,
      ),
    );

    selectRoute(_routeOptions.first);
    onRoutesPanelShow();
    notifyListeners();
  }

  // Calcular rutas
  Future<void> calculateRoutes() async {
    if (_startPoint == null || _endPoint == null) {
      return;
    }

    try {
      _routeOptions.clear();

      // 🛡️ NUEVO: Calcular múltiples rutas con diferentes niveles de seguridad
      final routes = await _calculateMultipleRoutes(_startPoint!, _endPoint!);

      print('✅ Calculadas ${routes.length} rutas');

      // Agregar rutas calculadas
      for (final route in routes) {
        _routeOptions.add(route);
      }

      // Seleccionar la ruta más segura por defecto
      if (_routeOptions.isNotEmpty) {
        final recommendedRoute = _routeOptions.reduce(
          (a, b) => a.safetyLevel > b.safetyLevel ? a : b,
        );
        selectRoute(recommendedRoute);
      }

      onRoutesPanelShow();
    } catch (e) {
      onRouteError('Error calculando rutas: $e');
    }

    notifyListeners();
  }

  // 🛡️ NUEVO: Calcular múltiples rutas con diferentes niveles de seguridad
  Future<List<RouteOption>> _calculateMultipleRoutes(
    LatLng start,
    LatLng end,
  ) async {
    final routes = <RouteOption>[];

    try {
      // 🚨 NUEVO: Verificar si hay zonas peligrosas primero
      final dangerZones = _getNearbyDangerZones(start, end);

      if (dangerZones.isEmpty) {
        // Solo calcular ruta directa si NO hay zonas peligrosas
        final directRoute = await _calculateRealRoute(start, end);
        final directSafety = _calculateRouteSafety(directRoute);

        routes.add(
          RouteOption(
            name: 'Ruta Directa',
            points: directRoute,
            distance: _calculateDistance(directRoute),
            duration: _calculateDuration(directRoute, _selectedTransportMode),
            safetyLevel: directSafety,
            isRecommended: directSafety >= 70.0,
          ),
        );
      } else {
        // 🛡️ NO calcular ruta directa si hay zonas peligrosas

        final safeRoute = await _calculateSafeRoute(start, end);
        if (safeRoute != null) {
          final safeSafety = _calculateRouteSafety(safeRoute);

          routes.add(
            RouteOption(
              name: 'Ruta Segura',
              points: safeRoute,
              distance: _calculateDistance(safeRoute),
              duration: _calculateDuration(safeRoute, _selectedTransportMode),
              safetyLevel: safeSafety,
              isRecommended: safeSafety >= 80.0,
            ),
          );
        } else {}
      }

      // 3. Ruta alternativa (solo si hay rutas seguras y es necesario)
      if (routes.isNotEmpty && dangerZones.isNotEmpty) {
        final alternativeRoute = await _calculateAlternativeRoute(start, end);
        if (alternativeRoute != null) {
          final altSafety = _calculateRouteSafety(alternativeRoute);

          routes.add(
            RouteOption(
              name: 'Ruta Alternativa',
              points: alternativeRoute,
              distance: _calculateDistance(alternativeRoute),
              duration: _calculateDuration(
                alternativeRoute,
                _selectedTransportMode,
              ),
              safetyLevel: altSafety,
              isRecommended: altSafety >= 75.0,
            ),
          );
        }
      }
    } catch (e) {
      // Fallback: ruta directa simple
      routes.add(
        RouteOption(
          name: 'Ruta Directa (Fallback)',
          points: [start, end],
          distance: _calculateDistance([start, end]),
          duration: _calculateDuration([start, end], _selectedTransportMode),
          safetyLevel: 60.0,
          isRecommended: true,
        ),
      );
    }

    return routes;
  }

  Future<List<LatLng>> _calculateRealRoute(LatLng start, LatLng end) async {
    try {
      final directionsClient = MapboxDirectionsClient();
      final coordinates = await directionsClient.getRoute(
        start: start,
        end: end,
        profile: 'walking',
      );

      if (coordinates.isNotEmpty) {
        final route =
            coordinates.map((coord) => LatLng(coord[0], coord[1])).toList();
        return route;
      }
    } catch (e) {
      // Error en cálculo de ruta
    }
    return [start, end];
  }

  // 🛡️ NUEVO: Calcular ruta segura que evita zonas peligrosas
  Future<List<LatLng>?> _calculateSafeRoute(LatLng start, LatLng end) async {
    try {
      // Obtener zonas peligrosas cercanas
      final dangerZones = _getNearbyDangerZones(start, end);

      if (dangerZones.isEmpty) {
        return await _calculateRealRoute(start, end);
      }

      // 🚨 Verificar si la ruta directa pasa por zonas peligrosas
      final directRoute = await _calculateRealRoute(start, end);
      bool directRouteIsSafe = true;
      int dangerousPoints = 0;

      // Verificar cada punto de la ruta directa
      for (final point in directRoute) {
        if (isPointInDangerZone(point)) {
          dangerousPoints++;
          directRouteIsSafe = false;
        }
      }

      // Si la ruta directa es segura, usarla
      if (directRouteIsSafe) {
        return directRoute;
      }

      // 🛡️ Si no es segura, calcular ruta que evite zonas peligrosas
      final safeRoute = await _calculateRouteAvoidingDangerZones(
        start,
        end,
        dangerZones,
      );

      if (safeRoute != null) {
        // Verificar que la ruta segura realmente sea segura
        int safeRouteDangerousPoints = 0;
        for (final point in safeRoute) {
          if (isPointInDangerZone(point)) {
            safeRouteDangerousPoints++;
          }
        }

        if (safeRouteDangerousPoints == 0) {
          return safeRoute;
        } else {
          print(
            '[RouteMixin] ⚠️ Ruta segura aún tiene $safeRouteDangerousPoints puntos peligrosos',
          );
        }
      }

      //  Si no se pudo calcular ruta segura, usar ruta con waypoints seguros

      final waypointRoute = await _calculateRouteWithSafeWaypoints(
        start,
        end,
        dangerZones,
      );

      if (waypointRoute != null) {
        print(
          '[RouteMixin]  Ruta con waypoints creada con ${waypointRoute.length} puntos',
        );
        return waypointRoute;
      }

      print(
        '[RouteMixin]  No se pudo crear ruta segura, usando ruta directa como fallback',
      );
      return directRoute;
    } catch (e) {
      print('[RouteMixin]  Error en cálculo de ruta segura: $e');
      return null;
    }
  }

  // 🛡️ NUEVO: Calcular ruta alternativa usando API real
  Future<List<LatLng>?> _calculateAlternativeRoute(
    LatLng start,
    LatLng end,
  ) async {
    try {
      print('[RouteMixin] 🔄 Calculando ruta alternativa...');

      // Obtener zonas peligrosas para evitar
      final dangerZones = _getNearbyDangerZones(start, end);

      if (dangerZones.isEmpty) {
        return await _calculateRealRoute(start, end);
      }

      // Encontrar punto seguro alejado para desvío
      final midPoint = LatLng(
        (start.latitude + end.latitude) / 2,
        (start.longitude + end.longitude) / 2,
      );

      final safeDetourPoint = _findSafePointAwayFromDangerZones(
        midPoint,
        dangerZones,
      );

      if (safeDetourPoint != null) {
        print(
          '[RouteMixin]  Punto de desvío seguro encontrado: ${safeDetourPoint.latitude}, ${safeDetourPoint.longitude}',
        );

        // Calcular ruta por segmentos usando API real
        final route = <LatLng>[];

        try {
          final directionsClient = MapboxDirectionsClient();

          // Segmento 1: start -> detourPoint
          final segment1Coordinates = await directionsClient.getRoute(
            start: start,
            end: safeDetourPoint,
            profile: 'walking',
          );

          final segment1Route =
              segment1Coordinates
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList();

          route.addAll(segment1Route);

          // Segmento 2: detourPoint -> end
          final segment2Coordinates = await directionsClient.getRoute(
            start: safeDetourPoint,
            end: end,
            profile: 'walking',
          );

          final segment2Route =
              segment2Coordinates
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList();

          // Agregar segmento 2 (excluyendo el primer punto para evitar duplicados)
          route.addAll(segment2Route.skip(1));

          print(
            '[RouteMixin]  Ruta alternativa calculada con ${route.length} puntos usando API real',
          );

          // Verificar que la ruta sea segura
          int dangerousPoints = 0;
          for (final point in route) {
            if (isPointInDangerZone(point)) {
              dangerousPoints++;
            }
          }

          if (dangerousPoints == 0) {
            print('[RouteMixin]  Ruta alternativa es segura');
            return route;
          } else {
            print('[RouteMixin]  Ruta alternativa aún tiene puntos peligrosos');
            return null;
          }
        } catch (e) {
          print('[RouteMixin] Error calculando ruta alternativa con API: $e');
          return null;
        }
      } else {
        print('[RouteMixin]  No se pudo encontrar punto de desvío seguro');
        return null;
      }
    } catch (e) {
      print('[RouteMixin]  Error en cálculo de ruta alternativa: $e');
      return null;
    }
  }

  // 🛡️ NUEVO: Calcular seguridad de una ruta
  double _calculateRouteSafety(List<LatLng> route) {
    if (route.isEmpty) return 100.0;

    double safetyScore = 100.0;
    int dangerousPoints = 0;
    int totalPoints = 0;

    // Verificar cada punto de la ruta contra zonas peligrosas
    for (final point in route) {
      totalPoints++;
      if (isPointInDangerZone(point)) {
        dangerousPoints++;
        safetyScore -= 15.0; // Penalización por punto peligroso
      }
    }

    // Penalización adicional por densidad de puntos peligrosos
    if (totalPoints > 0) {
      final dangerPercentage = dangerousPoints / totalPoints;
      if (dangerPercentage > 0.5) {
        safetyScore -= 30.0; // Muchos puntos peligrosos
      } else if (dangerPercentage > 0.2) {
        safetyScore -= 15.0; // Algunos puntos peligrosos
      }
    }

    // Factor de hora del día
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 6) {
      safetyScore -= 10.0; // Noche: más peligroso
    }

    return safetyScore.clamp(0.0, 100.0);
  }

  // 🛡️ NUEVO: Obtener zonas peligrosas cercanas
  List<LatLng> _getNearbyDangerZones(LatLng start, LatLng end) {
    try {
      // Intentar obtener zonas peligrosas del MapViewModel
      final mapViewModel = GetIt.instance<MapViewModel>();
      final clusters = mapViewModel.clusters;

      if (clusters.isNotEmpty) {
        // Filtrar solo clusters con severidad alta
        final dangerousClusters =
            clusters.where((cluster) {
              final severity = cluster.severityNumber ?? 1;
              return severity >= 3; // Solo clusters con severidad 3 o mayor
            }).toList();

        return dangerousClusters
            .map(
              (cluster) =>
                  LatLng(cluster.centerLatitude, cluster.centerLongitude),
            )
            .toList();
      } else {
        print('[RouteMixin] ⚠️ No se encontraron clusters de peligro');
      }
    } catch (e) {
      print('[RouteMixin] ❌ Error obteniendo clusters: $e');
    }

    // Datos ficticios como fallback para testing
    print('[RouteMixin] 🔄 Usando zonas peligrosas de prueba');
    return [
      LatLng(16.7569, -93.1292), // Ejemplo de zona peligrosa
      LatLng(16.7570, -93.1293), // Ejemplo de zona peligrosa
    ];
  }

  // 🛡️ NUEVO: Calcular ruta que evita zonas peligrosas
  Future<List<LatLng>?> _calculateRouteAvoidingDangerZones(
    LatLng start,
    LatLng end,
    List<LatLng> dangerZones,
  ) async {
    try {
      print('[RouteMixin] 🛡️ Calculando ruta que evita zonas peligrosas...');

      // 1. Encontrar waypoints seguros
      final safeWaypoints = _findSafeWaypoints(start, end, dangerZones);
      print(
        '[RouteMixin] 📍 Waypoints seguros encontrados: ${safeWaypoints.length}',
      );

      if (safeWaypoints.isEmpty) {
        print(
          '[RouteMixin] ⚠️ No hay waypoints seguros, intentando desvío amplio...',
        );
        // Si no hay waypoints seguros, intentar con desvíos más amplios
        return await _calculateDetourRoute(start, end, dangerZones);
      }

      // 2. Construir ruta con waypoints seguros
      final route = <LatLng>[start];
      route.addAll(safeWaypoints);
      route.add(end);

      print('[RouteMixin] 📊 Ruta construida con ${route.length} puntos');

      // 3. Verificar que la ruta final sea segura
      int dangerousPoints = 0;
      for (final point in route) {
        if (isPointInDangerZone(point)) {
          dangerousPoints++;
        }
      }

      print(
        '[RouteMixin] 📊 Puntos peligrosos en ruta con waypoints: $dangerousPoints',
      );

      if (dangerousPoints == 0) {
        print('[RouteMixin] ✅ Ruta con waypoints es segura');
        return route;
      }

      print(
        '[RouteMixin] ⚠️ Ruta con waypoints aún tiene puntos peligrosos, intentando desvío amplio...',
      );

      // 4. Si aún no es segura, usar desvío más amplio
      return await _calculateDetourRoute(start, end, dangerZones);
    } catch (e) {
      print('[RouteMixin] ❌ Error calculando ruta que evita zonas: $e');
      return null;
    }
  }

  // 🛡️ NUEVO: Calcular ruta con desvío amplio
  Future<List<LatLng>?> _calculateDetourRoute(
    LatLng start,
    LatLng end,
    List<LatLng> dangerZones,
  ) async {
    try {
      // Calcular punto medio
      final midPoint = LatLng(
        (start.latitude + end.latitude) / 2,
        (start.longitude + end.longitude) / 2,
      );

      // Encontrar punto seguro alejado de zonas peligrosas
      final safeMidPoint = _findSafePointAwayFromDangerZones(
        midPoint,
        dangerZones,
      );

      if (safeMidPoint != null) {
        // Construir ruta con desvío: start -> safeMidPoint -> end
        final route = <LatLng>[start, safeMidPoint, end];

        // Verificar que la ruta sea segura
        bool routeIsSafe = true;
        for (final point in route) {
          if (isPointInDangerZone(point)) {
            routeIsSafe = false;
            break;
          }
        }

        if (routeIsSafe) {
          return route;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 🛡️ NUEVO: Calcular ruta con waypoints seguros usando API real
  Future<List<LatLng>?> _calculateRouteWithSafeWaypoints(
    LatLng start,
    LatLng end,
    List<LatLng> dangerZones,
  ) async {
    try {
      print('[RouteMixin] 🛡️ Calculando ruta con waypoints seguros...');

      // Encontrar waypoints seguros
      final safeWaypoints = _findSafeWaypoints(start, end, dangerZones);
      print(
        '[RouteMixin] 📍 Waypoints seguros encontrados: ${safeWaypoints.length}',
      );

      if (safeWaypoints.isEmpty) {
        print('[RouteMixin] ⚠️ No se encontraron waypoints seguros');
        return null;
      }

      // Usar la API de Mapbox con waypoints
      final directionsClient = MapboxDirectionsClient();

      // Calcular ruta por segmentos usando la API
      final route = <LatLng>[];

      // Agregar punto de inicio
      route.add(start);

      // Calcular rutas entre waypoints
      for (int i = 0; i < safeWaypoints.length; i++) {
        final segmentStart = i == 0 ? start : safeWaypoints[i - 1];
        final segmentEnd = safeWaypoints[i];

        try {
          final segmentCoordinates = await directionsClient.getRoute(
            start: segmentStart,
            end: segmentEnd,
            profile: 'walking',
          );

          final segmentRoute =
              segmentCoordinates
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList();

          // Agregar puntos del segmento (excluyendo el primer punto para evitar duplicados)
          route.addAll(segmentRoute.skip(1));
        } catch (e) {
          // Fallback: línea recta entre puntos
          route.add(segmentEnd);
        }
      }

      // Calcular último segmento hasta el final
      if (safeWaypoints.isNotEmpty) {
        final lastWaypoint = safeWaypoints.last;
        try {
          final finalSegmentCoordinates = await directionsClient.getRoute(
            start: lastWaypoint,
            end: end,
            profile: 'walking',
          );

          final finalSegmentRoute =
              finalSegmentCoordinates
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList();

          // Agregar puntos del segmento final (excluyendo el primer punto)
          route.addAll(finalSegmentRoute.skip(1));
        } catch (e) {
          route.add(end);
        }
      } else {
        // Si no hay waypoints, calcular ruta directa
        try {
          final directCoordinates = await directionsClient.getRoute(
            start: start,
            end: end,
            profile: 'walking',
          );

          final directRoute =
              directCoordinates
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList();

          route.clear();
          route.addAll(directRoute);
        } catch (e) {
          route.clear();
          route.addAll([start, end]);
        }
      }

      print(' Ruta con waypoints calculada: ${route.length} puntos');

      // Verificar que la ruta sea segura
      int dangerousPoints = 0;
      for (final point in route) {
        if (isPointInDangerZone(point)) {
          dangerousPoints++;
        }
      }

      if (dangerousPoints == 0) {
        return route;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 🛡️ NUEVO: Encontrar punto seguro alejado de zonas peligrosas
  LatLng? _findSafePointAwayFromDangerZones(
    LatLng center,
    List<LatLng> dangerZones,
  ) {
    const maxAttempts = 8;
    const baseDistance = 500.0; // 500m de distancia base

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final angle = (attempt * 45.0) * (3.14159 / 180); // 45 grados por intento
      final distance =
          baseDistance + (attempt * 100.0); // Aumentar distancia cada intento

      final safePoint = _getPointAtDistance(
        center,
        distance,
        angle * (180 / 3.14159),
      );

      // Verificar si el punto está lejos de todas las zonas peligrosas
      bool isSafe = true;
      for (final dangerZone in dangerZones) {
        final distToDanger = Distance().as(
          LengthUnit.Meter,
          safePoint,
          dangerZone,
        );
        if (distToDanger < 300) {
          // Mínimo 300m de distancia
          isSafe = false;
          break;
        }
      }

      if (isSafe) {
        return safePoint;
      }
    }

    return null;
  }

  // 🛡️ NUEVO: Encontrar waypoints seguros
  List<LatLng> _findSafeWaypoints(
    LatLng start,
    LatLng end,
    List<LatLng> dangerZones,
  ) {
    final waypoints = <LatLng>[];

    // Calcular puntos intermedios cada 300m (más frecuente para mejor cobertura)
    final totalDistance = Distance().as(LengthUnit.Meter, start, end);
    final numPoints = (totalDistance / 300).ceil();

    print(
      '[RouteMixin] 🔍 Buscando waypoints seguros en $numPoints puntos intermedios...',
    );

    for (int i = 1; i < numPoints; i++) {
      final ratio = i / numPoints;
      final midPoint = LatLng(
        start.latitude + (end.latitude - start.latitude) * ratio,
        start.longitude + (end.longitude - start.longitude) * ratio,
      );

      // Verificar si el punto está en zona peligrosa
      bool isSafe = true;
      double minDistanceToDanger = double.infinity;

      for (final dangerZone in dangerZones) {
        final distance = Distance().as(LengthUnit.Meter, midPoint, dangerZone);
        if (distance < 300) {
          // Aumentar radio de seguridad a 300m
          isSafe = false;
          minDistanceToDanger = distance;
          break;
        }
        if (distance < minDistanceToDanger) {
          minDistanceToDanger = distance;
        }
      }

      if (isSafe) {
        waypoints.add(midPoint);
        print(
          '[RouteMixin] ✅ Waypoint seguro encontrado: ${midPoint.latitude}, ${midPoint.longitude}',
        );
      } else {
        print(
          '[RouteMixin] ⚠️ Waypoint peligroso: ${midPoint.latitude}, ${midPoint.longitude} - Distancia mínima: ${minDistanceToDanger.toInt()}m',
        );

        // Intentar encontrar punto seguro cercano
        final safePoint = _findSafePointAwayFromDangerZones(
          midPoint,
          dangerZones,
        );
        if (safePoint != null) {
          waypoints.add(safePoint);
          print(
            '[RouteMixin] ✅ Punto seguro alternativo encontrado: ${safePoint.latitude}, ${safePoint.longitude}',
          );
        }
      }
    }

    print(
      '[RouteMixin] 📊 Total waypoints seguros encontrados: ${waypoints.length}',
    );
    return waypoints;
  }

  // Métodos simplificados - no se usan en la versión básica

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
    print('🛣️ [RouteMixin] selectRoute llamado');
    print('🛣️ [RouteMixin] Nombre de ruta: ${route.name}');
    print('🛣️ [RouteMixin] Puntos de ruta: ${route.points.length}');
    print('🛣️ [RouteMixin] Ruta actual antes: ${_currentRoute.length} puntos');

    _currentRoute = route.points;

    print(
      '🛣️ [RouteMixin] Ruta actual después: ${_currentRoute.length} puntos',
    );
    print('🛣️ [RouteMixin] Llamando a onRouteSelected...');
    onRouteSelected(route);

    print('🛣️ [RouteMixin] Notificando listeners...');
    notifyListeners();
    print('🛣️ [RouteMixin] selectRoute completado');
  }

  void clearRoute() {
    _startPoint = null;
    _endPoint = null;
    _currentRoute.clear();
    _routeOptions.clear();
    onRoutesCleared();
    notifyListeners();
  }

  // 🧹 NUEVO: Método para limpiar rutas sin recursión
  void clearRouteSilently() {
    _startPoint = null;
    _endPoint = null;
    _currentRoute.clear();
    _routeOptions.clear();
    notifyListeners();
  }

  // 🛡️ NUEVO: Verificar si un punto está en zona peligrosa
  bool isPointInDangerZone(LatLng point) {
    try {
      // Intentar obtener clusters del MapViewModel
      final mapViewModel = GetIt.instance<MapViewModel>();
      final clusters = mapViewModel.clusters;

      for (final cluster in clusters) {
        final severity = cluster.severityNumber ?? 1;

        // Solo verificar clusters con severidad alta
        if (severity >= 3) {
          final clusterPoint = LatLng(
            cluster.centerLatitude,
            cluster.centerLongitude,
          );
          final distance = Distance().as(LengthUnit.Meter, point, clusterPoint);

          // Radio del cluster basado en la severidad
          final clusterRadius = _calculateClusterRadius(cluster);

          if (distance <= clusterRadius) {
            print(
              '[RouteMixin] 🚨 Punto en zona peligrosa: ${point.latitude}, ${point.longitude}',
            );
            print(
              '[RouteMixin] 🚨 Distancia al cluster: ${distance.toInt()}m, Radio: ${clusterRadius.toInt()}m',
            );
            return true;
          }
        }
      }
    } catch (e) {
      print('[RouteMixin] ❌ Error verificando zona peligrosa: $e');
    }

    return false;
  }

  // 🛡️ NUEVO: Calcular radio del cluster basado en severidad
  double _calculateClusterRadius(dynamic cluster) {
    try {
      final severity = cluster.severityNumber ?? 3;
      final reportCount = cluster.reportCount ?? 1;

      // Radio base de 100m + factor de severidad + factor de cantidad
      double radius = 100.0;
      radius += (severity - 1) * 50.0; // +50m por cada nivel de severidad
      radius += math.min(
        reportCount * 10.0,
        200.0,
      ); // +10m por reporte, máximo 200m

      return radius.clamp(100.0, 500.0);
    } catch (e) {
      return 200.0; // Radio por defecto
    }
  }

  // Callbacks abstractos
  double calculateRouteSafety(List<LatLng> route);
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
