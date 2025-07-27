import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

/// Servicio para detectar GPS falso y ubicaciones simuladas
class GpsSpoofingDetector {
  static final GpsSpoofingDetector _instance = GpsSpoofingDetector._internal();
  factory GpsSpoofingDetector() => _instance;
  GpsSpoofingDetector._internal();

  // Historial de ubicaciones para análisis
  final List<Position> _locationHistory = [];
  final int _maxHistorySize = 10;

  // Umbrales de detección - MUY SENSIBLES PARA DETECTAR FAKE GPS RÁPIDAMENTE
  static const double _maxSpeedKmh = 30.0; // Velocidad máxima muy conservadora
  static const double _minAccuracyMeters = 2.0; // Precisión mínima muy estricta
  static const double _maxAltitudeChangeMeters =
      200.0; // Cambio máximo de altitud muy conservador
  static const double _suspiciousAccuracyThreshold =
      3.0; // Precisión sospechosamente perfecta más alta

  /// Detecta si la ubicación actual es falsa o simulada
  Future<SpoofingDetectionResult> detectSpoofing({
    required Position currentPosition,
    Duration? timeWindow,
  }) async {
    try {
      print('[GpsSpoofingDetector] 🔍 Iniciando detección de GPS falso...');

      // Agregar posición actual al historial
      _addToHistory(currentPosition);

      // Realizar múltiples verificaciones
      final checks = await Future.wait([
        _checkSpeedAnomalies(),
        _checkAccuracyAnomalies(),
        _checkAltitudeAnomalies(),
        _checkLocationConsistency(),
        _checkProviderAnomalies(currentPosition),
        _checkTimeAnomalies(currentPosition),
        _checkFakeGpsSpecific(
          currentPosition,
        ), // NUEVA: Verificación específica para Fake GPS
      ]);

      // Calcular puntuación de riesgo
      final riskScore = _calculateRiskScore(checks);
      final isSpoofed =
          riskScore >=
          0.4; // Umbral más bajo del 40% para detectar Fake GPS más fácilmente

      final result = SpoofingDetectionResult(
        isSpoofed: isSpoofed,
        riskScore: riskScore,
        confidence: _calculateConfidence(checks),
        detectedIssues: checks.where((check) => check.isAnomaly).toList(),
        recommendations: _generateRecommendations(checks),
      );

      print(
        '[GpsSpoofingDetector] 📊 Resultado: ${result.isSpoofed ? "GPS FALSO DETECTADO" : "GPS REAL"}',
      );
      print(
        '[GpsSpoofingDetector] 🎯 Puntuación de riesgo: ${(riskScore * 100).toStringAsFixed(1)}%',
      );

      // Log detallado de cada verificación
      for (final check in checks) {
        print(
          '[GpsSpoofingDetector] 🔍 ${check.type}: ${check.isAnomaly ? "ANOMALÍA" : "NORMAL"} - ${check.description}',
        );
      }

      return result;
    } catch (e) {
      print('[GpsSpoofingDetector] ❌ Error en detección: $e');
      return SpoofingDetectionResult(
        isSpoofed: false,
        riskScore: 0.0,
        confidence: 0.0,
        detectedIssues: [],
        recommendations: ['Error en detección: $e'],
      );
    }
  }

  /// Verifica anomalías de velocidad
  Future<SpoofingCheck> _checkSpeedAnomalies() async {
    if (_locationHistory.length < 2) {
      return SpoofingCheck(
        type: SpoofingCheckType.speed,
        isAnomaly: false,
        severity: 0.0,
        description: 'Insuficientes datos para análisis de velocidad',
      );
    }

    final speeds = <double>[];
    for (int i = 1; i < _locationHistory.length; i++) {
      final prev = _locationHistory[i - 1];
      final curr = _locationHistory[i];

      final distance = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
      if (timeDiff > 0) {
        final speedKmh = (distance / 1000) / (timeDiff / 3600);
        speeds.add(speedKmh);
      }
    }

    final maxSpeed = speeds.isNotEmpty ? speeds.reduce(math.max) : 0.0;
    final isAnomaly = maxSpeed > _maxSpeedKmh;
    final severity = math.min(maxSpeed / _maxSpeedKmh, 1.0);

    return SpoofingCheck(
      type: SpoofingCheckType.speed,
      isAnomaly: isAnomaly,
      severity: severity,
      description:
          'Velocidad máxima detectada: ${maxSpeed.toStringAsFixed(1)} km/h',
    );
  }

  /// Verifica anomalías de precisión
  Future<SpoofingCheck> _checkAccuracyAnomalies() async {
    if (_locationHistory.isEmpty) {
      return SpoofingCheck(
        type: SpoofingCheckType.accuracy,
        isAnomaly: false,
        severity: 0.0,
        description: 'Sin datos de precisión',
      );
    }

    final accuracies = _locationHistory.map((pos) => pos.accuracy).toList();
    final avgAccuracy = accuracies.reduce((a, b) => a + b) / accuracies.length;
    final minAccuracy = accuracies.reduce(math.min);

    // Detectar precisión sospechosamente perfecta
    final isTooPerfect = minAccuracy < _suspiciousAccuracyThreshold;
    final isTooPoor = avgAccuracy > _minAccuracyMeters;

    final isAnomaly = isTooPerfect || isTooPoor;
    final severity = isTooPerfect ? 1.0 : (avgAccuracy / _minAccuracyMeters);

    return SpoofingCheck(
      type: SpoofingCheckType.accuracy,
      isAnomaly: isAnomaly,
      severity: severity,
      description:
          'Precisión promedio: ${avgAccuracy.toStringAsFixed(1)}m, mínima: ${minAccuracy.toStringAsFixed(1)}m',
    );
  }

  /// Verifica anomalías de altitud
  Future<SpoofingCheck> _checkAltitudeAnomalies() async {
    if (_locationHistory.length < 2) {
      return SpoofingCheck(
        type: SpoofingCheckType.altitude,
        isAnomaly: false,
        severity: 0.0,
        description: 'Insuficientes datos para análisis de altitud',
      );
    }

    final altitudeChanges = <double>[];
    for (int i = 1; i < _locationHistory.length; i++) {
      final prev = _locationHistory[i - 1];
      final curr = _locationHistory[i];

      if (prev.altitude != 0 && curr.altitude != 0) {
        final change = (curr.altitude - prev.altitude).abs();
        altitudeChanges.add(change);
      }
    }

    if (altitudeChanges.isEmpty) {
      return SpoofingCheck(
        type: SpoofingCheckType.altitude,
        isAnomaly: false,
        severity: 0.0,
        description: 'Sin datos de altitud disponibles',
      );
    }

    final maxChange = altitudeChanges.reduce(math.max);
    final isAnomaly = maxChange > _maxAltitudeChangeMeters;
    final severity = math.min(maxChange / _maxAltitudeChangeMeters, 1.0);

    return SpoofingCheck(
      type: SpoofingCheckType.altitude,
      isAnomaly: isAnomaly,
      severity: severity,
      description: 'Cambio máximo de altitud: ${maxChange.toStringAsFixed(1)}m',
    );
  }

  /// Verifica consistencia de ubicación
  Future<SpoofingCheck> _checkLocationConsistency() async {
    if (_locationHistory.length < 3) {
      return SpoofingCheck(
        type: SpoofingCheckType.consistency,
        isAnomaly: false,
        severity: 0.0,
        description: 'Insuficientes datos para análisis de consistencia',
      );
    }

    // Verificar si las ubicaciones están en una línea perfecta (sospechoso)
    final points =
        _locationHistory
            .map((pos) => LatLng(pos.latitude, pos.longitude))
            .toList();
    final isLinear = _isLinearPath(points);

    // Verificar si hay saltos imposibles
    final hasImpossibleJumps = _hasImpossibleJumps();

    final isAnomaly = isLinear || hasImpossibleJumps;
    final severity = isLinear ? 0.8 : (hasImpossibleJumps ? 0.9 : 0.0);

    return SpoofingCheck(
      type: SpoofingCheckType.consistency,
      isAnomaly: isAnomaly,
      severity: severity,
      description:
          isLinear
              ? 'Trayectoria sospechosamente lineal detectada'
              : hasImpossibleJumps
              ? 'Saltos imposibles detectados'
              : 'Trayectoria normal',
    );
  }

  /// Verifica anomalías del proveedor de ubicación
  Future<SpoofingCheck> _checkProviderAnomalies(Position position) async {
    // En geolocator, no hay propiedad provider, así que verificamos otros indicadores
    final isAnomaly =
        position.accuracy < 1.0; // Precisión sospechosamente perfecta
    final severity = isAnomaly ? 0.6 : 0.0;

    return SpoofingCheck(
      type: SpoofingCheckType.provider,
      isAnomaly: isAnomaly,
      severity: severity,
      description: 'Precisión: ${position.accuracy.toStringAsFixed(1)}m',
    );
  }

  /// Verifica anomalías de tiempo
  Future<SpoofingCheck> _checkTimeAnomalies(Position position) async {
    final now = DateTime.now();
    final timeDiff = now.difference(position.timestamp).abs();
    final isAnomaly = timeDiff.inMinutes > 5; // Más de 5 minutos de diferencia
    final severity = math.min(timeDiff.inMinutes / 10.0, 1.0);

    return SpoofingCheck(
      type: SpoofingCheckType.timestamp,
      isAnomaly: isAnomaly,
      severity: severity,
      description: 'Diferencia de tiempo: ${timeDiff.inMinutes} minutos',
    );
  }

  /// NUEVA: Verificación específica para detectar Fake GPS
  Future<SpoofingCheck> _checkFakeGpsSpecific(Position position) async {
    bool isAnomaly = false;
    double severity = 0.0;
    String description = '';

    // 1. Verificar si la precisión es sospechosamente constante
    if (_locationHistory.length >= 3) {
      final accuracies = _locationHistory.map((pos) => pos.accuracy).toList();
      final avgAccuracy =
          accuracies.reduce((a, b) => a + b) / accuracies.length;
      final variance =
          accuracies
              .map((acc) => math.pow(acc - avgAccuracy, 2))
              .reduce((a, b) => a + b) /
          accuracies.length;

      // Si la varianza es muy baja, es sospechoso (Fake GPS suele tener precisión constante)
      if (variance < 0.5) {
        isAnomaly = true;
        severity = 0.8;
        description =
            'Precisión sospechosamente constante (varianza: ${variance.toStringAsFixed(2)})';
      }
    }

    // 2. Verificar si hay saltos de ubicación sin movimiento gradual
    if (_locationHistory.length >= 2) {
      final lastPosition = _locationHistory[_locationHistory.length - 2];
      final distance = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );

      // Si hay un salto grande sin tiempo suficiente, es sospechoso
      if (distance > 1000) {
        // Más de 1km de salto
        final timeDiff =
            position.timestamp.difference(lastPosition.timestamp).inSeconds;
        if (timeDiff < 60) {
          // Menos de 1 minuto
          isAnomaly = true;
          severity = 0.9;
          description =
              'Salto de ubicación imposible: ${distance.toInt()}m en ${timeDiff}s';
        }
      }
    }

    // 3. Verificar si la ubicación está en coordenadas "redondas" (sospechoso)
    final latDecimal = position.latitude - position.latitude.floor();
    final lngDecimal = position.longitude - position.longitude.floor();

    // Coordenadas muy redondas son sospechosas
    if ((latDecimal < 0.001 || latDecimal > 0.999) &&
        (lngDecimal < 0.001 || lngDecimal > 0.999)) {
      isAnomaly = true;
      severity = 0.7;
      description = 'Coordenadas sospechosamente redondas';
    }

    // 4. Verificar si la altitud es constante (Fake GPS suele mantener altitud fija)
    if (_locationHistory.length >= 3) {
      final altitudes = _locationHistory.map((pos) => pos.altitude).toList();
      final avgAltitude = altitudes.reduce((a, b) => a + b) / altitudes.length;
      final altitudeVariance =
          altitudes
              .map((alt) => math.pow(alt - avgAltitude, 2))
              .reduce((a, b) => a + b) /
          altitudes.length;

      if (altitudeVariance < 1.0 && avgAltitude != 0) {
        isAnomaly = true;
        severity = 0.6;
        description = 'Altitud sospechosamente constante';
      }
    }

    return SpoofingCheck(
      type: SpoofingCheckType.consistency,
      isAnomaly: isAnomaly,
      severity: severity,
      description:
          description.isEmpty
              ? 'Sin anomalías específicas de Fake GPS'
              : description,
    );
  }

  /// Verifica si una trayectoria es lineal (sospechoso)
  bool _isLinearPath(List<LatLng> points) {
    if (points.length < 3) return false;

    // Calcular la desviación estándar de las distancias
    final distances = <double>[];
    for (int i = 1; i < points.length; i++) {
      final distance = Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
      distances.add(distance);
    }

    final avgDistance = distances.reduce((a, b) => a + b) / distances.length;
    final variance =
        distances
            .map((d) => math.pow(d - avgDistance, 2))
            .reduce((a, b) => a + b) /
        distances.length;
    final stdDev = math.sqrt(variance);

    // Si la desviación estándar es muy baja, es sospechoso
    return stdDev < 10.0; // Menos de 10 metros de variación
  }

  /// Verifica si hay saltos imposibles
  bool _hasImpossibleJumps() {
    for (int i = 1; i < _locationHistory.length; i++) {
      final prev = _locationHistory[i - 1];
      final curr = _locationHistory[i];

      final distance = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
      if (timeDiff > 0) {
        final speedKmh = (distance / 1000) / (timeDiff / 3600);
        if (speedKmh > _maxSpeedKmh) {
          return true;
        }
      }
    }
    return false;
  }

  /// Agrega posición al historial
  void _addToHistory(Position position) {
    _locationHistory.add(position);
    if (_locationHistory.length > _maxHistorySize) {
      _locationHistory.removeAt(0);
    }
  }

  /// Calcula puntuación de riesgo basada en todas las verificaciones
  double _calculateRiskScore(List<SpoofingCheck> checks) {
    if (checks.isEmpty) return 0.0;

    final totalSeverity = checks
        .map((check) => check.severity)
        .reduce((a, b) => a + b);
    final anomalyCount = checks.where((check) => check.isAnomaly).length;

    // Peso por severidad y cantidad de anomalías
    final severityScore = totalSeverity / checks.length;
    final anomalyScore = anomalyCount / checks.length;

    return (severityScore * 0.7) + (anomalyScore * 0.3);
  }

  /// Calcula nivel de confianza
  double _calculateConfidence(List<SpoofingCheck> checks) {
    final validChecks =
        checks
            .where(
              (check) =>
                  check.type != SpoofingCheckType.altitude ||
                  _locationHistory.any((pos) => pos.altitude != 0),
            )
            .length;

    return validChecks / checks.length;
  }

  /// Genera recomendaciones basadas en las verificaciones
  List<String> _generateRecommendations(List<SpoofingCheck> checks) {
    final recommendations = <String>[];

    for (final check in checks) {
      if (check.isAnomaly) {
        switch (check.type) {
          case SpoofingCheckType.speed:
            recommendations.add('⚠️ Velocidad detectada sospechosamente alta');
            break;
          case SpoofingCheckType.accuracy:
            recommendations.add('⚠️ Precisión GPS sospechosa');
            break;
          case SpoofingCheckType.altitude:
            recommendations.add('⚠️ Cambios de altitud imposibles detectados');
            break;
          case SpoofingCheckType.consistency:
            recommendations.add('⚠️ Trayectoria de movimiento sospechosa');
            break;
          case SpoofingCheckType.provider:
            recommendations.add('⚠️ Proveedor de ubicación desconocido');
            break;
          case SpoofingCheckType.timestamp:
            recommendations.add('⚠️ Timestamp de ubicación sospechoso');
            break;
        }
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ Ubicación parece ser real');
    }

    return recommendations;
  }

  /// Limpia el historial de ubicaciones
  void clearHistory() {
    _locationHistory.clear();
  }

  /// NUEVO: Detección inmediata para Fake GPS (sin esperar historial)
  Future<SpoofingDetectionResult> detectFakeGpsImmediately(
    Position position,
  ) async {
    try {
      print('[GpsSpoofingDetector] 🚨 DETECCIÓN INMEDIATA DE FAKE GPS...');

      // Agregar posición actual al historial
      _addToHistory(position);

      // Verificaciones inmediatas que no requieren historial
      final immediateChecks = <SpoofingCheck>[];

      // 1. Verificar precisión sospechosamente perfecta
      if (position.accuracy < 3.0) {
        immediateChecks.add(
          SpoofingCheck(
            type: SpoofingCheckType.accuracy,
            isAnomaly: true,
            severity: 0.8,
            description:
                'Precisión sospechosamente perfecta: ${position.accuracy.toStringAsFixed(1)}m',
          ),
        );
      }

      // 2. Verificar coordenadas redondas
      final latDecimal = position.latitude - position.latitude.floor();
      final lngDecimal = position.longitude - position.longitude.floor();
      if ((latDecimal < 0.001 || latDecimal > 0.999) &&
          (lngDecimal < 0.001 || lngDecimal > 0.999)) {
        immediateChecks.add(
          SpoofingCheck(
            type: SpoofingCheckType.consistency,
            isAnomaly: true,
            severity: 0.7,
            description: 'Coordenadas sospechosamente redondas',
          ),
        );
      }

      // 3. Verificar altitud sospechosa
      if (position.altitude != 0 && position.altitude.abs() < 10) {
        immediateChecks.add(
          SpoofingCheck(
            type: SpoofingCheckType.altitude,
            isAnomaly: true,
            severity: 0.6,
            description:
                'Altitud sospechosamente baja: ${position.altitude.toStringAsFixed(1)}m',
          ),
        );
      }

      // 4. Verificar timestamp
      final now = DateTime.now();
      final timeDiff = now.difference(position.timestamp).abs();
      if (timeDiff.inMinutes > 1) {
        // Más sensible
        immediateChecks.add(
          SpoofingCheck(
            type: SpoofingCheckType.timestamp,
            isAnomaly: true,
            severity: 0.5,
            description:
                'Timestamp sospechoso: ${timeDiff.inMinutes} min de diferencia',
          ),
        );
      }

      // 5. Verificar si las coordenadas están en valores "típicos" de Fake GPS
      final lat = position.latitude;
      final lng = position.longitude;

      // Coordenadas muy redondas o en valores típicos de Fake GPS
      if ((lat * 1000000).round() % 100000 == 0 ||
          (lng * 1000000).round() % 100000 == 0) {
        immediateChecks.add(
          SpoofingCheck(
            type: SpoofingCheckType.consistency,
            isAnomaly: true,
            severity: 0.9,
            description: 'Coordenadas típicas de Fake GPS',
          ),
        );
      }

      // 6. Verificar si la precisión es exactamente la misma (muy sospechoso)
      if (_locationHistory.isNotEmpty) {
        final lastAccuracy = _locationHistory.last.accuracy;
        if ((position.accuracy - lastAccuracy).abs() < 0.1) {
          immediateChecks.add(
            SpoofingCheck(
              type: SpoofingCheckType.accuracy,
              isAnomaly: true,
              severity: 0.7,
              description: 'Precisión idéntica (sospechoso)',
            ),
          );
        }
      }

      // Calcular riesgo inmediato
      final immediateRiskScore =
          immediateChecks.isNotEmpty
              ? immediateChecks.map((c) => c.severity).reduce((a, b) => a + b) /
                  immediateChecks.length
              : 0.0;

      final isSpoofed =
          immediateRiskScore >= 0.2; // Umbral muy bajo para detección inmediata

      final result = SpoofingDetectionResult(
        isSpoofed: isSpoofed,
        riskScore: immediateRiskScore,
        confidence: immediateChecks.length / 4.0,
        detectedIssues:
            immediateChecks.where((check) => check.isAnomaly).toList(),
        recommendations: _generateRecommendations(immediateChecks),
      );

      print(
        '[GpsSpoofingDetector] 🚨 DETECCIÓN INMEDIATA: ${result.isSpoofed ? "FAKE GPS DETECTADO" : "GPS REAL"}',
      );
      print(
        '[GpsSpoofingDetector] 🎯 Riesgo inmediato: ${(immediateRiskScore * 100).toStringAsFixed(1)}%',
      );

      return result;
    } catch (e) {
      print('[GpsSpoofingDetector] ❌ Error en detección inmediata: $e');
      return SpoofingDetectionResult(
        isSpoofed: false,
        riskScore: 0.0,
        confidence: 0.0,
        detectedIssues: [],
        recommendations: ['Error en detección inmediata: $e'],
      );
    }
  }
}

/// Resultado de la detección de GPS falso
class SpoofingDetectionResult {
  final bool isSpoofed;
  final double riskScore;
  final double confidence;
  final List<SpoofingCheck> detectedIssues;
  final List<String> recommendations;

  SpoofingDetectionResult({
    required this.isSpoofed,
    required this.riskScore,
    required this.confidence,
    required this.detectedIssues,
    required this.recommendations,
  });

  String get riskLevel {
    if (riskScore >= 0.8) return 'CRÍTICO';
    if (riskScore >= 0.6) return 'ALTO';
    if (riskScore >= 0.4) return 'MEDIO';
    if (riskScore >= 0.2) return 'BAJO';
    return 'MÍNIMO';
  }

  Color get riskColor {
    if (riskScore >= 0.8) return Colors.red;
    if (riskScore >= 0.6) return Colors.orange;
    if (riskScore >= 0.4) return Colors.yellow;
    if (riskScore >= 0.2) return Colors.lightGreen;
    return Colors.green;
  }
}

/// Verificación individual de spoofing
class SpoofingCheck {
  final SpoofingCheckType type;
  final bool isAnomaly;
  final double severity;
  final String description;

  SpoofingCheck({
    required this.type,
    required this.isAnomaly,
    required this.severity,
    required this.description,
  });
}

/// Tipos de verificaciones de spoofing
enum SpoofingCheckType {
  speed,
  accuracy,
  altitude,
  consistency,
  provider,
  timestamp,
}
