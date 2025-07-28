import 'dart:math';

/// Calculadora para determinar el radio de las zonas de peligro
/// basándose en la severidad promedio y máxima de los incidentes
class DangerZoneRadiusCalculator {
  /// Radio base en metros para zonas de peligro
  static const double _baseRadius = 75.0; // 75 metros - Reducido para ser más preciso

  /// Radio máximo en metros
  static const double _maxRadius = 250.0; // 250 metros - Reducido para ser más realista

  /// Radio mínimo en metros
  static const double _minRadius = 30.0; // 30 metros - Reducido para ser más preciso

  /// Factor de multiplicación por severidad
  static const double _severityMultiplier = 1.2; // Reducido para radios más conservadores

  /// Factor de multiplicación por cantidad de reportes
  static const double _reportCountMultiplier = 1.1; // Reducido para radios más conservadores

  /// Calcula el radio de la zona de peligro basándose en la severidad
  ///
  /// [averageSeverity]: Severidad promedio de los incidentes (1-5)
  /// [maxSeverity]: Severidad máxima de los incidentes (1-5)
  /// [reportCount]: Cantidad de reportes en el cluster
  ///
  /// Retorna el radio en metros
  static double calculateRadius({
    required double averageSeverity,
    required int maxSeverity,
    required int reportCount,
  }) {
    // Validar parámetros
    averageSeverity = averageSeverity.clamp(1.0, 5.0);
    maxSeverity = maxSeverity.clamp(1, 5);
    reportCount = reportCount.clamp(1, 100);

    // Calcular factor de severidad (promedio + máximo)
    final severityFactor = (averageSeverity + maxSeverity) / 2.0;

    // Calcular factor de cantidad de reportes (logarítmico para evitar valores muy altos)
    final reportCountFactor = log(reportCount + 1) / log(10);

    // Calcular radio base con factores
    double radius =
        _baseRadius *
        (severityFactor * _severityMultiplier) *
        (reportCountFactor * _reportCountMultiplier);

    // Aplicar límites
    radius = radius.clamp(_minRadius, _maxRadius);

    return radius;
  }

  /// Calcula el radio basándose en el nivel de riesgo
  ///
  /// [riskLevel]: Nivel de riesgo ("LOW", "MEDIUM", "HIGH", "CRITICAL")
  /// [reportCount]: Cantidad de reportes
  static double calculateRadiusByRiskLevel({
    required String riskLevel,
    required int reportCount,
  }) {
    double severityMultiplier;

    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        severityMultiplier = 1.0;
        break;
      case 'MEDIUM':
        severityMultiplier = 1.5;
        break;
      case 'HIGH':
        severityMultiplier = 2.0;
        break;
      case 'CRITICAL':
        severityMultiplier = 2.5;
        break;
      default:
        severityMultiplier = 1.0;
    }

    final reportCountFactor = log(reportCount + 1) / log(10);
    double radius = _baseRadius * severityMultiplier * reportCountFactor;

    return radius.clamp(_minRadius, _maxRadius);
  }

  /// Calcula el radio basándose en el tipo de cluster
  ///
  /// [clusterType]: Tipo de cluster ("HIGH_ACTIVITY", "MEDIUM_ACTIVITY", etc.)
  /// [averageSeverity]: Severidad promedio
  /// [reportCount]: Cantidad de reportes
  static double calculateRadiusByClusterType({
    required String clusterType,
    required double averageSeverity,
    required int reportCount,
  }) {
    double typeMultiplier;

    switch (clusterType.toUpperCase()) {
      case 'HIGH_ACTIVITY':
        typeMultiplier = 2.0;
        break;
      case 'MEDIUM_ACTIVITY':
        typeMultiplier = 1.5;
        break;
      case 'LOW_ACTIVITY':
        typeMultiplier = 1.0;
        break;
      default:
        typeMultiplier = 1.0;
    }

    final severityFactor = averageSeverity.clamp(1.0, 5.0);
    final reportCountFactor = log(reportCount + 1) / log(10);

    double radius =
        _baseRadius * typeMultiplier * severityFactor * reportCountFactor;

    return radius.clamp(_minRadius, _maxRadius);
  }

  /// Obtiene el color de la zona basándose en el radio
  ///
  /// [radius]: Radio en metros
  /// Retorna un color en formato hexadecimal
  static String getZoneColor(double radius) {
    if (radius >= 400) {
      return '#FF0000'; // Rojo - Muy peligroso
    } else if (radius >= 300) {
      return '#FF6600'; // Naranja - Alto peligro
    } else if (radius >= 200) {
      return '#FFCC00'; // Amarillo - Peligro medio
    } else if (radius >= 100) {
      return '#00CC00'; // Verde - Bajo peligro
    } else {
      return '#0066CC'; // Azul - Muy bajo peligro
    }
  }

  /// Obtiene la opacidad de la zona basándose en el radio
  ///
  /// [radius]: Radio en metros
  /// Retorna un valor entre 0.0 y 1.0
  static double getZoneOpacity(double radius) {
    // Normalizar el radio entre 0 y 1
    final normalizedRadius = (radius - _minRadius) / (_maxRadius - _minRadius);

    // Aplicar una curva logarítmica para mejor distribución visual
    return (0.3 + (normalizedRadius * 0.7)).clamp(0.3, 1.0);
  }

  /// Obtiene el grosor del borde basándose en el radio
  ///
  /// [radius]: Radio en metros
  /// Retorna el grosor en píxeles
  static double getZoneBorderWidth(double radius) {
    if (radius >= 400) {
      return 4.0; // Borde grueso para zonas muy peligrosas
    } else if (radius >= 300) {
      return 3.0;
    } else if (radius >= 200) {
      return 2.0;
    } else {
      return 1.0; // Borde fino para zonas menos peligrosas
    }
  }

  /// Calcula el radio recomendado para mostrar en la UI
  ///
  /// [averageSeverity]: Severidad promedio
  /// [maxSeverity]: Severidad máxima
  /// [reportCount]: Cantidad de reportes
  /// [riskLevel]: Nivel de riesgo
  /// [clusterType]: Tipo de cluster
  ///
  /// Retorna un mapa con información del radio calculado
  static Map<String, dynamic> calculateRecommendedRadius({
    required double averageSeverity,
    required int maxSeverity,
    required int reportCount,
    required String riskLevel,
    required String clusterType,
  }) {
    // Calcular radio usando múltiples métodos
    final severityRadius = calculateRadius(
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      reportCount: reportCount,
    );

    final riskRadius = calculateRadiusByRiskLevel(
      riskLevel: riskLevel,
      reportCount: reportCount,
    );

    final clusterRadius = calculateRadiusByClusterType(
      clusterType: clusterType,
      averageSeverity: averageSeverity,
      reportCount: reportCount,
    );

    // Promedio ponderado (dar más peso al método de severidad)
    final recommendedRadius =
        (severityRadius * 0.5 + riskRadius * 0.3 + clusterRadius * 0.2);

    return {
      'radius': recommendedRadius,
      'color': getZoneColor(recommendedRadius),
      'opacity': getZoneOpacity(recommendedRadius),
      'borderWidth': getZoneBorderWidth(recommendedRadius),
      'severityRadius': severityRadius,
      'riskRadius': riskRadius,
      'clusterRadius': clusterRadius,
    };
  }
}
