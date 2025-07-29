import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/value_objects/safety_level.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';
import 'package:safy/home/domain/value_objects/danger_level.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';
import 'dart:math' as math;

class CalculateSafeRoutesUseCase {
  final RouteRepository _routeRepository;
  final DangerZoneRepository _dangerZoneRepository;
  final ReportRepository? _reportRepository;

  CalculateSafeRoutesUseCase(
    this._routeRepository,
    this._dangerZoneRepository, [
    this._reportRepository,
  ]);

  Future<List<RouteEntity>> execute({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
  }) async {
    try {
      // 1. Obtener zonas peligrosas en el área
      final dangerZones = await _dangerZoneRepository.getDangerZonesInArea(
        center: Location(
          latitude: (startPoint.latitude + endPoint.latitude) / 2,
          longitude: (startPoint.longitude + endPoint.longitude) / 2,
        ),
        radiusKm: 15.0, // Radio más amplio para mejor cobertura
      );

      // 2. Obtener clusters de reportes si está disponible
      List<ClusterEntity> clusters = [];
      if (_reportRepository != null) {
        try {
          clusters = await _reportRepository!.getClusters(
            latitude: (startPoint.latitude + endPoint.latitude) / 2,
            longitude: (startPoint.longitude + endPoint.longitude) / 2,
            radiusKm: 10.0,
          );
        } catch (e) {
          // Removed debug print
        }
      }

      // 3. Combinar zonas peligrosas con clusters
      final allDangerZones = _combineDangerZonesAndClusters(
        dangerZones,
        clusters,
      );

      // 4. Calcular ruta directa
      final directRoute = await _routeRepository.calculateRoutes(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
      );

      // 5. Evaluar seguridad de la ruta directa
      final directRouteEvaluation = _evaluateRouteSafety(
        directRoute.first,
        allDangerZones,
      );

      // 6. Si la ruta directa es segura, devolverla como principal
      if (directRouteEvaluation.safetyLevel.percentage >= 75) {
        final safeDirectRoute = directRoute.first.copyWith(
          safetyLevel: directRouteEvaluation.safetyLevel,
          warnings: directRouteEvaluation.warnings,
          isRecommended: true,
        );
        return [safeDirectRoute];
      }

      // 7. Si no es segura, calcular rutas alternativas
      final alternativeRoutes = await _calculateAlternativeSafeRoutes(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
        dangerZones: allDangerZones,
      );

      // 8. Combinar y ordenar todas las rutas
      final allRoutes = <RouteEntity>[];

      // Agregar ruta directa (aunque no sea segura) para comparación
      allRoutes.add(
        directRoute.first.copyWith(
          safetyLevel: directRouteEvaluation.safetyLevel,
          warnings: directRouteEvaluation.warnings,
          isRecommended: false,
        ),
      );

      allRoutes.addAll(alternativeRoutes);

      // 9. Ordenar por seguridad y eficiencia
      allRoutes.sort((a, b) {
        // Priorizar rutas seguras
        if (a.isSafe && !b.isSafe) return -1;
        if (!a.isSafe && b.isSafe) return 1;

        // Si ambas son igualmente seguras, ordenar por tiempo
        return a.durationMinutes.compareTo(b.durationMinutes);
      });

      return allRoutes;
    } catch (e) {
      throw ServerFailure('Error calculando rutas seguras: $e');
    }
  }

  Future<List<RouteEntity>> _calculateAlternativeSafeRoutes({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
    required List<DangerZone> dangerZones,
  }) async {
    final alternativeRoutes = <RouteEntity>[];

    // 1. Encontrar waypoints seguros
    final safeWaypoints = _findSafeWaypoints(startPoint, endPoint, dangerZones);

    // 2. Calcular ruta con waypoints seguros
    if (safeWaypoints.isNotEmpty) {
      try {
        final safeRoute = await _calculateRouteWithWaypoints(
          startPoint: startPoint,
          endPoint: endPoint,
          waypoints: safeWaypoints,
          transportMode: transportMode,
        );

        final safeEvaluation = _evaluateRouteSafety(safeRoute, dangerZones);
        alternativeRoutes.add(
          safeRoute.copyWith(
            safetyLevel: safeEvaluation.safetyLevel,
            warnings: safeEvaluation.warnings,
            isRecommended: true,
          ),
        );
      } catch (e) {
        // Removed debug print
      }
    }

    // 3. Calcular ruta perimetral (evita el centro de zonas peligrosas)
    try {
      final perimeterRoute = await _calculatePerimeterRoute(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
        dangerZones: dangerZones,
      );

      final perimeterEvaluation = _evaluateRouteSafety(
        perimeterRoute,
        dangerZones,
      );
      alternativeRoutes.add(
        perimeterRoute.copyWith(
          safetyLevel: perimeterEvaluation.safetyLevel,
          warnings: perimeterEvaluation.warnings,
          isRecommended: perimeterEvaluation.safetyLevel.percentage >= 70,
        ),
      );
    } catch (e) {
      // Removed debug print
    }

    // 4. Calcular ruta con desvío amplio
    try {
      final detourRoute = await _calculateDetourRoute(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
        dangerZones: dangerZones,
      );

      final detourEvaluation = _evaluateRouteSafety(detourRoute, dangerZones);
      alternativeRoutes.add(
        detourRoute.copyWith(
          safetyLevel: detourEvaluation.safetyLevel,
          warnings: detourEvaluation.warnings,
          isRecommended: detourEvaluation.safetyLevel.percentage >= 80,
        ),
      );
    } catch (e) {
      // Removed debug print
    }

    return alternativeRoutes;
  }

  List<Location> _findSafeWaypoints(
    Location startPoint,
    Location endPoint,
    List<DangerZone> dangerZones,
  ) {
    final waypoints = <Location>[];
    final checkPoints = _getPointsAlongPath(
      startPoint,
      endPoint,
      intervalMeters: 200,
    );

    for (final point in checkPoints) {
      if (_isPointInDangerZone(point, dangerZones)) {
        final safePoint = _findNearestSafePoint(point, dangerZones);
        if (safePoint != null && !_containsLocation(waypoints, safePoint)) {
          waypoints.add(safePoint);
        }
      }
    }

    return _optimizeWaypoints(waypoints, startPoint, endPoint);
  }

  Location? _findNearestSafePoint(
    Location dangerousPoint,
    List<DangerZone> dangerZones,
  ) {
    const maxSearchRadius = 1000; // 1km
    const searchStep = 100;
    const angleStep = 30;

    for (
      int radius = searchStep;
      radius <= maxSearchRadius;
      radius += searchStep
    ) {
      for (int angle = 0; angle < 360; angle += angleStep) {
        final candidate = _getPointAtDistance(
          dangerousPoint,
          radius.toDouble(),
          angle.toDouble(),
        );
        if (!_isPointInDangerZone(candidate, dangerZones)) {
          return candidate;
        }
      }
    }
    return null;
  }

  Location _getPointAtDistance(
    Location center,
    double distanceMeters,
    double angleDegrees,
  ) {
    const earthRadius = 6371000;
    final distRad = distanceMeters / earthRadius;
    final bearingRad = angleDegrees * (math.pi / 180);

    final lat1Rad = center.latitude * (math.pi / 180);
    final lon1Rad = center.longitude * (math.pi / 180);

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

    return Location(
      latitude: lat2Rad * (180 / math.pi),
      longitude: lon2Rad * (180 / math.pi),
    );
  }

  List<Location> _getPointsAlongPath(
    Location start,
    Location end, {
    double intervalMeters = 200,
  }) {
    final points = <Location>[];
    final totalDistance = _calculateDistance(start, end);

    if (totalDistance < intervalMeters) {
      return [];
    }

    final numPoints = (totalDistance / intervalMeters).ceil();

    for (int i = 1; i < numPoints; i++) {
      final fraction = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng =
          start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(Location(latitude: lat, longitude: lng));
    }

    return points;
  }

  List<Location> _optimizeWaypoints(
    List<Location> waypoints,
    Location start,
    Location end,
  ) {
    if (waypoints.isEmpty) return waypoints;

    final optimized = <Location>[];
    const minDistance = 300.0; // 300 metros mínimo entre waypoints

    for (final waypoint in waypoints) {
      bool tooClose = false;

      if (_calculateDistance(waypoint, start) < minDistance ||
          _calculateDistance(waypoint, end) < minDistance) {
        continue;
      }

      for (final existing in optimized) {
        if (_calculateDistance(waypoint, existing) < minDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        optimized.add(waypoint);
      }
    }

    // Ordenar por distancia al punto de inicio
    optimized.sort((a, b) {
      final distA = _calculateDistance(start, a);
      final distB = _calculateDistance(start, b);
      return distA.compareTo(distB);
    });

    return optimized.take(3).toList(); // Máximo 3 waypoints
  }

  Future<RouteEntity> _calculateRouteWithWaypoints({
    required Location startPoint,
    required Location endPoint,
    required List<Location> waypoints,
    required TransportMode transportMode,
  }) async {
    // Por ahora, calcular segmentos individuales
    // En una implementación real, usarías un servicio que soporte waypoints
    final allWaypoints = [startPoint, ...waypoints, endPoint];
    final routeSegments = <Location>[];

    for (int i = 0; i < allWaypoints.length - 1; i++) {
      final segment = await _routeRepository.calculateRoutes(
        startPoint: allWaypoints[i],
        endPoint: allWaypoints[i + 1],
        transportMode: transportMode,
      );
      routeSegments.addAll(segment.first.waypoints);
    }

    // Crear ruta combinada
    return RouteEntity(
      id: 'safe_route_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Ruta Segura',
      waypoints: routeSegments,
      startPoint: startPoint,
      endPoint: endPoint,
      distanceKm: _calculateTotalDistance(routeSegments),
      durationMinutes: _estimateDuration(routeSegments, transportMode),
      safetyLevel: SafetyLevel(percentage: 85, description: 'Muy segura'),
      transportMode: transportMode,
      isRecommended: true,
      warnings: ['Ruta optimizada para evitar zonas peligrosas'],
    );
  }

  Future<RouteEntity> _calculatePerimeterRoute({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
    required List<DangerZone> dangerZones,
  }) async {
    // Calcular puntos perimetrales alrededor de zonas peligrosas
    final perimeterPoints = <Location>[];

    for (final dangerZone in dangerZones) {
      final perimeterPoint = _getPerimeterPoint(
        dangerZone,
        startPoint,
        endPoint,
      );
      if (perimeterPoint != null) {
        perimeterPoints.add(perimeterPoint);
      }
    }

    // Usar el punto perimetral más cercano a la ruta directa
    if (perimeterPoints.isNotEmpty) {
      final bestPerimeterPoint = _findBestPerimeterPoint(
        perimeterPoints,
        startPoint,
        endPoint,
      );

      return await _calculateRouteWithWaypoints(
        startPoint: startPoint,
        endPoint: endPoint,
        waypoints: [bestPerimeterPoint],
        transportMode: transportMode,
      );
    }

    // Si no hay puntos perimetrales, devolver ruta directa
    final directRoute = await _routeRepository.calculateRoutes(
      startPoint: startPoint,
      endPoint: endPoint,
      transportMode: transportMode,
    );

    return directRoute.first.copyWith(
      name: 'Ruta Perimetral',
      isRecommended: false,
    );
  }

  Future<RouteEntity> _calculateDetourRoute({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
    required List<DangerZone> dangerZones,
  }) async {
    // Calcular un desvío amplio alrededor de todas las zonas peligrosas
    final detourPoint = _calculateDetourPoint(
      startPoint,
      endPoint,
      dangerZones,
    );

    return await _calculateRouteWithWaypoints(
      startPoint: startPoint,
      endPoint: endPoint,
      waypoints: [detourPoint],
      transportMode: transportMode,
    );
  }

  Location _calculateDetourPoint(
    Location start,
    Location end,
    List<DangerZone> dangerZones,
  ) {
    // Calcular el centro de todas las zonas peligrosas
    if (dangerZones.isEmpty) {
      return Location(
        latitude: (start.latitude + end.latitude) / 2,
        longitude: (start.longitude + end.longitude) / 2,
      );
    }

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final zone in dangerZones) {
      totalLat += zone.center.latitude;
      totalLng += zone.center.longitude;
      count++;
    }

    final dangerCenter = Location(
      latitude: totalLat / count,
      longitude: totalLng / count,
    );

    // Calcular punto de desvío alejado del centro de peligro
    final detourDistance = 2000.0; // 2km de desvío
    final bearing = _calculateBearing(start, end);
    final detourBearing = bearing + 90.0; // Desvío perpendicular

    return _getPointAtDistance(dangerCenter, detourDistance, detourBearing);
  }

  Location? _getPerimeterPoint(
    DangerZone dangerZone,
    Location start,
    Location end,
  ) {
    final zoneCenter = dangerZone.center;
    final safeRadius =
        dangerZone.radiusMeters + 200; // 200m adicional de seguridad

    // Calcular punto en el perímetro más cercano a la ruta
    final routeBearing = _calculateBearing(start, end);
    final perimeterBearing = routeBearing + 45; // 45 grados de desvío

    return _getPointAtDistance(zoneCenter, safeRadius, perimeterBearing);
  }

  Location _findBestPerimeterPoint(
    List<Location> perimeterPoints,
    Location start,
    Location end,
  ) {
    if (perimeterPoints.isEmpty) {
      return Location(
        latitude: (start.latitude + end.latitude) / 2,
        longitude: (start.longitude + end.longitude) / 2,
      );
    }

    // Encontrar el punto que minimiza la distancia total
    Location bestPoint = perimeterPoints.first;
    double minTotalDistance = double.infinity;

    for (final point in perimeterPoints) {
      final totalDistance =
          _calculateDistance(start, point) + _calculateDistance(point, end);
      if (totalDistance < minTotalDistance) {
        minTotalDistance = totalDistance;
        bestPoint = point;
      }
    }

    return bestPoint;
  }

  double _calculateBearing(Location from, Location to) {
    final lat1 = from.latitude * (math.pi / 180);
    final lat2 = to.latitude * (math.pi / 180);
    final deltaLng = (to.longitude - from.longitude) * (math.pi / 180);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    final bearing = math.atan2(y, x) * (180 / math.pi);
    return (bearing + 360) % 360;
  }

  bool _isPointInDangerZone(Location point, List<DangerZone> dangerZones) {
    for (final zone in dangerZones) {
      if (zone.isLocationInDangerZone(point)) {
        return true;
      }
    }
    return false;
  }

  bool _containsLocation(List<Location> locations, Location location) {
    for (final loc in locations) {
      if (_calculateDistance(loc, location) < 50) {
        // 50m de tolerancia
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(Location point1, Location point2) {
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

  double _calculateTotalDistance(List<Location> waypoints) {
    double totalDistance = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistance += _calculateDistance(waypoints[i], waypoints[i + 1]);
    }
    return totalDistance / 1000; // Convertir a kilómetros
  }

  int _estimateDuration(List<Location> waypoints, TransportMode transportMode) {
    final distanceKm = _calculateTotalDistance(waypoints);
    final speeds = {
      TransportMode.walking: 5.0, // 5 km/h
      TransportMode.driving: 40.0, // 40 km/h
      TransportMode.publicTransport: 25.0, // 25 km/h
    };

    final speed = speeds[transportMode] ?? 5.0;
    return (distanceKm / speed * 60.0).round(); // Convertir a minutos
  }

  _RouteEvaluation _evaluateRouteSafety(
    RouteEntity route,
    List<DangerZone> dangerZones,
  ) {
    final warnings = <String>[];
    double safetyScore = 100.0;

    // Evaluar cada waypoint de la ruta
    for (final waypoint in route.waypoints) {
      for (final dangerZone in dangerZones) {
        if (dangerZone.isLocationInDangerZone(waypoint)) {
          safetyScore -= _getDangerPenalty(dangerZone);
          warnings.add(_getDangerWarning(dangerZone));
        }
      }
    }

    // Evaluar hora del día (más peligroso de noche)
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour <= 6) {
      safetyScore -= 10;
      warnings.add('Horario nocturno: mayor riesgo de incidentes');
    }

    // Evaluar densidad de zonas peligrosas
    final dangerousWaypoints =
        route.waypoints.where((waypoint) {
          return dangerZones.any(
            (zone) => zone.isLocationInDangerZone(waypoint),
          );
        }).length;

    final dangerPercentage = dangerousWaypoints / route.waypoints.length;
    if (dangerPercentage > 0.3) {
      safetyScore -= 20;
      warnings.add('Ruta atraviesa múltiples zonas de riesgo');
    }

    safetyScore = safetyScore.clamp(0, 100);

    return _RouteEvaluation(
      safetyLevel: SafetyLevel(
        percentage: safetyScore,
        description: _getSafetyDescription(safetyScore),
      ),
      warnings: warnings,
      isRecommended: safetyScore >= 75 && warnings.length <= 1,
    );
  }

  double _getDangerPenalty(DangerZone dangerZone) {
    switch (dangerZone.dangerLevel) {
      case DangerLevel.low:
        return 5.0;
      case DangerLevel.medium:
        return 15.0;
      case DangerLevel.high:
        return 25.0;
      case DangerLevel.critical:
        return 40.0;
    }
  }

  String _getDangerWarning(DangerZone dangerZone) {
    return 'Zona de riesgo ${dangerZone.dangerLevel.displayName.toLowerCase()}: '
        '${dangerZone.reportCount} reportes recientes';
  }

  String _getSafetyDescription(double score) {
    if (score >= 85) return 'Muy segura';
    if (score >= 70) return 'Segura';
    if (score >= 50) return 'Moderada';
    if (score >= 30) return 'Riesgosa';
    return 'Muy peligrosa';
  }

  List<DangerZone> _combineDangerZonesAndClusters(
    List<DangerZone> dangerZones,
    List<ClusterEntity> clusters,
  ) {
    final combinedZones = <DangerZone>[];

    // Agregar zonas peligrosas existentes
    combinedZones.addAll(dangerZones);

    // Convertir clusters en zonas peligrosas
    for (final cluster in clusters) {
      final clusterZone = _convertClusterToDangerZone(cluster);
      combinedZones.add(clusterZone);
    }

    return combinedZones;
  }

  DangerZone _convertClusterToDangerZone(ClusterEntity cluster) {
    // Determinar nivel de peligro basado en la severidad del cluster
    DangerLevel dangerLevel;
    if (cluster.averageSeverity >= 4) {
      dangerLevel = DangerLevel.critical;
    } else if (cluster.averageSeverity >= 3) {
      dangerLevel = DangerLevel.high;
    } else if (cluster.averageSeverity >= 2) {
      dangerLevel = DangerLevel.medium;
    } else {
      dangerLevel = DangerLevel.low;
    }

    return DangerZone(
      id: 'cluster_${cluster.clusterId}',
      center: Location(
        latitude: cluster.centerLatitude,
        longitude: cluster.centerLongitude,
      ),
      radiusMeters: 200.0, // Radio fijo para clusters
      dangerLevel: dangerLevel,
      reportCount: cluster.reportCount,
      lastReportAt:
          DateTime.now(), // Usar tiempo actual ya que no hay timestamp específico
      incidentTypes: [
        cluster.dominantIncidentType,
      ], // Usar el tipo de incidente dominante
      isActive: true,
    );
  }
}

class _RouteEvaluation {
  final SafetyLevel safetyLevel;
  final List<String> warnings;
  final bool isRecommended;

  _RouteEvaluation({
    required this.safetyLevel,
    required this.warnings,
    required this.isRecommended,
  });
}
