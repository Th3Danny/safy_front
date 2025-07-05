import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/value_objects/safety_level.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';
import 'package:safy/home/domain/value_objects/danger_level.dart';

class CalculateSafeRoutesUseCase {
  final RouteRepository _routeRepository;
  final DangerZoneRepository _dangerZoneRepository;

  CalculateSafeRoutesUseCase(this._routeRepository, this._dangerZoneRepository);

  Future<List<RouteEntity>> execute({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
  }) async {
    try {
      // 1. Calcular rutas básicas
      final routes = await _routeRepository.calculateRoutes(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
      );

      // 2. Obtener zonas peligrosas en el área
      final dangerZones = await _dangerZoneRepository.getDangerZonesInArea(
        center: Location(
          latitude: (startPoint.latitude + endPoint.latitude) / 2,
          longitude: (startPoint.longitude + endPoint.longitude) / 2,
        ),
        radiusKm: 10.0,
      );

      // 3. Evaluar seguridad de cada ruta
      final evaluatedRoutes = <RouteEntity>[];
      for (final route in routes) {
        final safetyEvaluation = _evaluateRouteSafety(route, dangerZones);
        final updatedRoute = route.copyWith(
          safetyLevel: safetyEvaluation.safetyLevel,
          warnings: safetyEvaluation.warnings,
          isRecommended: safetyEvaluation.isRecommended,
        );
        evaluatedRoutes.add(updatedRoute);
      }

      // 4. Ordenar por seguridad y eficiencia
      evaluatedRoutes.sort((a, b) {
        // Priorizar rutas seguras
        if (a.isSafe && !b.isSafe) return -1;
        if (!a.isSafe && b.isSafe) return 1;

        // Si ambas son igualmente seguras, ordenar por tiempo
        return a.durationMinutes.compareTo(b.durationMinutes);
      });

      return evaluatedRoutes;
    } catch (e) {
      throw ServerFailure('Error calculando rutas seguras: $e');
    }
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
