import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
// import 'package:detect_fake_location/detect_fake_location.dart';  // Comentado por problemas de compatibilidad

/// Servicio para detectar GPS falso y ubicaciones simuladas
class GpsSpoofingDetector {
  static final GpsSpoofingDetector _instance = GpsSpoofingDetector._internal();
  factory GpsSpoofingDetector() => _instance;
  GpsSpoofingDetector._internal();

  // Historial de ubicaciones para análisis
  final List<Position> _locationHistory = [];
  final int _maxHistorySize = 10;

  // Umbrales de detección - MÁS TOLERANTES CON GPS REAL
  static const double _maxSpeedKmh =
      200.0; // Velocidad máxima permisiva (aumentado)
  static const double _minAccuracyMeters =
      5.0; // Precisión mínima permisiva (más tolerante)
  static const double _maxAltitudeChangeMeters =
      1000.0; // Cambio máximo de altitud permisivo (aumentado)
  static const double _suspiciousAccuracyThreshold =
      0.1; // Precisión sospechosamente perfecta (más estricta solo para Fake GPS)

  /// Detecta si la ubicación actual es falsa o simulada
  Future<SpoofingDetectionResult> detectSpoofing({
    required Position currentPosition,
    Duration? timeWindow,
  }) async {
    try {
      // Agregar posición actual al historial
      _addToHistory(currentPosition);

      // PRIMERO: Verificación nativa (más confiable)
      final nativeCheck = await _checkNativeSpoofing(currentPosition);

      if (nativeCheck.isAnomaly) {
        return SpoofingDetectionResult(
          isSpoofed: true,
          riskScore: 0.95,
          confidence: 0.95,
          detectedIssues: [nativeCheck],
          recommendations: ['Fake GPS detectado por verificación nativa'],
        );
      }

      // SEGUNDO: Verificaciones algorítmicas
      final checks = await Future.wait([
        _checkSpeedAnomalies(),
        _checkAccuracyAnomalies(),
        _checkAltitudeAnomalies(),
        _checkLocationConsistency(),
        _checkProviderAnomalies(currentPosition),
        _checkTimeAnomalies(currentPosition),
        _checkFakeGpsSpecific(
          currentPosition,
        ), // Verificación específica para Fake GPS
        _checkFakeGpsImmediate(
          currentPosition,
        ), // NUEVA: Verificación inmediata
      ]);

      // Calcular puntuación de riesgo
      final riskScore = _calculateRiskScore(checks);
      final isSpoofed =
          riskScore >=
          0.7; // Umbral alto del 70% para ser menos sensible a GPS real

      final result = SpoofingDetectionResult(
        isSpoofed: isSpoofed,
        riskScore: riskScore,
        confidence: _calculateConfidence(checks),
        detectedIssues: checks.where((check) => check.isAnomaly).toList(),
        recommendations: _generateRecommendations(checks),
      );

      return result;
    } catch (e) {
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

    // Detectar precisión sospechosamente perfecta (más estricto)
    final isTooPerfect = minAccuracy < _suspiciousAccuracyThreshold;
    final isTooPoor = avgAccuracy > _minAccuracyMeters;

    // Ser más permisivo con GPS real - solo detectar si es muy sospechoso
    final isAnomaly =
        isTooPerfect && minAccuracy < 0.1; // Solo si es extremadamente perfecto
    final severity = isTooPerfect ? 0.8 : (avgAccuracy / _minAccuracyMeters);

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
    final isAnomaly =
        timeDiff.inMinutes > 2; // Más estricto: más de 2 minutos de diferencia
    final severity = math.min(timeDiff.inMinutes / 5.0, 1.0);

    return SpoofingCheck(
      type: SpoofingCheckType.timestamp,
      isAnomaly: isAnomaly,
      severity: severity,
      description: 'Diferencia de tiempo: ${timeDiff.inMinutes} minutos',
    );
  }

  /// NUEVA: Verificación inmediata para Fake GPS (sin esperar historial)
  Future<SpoofingCheck> _checkFakeGpsImmediate(Position position) async {
    bool isAnomaly = false;
    double severity = 0.0;
    String description = '';

    // 1. Verificar coordenadas redondas (muy sospechoso)
    final latDecimal = position.latitude - position.latitude.floor();
    final lngDecimal = position.longitude - position.longitude.floor();

    // Coordenadas muy redondas son sospechosas
    if ((latDecimal < 0.001 || latDecimal > 0.999) &&
        (lngDecimal < 0.001 || lngDecimal > 0.999)) {
      isAnomaly = true;
      severity = 0.9;
      description = 'Coordenadas sospechosamente redondas';
    }

    // 2. Verificar precisión sospechosamente perfecta
    if (position.accuracy < 0.1) {
      isAnomaly = true;
      severity = 0.9;
      description =
          'Precisión sospechosamente perfecta: ${position.accuracy.toStringAsFixed(1)}m';
    }

    // 3. Verificar altitud sospechosa (Fake GPS suele usar altitud 0 o muy baja)
    if (position.altitude == 0 && position.accuracy < 0.1) {
      isAnomaly = true;
      severity = 0.7;
      description = 'Altitud exactamente 0 con precisión perfecta (sospechoso)';
    }

    // 4. Verificar si las coordenadas están en valores "típicos" de Fake GPS
    final lat = position.latitude;
    final lng = position.longitude;

    // Coordenadas muy redondas o en valores típicos de Fake GPS
    if ((lat * 1000000).round() % 100000 == 0 ||
        (lng * 1000000).round() % 100000 == 0) {
      isAnomaly = true;
      severity = 0.9;
      description = 'Coordenadas típicas de Fake GPS';
    }

    // 5. Verificar si la precisión es exactamente la misma que la anterior (muy sospechoso)
    if (_locationHistory.isNotEmpty) {
      final lastAccuracy = _locationHistory.last.accuracy;
      if ((position.accuracy - lastAccuracy).abs() < 0.01) {
        isAnomaly = true;
        severity = 0.8;
        description = 'Precisión idéntica (sospechoso)';
      }
    }

    // 6. Verificar coordenadas en valores muy específicos (típico de Fake GPS)
    // Coordenadas que terminan en .0000 o .5000 (muy sospechoso)
    if ((position.latitude * 10000).round() % 10000 == 0 ||
        (position.longitude * 10000).round() % 10000 == 0) {
      isAnomaly = true;
      severity = 0.9;
      description = 'Coordenadas en valores específicos (sospechoso)';
    }

    // 7. Verificar si la altitud es exactamente 0 (sospechoso)
    if (position.altitude == 0.0 && position.accuracy < 0.1) {
      isAnomaly = true;
      severity = 0.8;
      description =
          'Altitud exactamente 0 con precisión muy perfecta (sospechoso)';
    }

    // 8. Verificar si la velocidad es exactamente 0 (sospechoso)
    if (position.speed == 0.0 && position.accuracy < 0.1) {
      isAnomaly = true;
      severity = 0.7;
      description =
          'Velocidad exactamente 0 con precisión muy perfecta (sospechoso)';
    }

    return SpoofingCheck(
      type: SpoofingCheckType.consistency,
      isAnomaly: isAnomaly,
      severity: severity,
      description:
          description.isEmpty ? 'Sin anomalías inmediatas' : description,
    );
  }

  /// Verificación específica para detectar Fake GPS
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
      if (variance < 0.01) {
        // Más estricto: solo detectar varianza extremadamente baja
        isAnomaly = true;
        severity = 0.9;
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
        // Más tolerante: solo detectar saltos muy grandes
        final timeDiff =
            position.timestamp.difference(lastPosition.timestamp).inSeconds;
        if (timeDiff < 10) {
          // Más tolerante: solo detectar saltos instantáneos
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
      severity = 0.8;
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

      if (altitudeVariance < 0.1 && avgAltitude != 0) {
        // Más estricto: solo detectar altitud extremadamente constante
        isAnomaly = true;
        severity = 0.7;
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

  /// NUEVO: Método para resetear el detector (útil cuando el usuario confirma que su GPS es real)
  void resetDetector() {
    _locationHistory.clear();
  }

  /// NUEVO: Método para limpiar historial cuando se detecta GPS real
  void clearHistoryForRealGps() {
    _locationHistory.clear();
  }

  /// NUEVO: Método para verificar si el GPS es real con verificaciones específicas
  Future<bool> isGpsReal(Position position) async {
    try {
      // Verificaciones que indican GPS real
      bool isReal = true;

      // 1. Precisión realista (entre 2m y 50m) - más permisivo
      if (position.accuracy < 2.0 || position.accuracy > 50.0) {
        isReal = false;
      }

      // 2. Altitud realista (no exactamente 0 con precisión muy perfecta)
      if (position.altitude == 0.0 && position.accuracy < 0.5) {
        isReal = false;
      }

      // 3. Velocidad realista (no exactamente 0 con precisión muy perfecta)
      if (position.speed == 0.0 && position.accuracy < 0.5) {
        isReal = false;
      }

      // 4. Coordenadas no muy redondas (más permisivo)
      final latDecimal = position.latitude - position.latitude.floor();
      final lngDecimal = position.longitude - position.longitude.floor();
      if ((latDecimal < 0.0001 || latDecimal > 0.9999) &&
          (lngDecimal < 0.0001 || lngDecimal > 0.9999)) {
        isReal = false;
      }

      return isReal;
    } catch (e) {
      return false;
    }
  }

  /// NUEVO: Método para debugging - muestra información detallada de la posición
  void debugPosition(Position position) {
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    print(
      '🕐 Diferencia de tiempo: ${DateTime.now().difference(position.timestamp).abs().inMinutes} minutos',
    );

    // Análisis de coordenadas
    final lat = position.latitude;
    final lng = position.longitude;
    final latDecimal = lat - lat.floor();
    final lngDecimal = lng - lng.floor();

    // Removed debug print
    print('   Lat decimal: ${latDecimal.toStringAsFixed(6)}');
    print('   Lng decimal: ${lngDecimal.toStringAsFixed(6)}');
    print('   Lat redondeada (0.1): ${(lat * 10).round() / 10}');
    print('   Lng redondeada (0.1): ${(lng * 10).round() / 10}');
    print('   Lat redondeada (0.01): ${(lat * 100).round() / 100}');
    print('   Lng redondeada (0.01): ${(lng * 100).round() / 100}');

    // Verificaciones
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    print(
      '   Coordenadas muy redondas: ${(latDecimal < 0.001 || latDecimal > 0.999) && (lngDecimal < 0.001 || lngDecimal > 0.999)}',
    );
    print(
      '   Múltiplos de 0.1: ${(lat * 10).round() % 10 == 0 && (lng * 10).round() % 10 == 0}',
    );
    print(
      '   Múltiplos de 0.01: ${(lat * 100).round() % 100 == 0 && (lng * 100).round() % 100 == 0}',
    );
    print(
      '   Timestamp > 30min: ${DateTime.now().difference(position.timestamp).abs().inMinutes > 30}',
    );
    // Removed debug print
  }

  /// NUEVO: Método para detectar GPS real de forma muy permisiva
  Future<SpoofingDetectionResult> detectRealGpsPermissive(
    Position position,
  ) async {
    try {
      // Agregar posición actual al historial
      _addToHistory(position);

      // Verificaciones muy permisivas que solo detectan Fake GPS obvio
      final checks = <SpoofingCheck>[];

      // 1. Solo detectar precisión extremadamente perfecta (< 0.1m)
      if (position.accuracy < 0.1) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.accuracy,
            isAnomaly: true,
            severity: 0.9,
            description:
                'Precisión extremadamente perfecta: ${position.accuracy.toStringAsFixed(2)}m',
          ),
        );
      }

      // 2. Solo detectar coordenadas extremadamente redondas (múltiplos de 0.01)
      final lat = position.latitude;
      final lng = position.longitude;
      if ((lat * 100).round() % 100 == 0 && (lng * 100).round() % 100 == 0) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.consistency,
            isAnomaly: true,
            severity: 0.9,
            description:
                'Coordenadas extremadamente redondas (múltiplos de 0.01)',
          ),
        );
      }

      // 3. Solo detectar altitud exactamente 0 con precisión perfecta
      if (position.altitude == 0.0 && position.accuracy < 0.1) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.altitude,
            isAnomaly: true,
            severity: 0.8,
            description:
                'Altitud exactamente 0 con precisión extremadamente perfecta',
          ),
        );
      }

      // 4. Solo detectar velocidad exactamente 0 con precisión perfecta
      if (position.speed == 0.0 && position.accuracy < 0.1) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.speed,
            isAnomaly: true,
            severity: 0.8,
            description:
                'Velocidad exactamente 0 con precisión extremadamente perfecta',
          ),
        );
      }

      // 5. Solo detectar timestamp muy antiguo (> 30 minutos)
      final now = DateTime.now();
      final timeDiff = now.difference(position.timestamp).abs();
      if (timeDiff.inMinutes > 30) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.timestamp,
            isAnomaly: true,
            severity: 0.7,
            description: 'Timestamp muy antiguo: ${timeDiff.inMinutes} minutos',
          ),
        );
      }

      // Calcular riesgo con umbral muy alto
      final riskScore =
          checks.isNotEmpty
              ? checks.map((c) => c.severity).reduce((a, b) => a + b) /
                  checks.length
              : 0.0;

      // Umbral muy alto (0.9) - solo detectar Fake GPS muy obvio
      final isSpoofed = riskScore >= 0.9;

      final result = SpoofingDetectionResult(
        isSpoofed: isSpoofed,
        riskScore: riskScore,
        confidence: checks.length / 5.0,
        detectedIssues: checks.where((check) => check.isAnomaly).toList(),
        recommendations: _generateRecommendations(checks),
      );

      // Removed debug print
      print(
        '[GpsSpoofingDetector] 🎯 Riesgo permisivo: ${(riskScore * 100).toStringAsFixed(1)}%',
      );

      return result;
    } catch (e) {
      return SpoofingDetectionResult(
        isSpoofed: false,
        riskScore: 0.0,
        confidence: 0.0,
        detectedIssues: [],
        recommendations: ['Error en detección permisiva: $e'],
      );
    }
  }

  /// NUEVO: Detector mejorado usando APIs nativas de Android - más preciso y confiable
  Future<SpoofingDetectionResult> detectWithNativeLibrary(
    Position position,
  ) async {
    try {
      // Removed debug print

      // Verificar si estamos en Android
      if (Platform.isAndroid) {
        // Usar APIs nativas de Android para detectar Fake GPS
        final isDeveloperMode = await _checkDeveloperMode();
        final hasMockLocationPermission = await _checkMockLocationPermission();

        // Removed debug print
        // Removed debug print

        // NUEVA: Verificar patrones de comportamiento
        final isFakeGpsByPatterns = await _detectFakeGpsByPatterns(position);

        if (isDeveloperMode && hasMockLocationPermission) {
          // Fake GPS detectado por APIs nativas
          final result = SpoofingDetectionResult(
            isSpoofed: true,
            riskScore: 0.95, // Muy alta confianza
            confidence: 0.95,
            detectedIssues: [
              SpoofingCheck(
                type: SpoofingCheckType.consistency,
                isAnomaly: true,
                severity: 0.95,
                description: 'Fake GPS detectado por APIs nativas de Android',
              ),
            ],
            recommendations: [
              'Se detectó Fake GPS usando APIs nativas de Android',
              'Modo desarrollador habilitado con permisos de mock location',
              'Desactiva las apps de Fake GPS',
              'Verifica los permisos de ubicación',
            ],
          );

          // Removed debug print
          return result;
        } else if (isFakeGpsByPatterns) {
          // Fake GPS detectado por patrones de comportamiento
          final result = SpoofingDetectionResult(
            isSpoofed: true,
            riskScore: 0.85, // Alta confianza
            confidence: 0.85,
            detectedIssues: [
              SpoofingCheck(
                type: SpoofingCheckType.consistency,
                isAnomaly: true,
                severity: 0.85,
                description:
                    'Fake GPS detectado por patrones de comportamiento',
              ),
            ],
            recommendations: [
              'Se detectó Fake GPS usando análisis de patrones',
              'Patrones sospechosos detectados en la ubicación',
              'Desactiva las apps de Fake GPS',
              'Verifica los permisos de ubicación',
            ],
          );

          // Removed debug print
          return result;
        } else {
          // GPS parece ser real según las APIs nativas
          final result = SpoofingDetectionResult(
            isSpoofed: false,
            riskScore: 0.05, // Muy baja confianza
            confidence: 0.95,
            detectedIssues: [],
            recommendations: [
              'GPS parece ser real según APIs nativas de Android',
              'Modo desarrollador deshabilitado o sin permisos de mock location',
            ],
          );

          // Removed debug print
          return result;
        }
      } else {
        // En iOS, usar detección personalizada
        // Removed debug print
        return await detectSpoofingBalanced(position);
      }
    } catch (e) {
      // Removed debug print

      // Fallback a detección personalizada si las APIs fallan
      return await detectSpoofingBalanced(position);
    }
  }

  /// NUEVO: Detector equilibrado - detecta Fake GPS real pero es menos propenso a falsos positivos
  Future<SpoofingDetectionResult> detectSpoofingBalanced(
    Position position,
  ) async {
    try {
      // Agregar posición actual al historial
      _addToHistory(position);

      // Verificaciones equilibradas
      final checks = <SpoofingCheck>[];

      // 1. Precisión sospechosamente perfecta (más permisivo que antes pero menos que el permisivo)
      if (position.accuracy < 3.0) {
        // Más permisivo - detecta precisión sospechosa
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.accuracy,
            isAnomaly: true,
            severity: 0.6,
            description:
                'Precisión sospechosamente perfecta: ${position.accuracy.toStringAsFixed(1)}m',
          ),
        );
      }

      // 1.5. Verificar si la precisión es sospechosamente perfecta para Fake GPS
      if (position.accuracy < 6.0 && position.accuracy > 4.0) {
        // Rango sospechoso para Fake GPS (entre 4-6m)
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.accuracy,
            isAnomaly: true,
            severity: 0.8,
            description:
                'Precisión en rango sospechoso de Fake GPS: ${position.accuracy.toStringAsFixed(1)}m',
          ),
        );
      }

      // 1.6. Verificar si la precisión es sospechosamente perfecta para Fake GPS (rango más amplio)
      if (position.accuracy < 8.0 && position.accuracy > 3.0) {
        // Rango más amplio sospechoso para Fake GPS (entre 3-8m)
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.accuracy,
            isAnomaly: true,
            severity: 0.7,
            description:
                'Precisión en rango amplio sospechoso de Fake GPS: ${position.accuracy.toStringAsFixed(1)}m',
          ),
        );
      }

      // 1.7. Verificar si la precisión es sospechosamente perfecta para Fake GPS estático
      if (position.accuracy < 6.0 &&
          position.accuracy > 3.0 &&
          position.speed == 0.0) {
        // Rango sospechoso para Fake GPS estático (entre 3-6m con velocidad 0)
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.accuracy,
            isAnomaly: true,
            severity: 0.8,
            description:
                'Precisión sospechosa para Fake GPS estático: ${position.accuracy.toStringAsFixed(1)}m',
          ),
        );
      }

      // 2. Coordenadas redondas (más permisivo que antes)
      final lat = position.latitude;
      final lng = position.longitude;
      final latDecimal = lat - lat.floor();
      final lngDecimal = lng - lng.floor();

      // Detectar coordenadas redondas (múltiplos de 0.1)
      if ((lat * 10).round() % 10 == 0 && (lng * 10).round() % 10 == 0) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.consistency,
            isAnomaly: true,
            severity: 0.8,
            description: 'Coordenadas redondas (múltiplos de 0.1)',
          ),
        );
      }

      // 3. Altitud sospechosa
      if (position.altitude == 0.0 && position.accuracy < 1.0) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.altitude,
            isAnomaly: true,
            severity: 0.6,
            description: 'Altitud exactamente 0 con precisión sospechosa',
          ),
        );
      }

      // 4. Velocidad sospechosa
      if (position.speed == 0.0 && position.accuracy < 1.0) {
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.speed,
            isAnomaly: true,
            severity: 0.6,
            description: 'Velocidad exactamente 0 con precisión sospechosa',
          ),
        );
      }

      // 5. Timestamp sospechoso
      final now = DateTime.now();
      final timeDiff = now.difference(position.timestamp).abs();
      if (timeDiff.inMinutes > 15) {
        // Entre 10 y 15 minutos
        checks.add(
          SpoofingCheck(
            type: SpoofingCheckType.timestamp,
            isAnomaly: true,
            severity: 0.5,
            description: 'Timestamp sospechoso: ${timeDiff.inMinutes} minutos',
          ),
        );
      }

      // 6. Verificar si la precisión es sospechosamente constante
      if (_locationHistory.isNotEmpty) {
        final lastAccuracy = _locationHistory.last.accuracy;
        if ((position.accuracy - lastAccuracy).abs() < 0.5) {
          // Precisión muy similar
          checks.add(
            SpoofingCheck(
              type: SpoofingCheckType.accuracy,
              isAnomaly: true,
              severity: 0.6,
              description: 'Precisión sospechosamente constante',
            ),
          );
        }
      }

      // 6.5. Verificar si la velocidad es sospechosamente constante
      if (_locationHistory.isNotEmpty) {
        final lastSpeed = _locationHistory.last.speed;
        if ((position.speed - lastSpeed).abs() < 0.1) {
          // Velocidad muy similar - solo detectar si también tiene precisión sospechosa
          if (position.accuracy < 10.0) {
            // Solo detectar como Fake GPS si la precisión es sospechosamente perfecta
            if (position.accuracy < 8.0) {
              checks.add(
                SpoofingCheck(
                  type: SpoofingCheckType.speed,
                  isAnomaly: true,
                  severity: 0.5,
                  description: 'Velocidad sospechosamente constante',
                ),
              );
            }
          }
        }
      }

      // 6.6. Verificar si las coordenadas son sospechosamente similares (Fake GPS estático)
      if (_locationHistory.isNotEmpty) {
        final lastPosition = _locationHistory.last;
        final latDiff = (position.latitude - lastPosition.latitude).abs();
        final lngDiff = (position.longitude - lastPosition.longitude).abs();

        // Si las coordenadas son muy similares (Fake GPS estático)
        if (latDiff < 0.0001 && lngDiff < 0.0001) {
          // Solo detectar como Fake GPS si también tiene precisión sospechosa
          if (position.accuracy < 8.0) {
            checks.add(
              SpoofingCheck(
                type: SpoofingCheckType.consistency,
                isAnomaly: true,
                severity: 0.7,
                description: 'Coordenadas sospechosamente estáticas (Fake GPS)',
              ),
            );
          }
        }
      }

      // 6.7. Verificar si la precisión es sospechosamente constante (Fake GPS estático)
      if (_locationHistory.isNotEmpty) {
        final lastAccuracy = _locationHistory.last.accuracy;
        if ((position.accuracy - lastAccuracy).abs() < 0.5) {
          // Precisión muy similar - solo detectar si es sospechosamente perfecta
          if (position.accuracy < 8.0) {
            checks.add(
              SpoofingCheck(
                type: SpoofingCheckType.accuracy,
                isAnomaly: true,
                severity: 0.6,
                description: 'Precisión sospechosamente constante',
              ),
            );
          }
        }
      }

      // 7. Verificar saltos de ubicación sospechosos
      if (_locationHistory.isNotEmpty) {
        final lastPosition = _locationHistory.last;
        final distance = Geolocator.distanceBetween(
          lastPosition.latitude,
          lastPosition.longitude,
          position.latitude,
          position.longitude,
        );

        print(
          '[GpsSpoofingDetector] 📍 Distancia desde última posición: ${distance.toInt()}m',
        );

        // Si hay un salto grande en poco tiempo
        if (distance > 1000) {
          // Más de 1km
          final timeDiff =
              position.timestamp.difference(lastPosition.timestamp).inSeconds;
          // Removed debug print

          if (timeDiff < 60) {
            // Menos de 1 minuto
            checks.add(
              SpoofingCheck(
                type: SpoofingCheckType.consistency,
                isAnomaly: true,
                severity: 0.9,
                description:
                    'Salto de ubicación sospechoso: ${distance.toInt()}m en ${timeDiff}s',
              ),
            );
            print(
              '[GpsSpoofingDetector] 🚨 SALTO SOSPECHOSO DETECTADO: ${distance.toInt()}m en ${timeDiff}s',
            );
          }
        }
      }

      // Calcular riesgo con umbral equilibrado
      final riskScore =
          checks.isNotEmpty
              ? checks.map((c) => c.severity).reduce((a, b) => a + b) /
                  checks.length
              : 0.0;

      // Umbral muy sensible (0.5) - detecta Fake GPS más fácilmente
      final isSpoofed = riskScore >= 0.5;

      final result = SpoofingDetectionResult(
        isSpoofed: isSpoofed,
        riskScore: riskScore,
        confidence: checks.length / 7.0,
        detectedIssues: checks.where((check) => check.isAnomaly).toList(),
        recommendations: _generateRecommendations(checks),
      );

      // Removed debug print
      print(
        '[GpsSpoofingDetector] 🎯 Riesgo equilibrado: ${(riskScore * 100).toStringAsFixed(1)}%',
      );

      // Logs detallados para debugging
      if (checks.isNotEmpty) {
        // Removed debug print
        for (final check in checks) {
          print(
            '[GpsSpoofingDetector]   - ${check.description} (severidad: ${(check.severity * 100).toStringAsFixed(1)}%)',
          );
        }
      }

      return result;
    } catch (e) {
      return SpoofingDetectionResult(
        isSpoofed: false,
        riskScore: 0.0,
        confidence: 0.0,
        detectedIssues: [],
        recommendations: ['Error en detección equilibrada: $e'],
      );
    }
  }

  /// NUEVO: Verificación nativa usando propiedades de Position
  Future<SpoofingCheck> _checkNativeSpoofing(Position position) async {
    try {
      bool isAnomaly = false;
      double severity = 0.0;
      String description = '';

      // 1. Verificar timestamp sospechoso (más estricto)
      final now = DateTime.now();
      final timeDiff = now.difference(position.timestamp).abs();
      if (timeDiff.inMinutes > 5) {
        isAnomaly = true;
        severity = 0.8;
        description = 'Timestamp muy antiguo: ${timeDiff.inMinutes} minutos';
        // Removed debug print
      }

      // 2. Verificar si está en modo de desarrollador (Android)
      if (Platform.isAndroid) {
        try {
          // Verificar si las opciones de desarrollador están habilitadas
          final isDeveloperMode = await _checkDeveloperMode();
          if (isDeveloperMode) {
            // Verificar si "Allow mock locations" está habilitado
            final hasMockLocationPermission =
                await _checkMockLocationPermission();
            if (hasMockLocationPermission) {
              isAnomaly = true;
              severity = 0.9;
              description =
                  'Permisos de mock location habilitados en modo desarrollador';
              // Removed debug print
            }
          }
        } catch (e) {
          // Removed debug print
        }
      }

      // 3. Verificar precisión sospechosamente perfecta (más sensible)
      if (position.accuracy < 0.5) {
        // Más sensible a precisión perfecta
        isAnomaly = true;
        severity = 0.9;
        description =
            'Precisión sospechosamente perfecta: ${position.accuracy.toStringAsFixed(2)}m';
        print(
          '[GpsSpoofingDetector] 🚨 PRECISIÓN SOSPECHOSAMENTE PERFECTA: ${position.accuracy.toStringAsFixed(2)}m',
        );
      }

      // 4. Verificar si la velocidad es exactamente 0 con precisión perfecta
      if (position.speed == 0.0 && position.accuracy < 0.5) {
        isAnomaly = true;
        severity = 0.8;
        description =
            'Velocidad exactamente 0 con precisión perfecta (sospechoso)';
        // Removed debug print
      }

      // 5. Verificar si la altitud es exactamente 0 con precisión perfecta
      if (position.altitude == 0.0 && position.accuracy < 0.5) {
        isAnomaly = true;
        severity = 0.8;
        description =
            'Altitud exactamente 0 con precisión perfecta (sospechoso)';
        // Removed debug print
      }

      // 6. Verificar coordenadas "redondas" (típicas de Fake GPS)
      final lat = position.latitude;
      final lng = position.longitude;

      // Verificar si las coordenadas son muy "redondas" (múltiplos de 0.1, 0.01, etc.)
      final latRounded = (lat * 10).round() / 10;
      final lngRounded = (lng * 10).round() / 10;

      if ((lat - latRounded).abs() < 0.001 &&
          (lng - lngRounded).abs() < 0.001) {
        isAnomaly = true;
        severity = 0.7;
        description = 'Coordenadas sospechosamente redondas (Fake GPS típico)';
        // Removed debug print
      }

      // 7. Verificar si la velocidad es constante (típico de Fake GPS)
      if (_locationHistory.isNotEmpty) {
        final lastPosition = _locationHistory.last;
        if (position.speed == lastPosition.speed &&
            position.speed > 0 &&
            position.speed < 0.1) {
          // Velocidad muy baja y constante
          isAnomaly = true;
          severity = 0.6;
          description = 'Velocidad sospechosamente constante (Fake GPS)';
          // Removed debug print
        }
      }

      return SpoofingCheck(
        type: SpoofingCheckType.provider,
        isAnomaly: isAnomaly,
        severity: severity,
        description:
            description.isEmpty ? 'Sin anomalías nativas' : description,
      );
    } catch (e) {
      // Removed debug print
      return SpoofingCheck(
        type: SpoofingCheckType.provider,
        isAnomaly: false,
        severity: 0.0,
        description: 'Error en verificación nativa: $e',
      );
    }
  }

  /// Verificar si el modo desarrollador está habilitado (Android)
  Future<bool> _checkDeveloperMode() async {
    try {
      if (Platform.isAndroid) {
        // Verificar si las opciones de desarrollador están habilitadas
        // Esto es una aproximación ya que no podemos acceder directamente a Settings.Secure
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // Verificar características que indican modo desarrollador
        final hasDeveloperFeatures =
            androidInfo.brand.toLowerCase().contains('google') ||
            androidInfo.model.toLowerCase().contains('sdk') ||
            androidInfo.model.toLowerCase().contains('pixel') ||
            androidInfo.isPhysicalDevice == false; // Emulador

        // Removed debug print
        // Removed debug print
        // Removed debug print
        // Removed debug print
        // Removed debug print

        return hasDeveloperFeatures;
      }
      return false;
    } catch (e) {
      // Removed debug print
      return false;
    }
  }

  /// Verificar si los permisos de mock location están habilitados (Android)
  Future<bool> _checkMockLocationPermission() async {
    try {
      if (Platform.isAndroid) {
        // Verificar si hay apps de mock location instaladas
        // Esto es una aproximación ya que no podemos acceder directamente a los permisos
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // Verificar características que indican mock location
        final hasMockLocationFeatures =
            androidInfo.supportedAbis.contains('x86') ||
            androidInfo.supportedAbis.contains('x86_64') ||
            androidInfo.brand.toLowerCase().contains('google') ||
            androidInfo.model.toLowerCase().contains('sdk') ||
            androidInfo.isPhysicalDevice == false; // Emulador

        // Removed debug print
        // Removed debug print
        // Removed debug print

        return hasMockLocationFeatures;
      }
      return false;
    } catch (e) {
      // Removed debug print
      return false;
    }
  }

  /// NUEVA: Detectar Fake GPS basado en patrones de comportamiento
  Future<bool> _detectFakeGpsByPatterns(Position position) async {
    try {
      // Patrones específicos de Fake GPS que veo en tus logs
      bool isFakeGps = false;
      String detectedPattern = '';

      // 1. Patrón: Coordenadas que cambian entre dos ubicaciones fijas
      if (_locationHistory.isNotEmpty) {
        final lastPosition = _locationHistory.last;
        final latDiff = (position.latitude - lastPosition.latitude).abs();
        final lngDiff = (position.longitude - lastPosition.longitude).abs();

        // Si las coordenadas son muy similares (Fake GPS estático)
        if (latDiff < 0.0001 && lngDiff < 0.0001) {
          // Verificar si la precisión es sospechosamente constante
          if (position.accuracy < 10.0 && position.accuracy > 3.0) {
            isFakeGps = true;
            detectedPattern = 'Coordenadas estáticas con precisión sospechosa';
          }
        }
      }

      // 2. Patrón: Precisión en rango sospechoso de Fake GPS
      if (position.accuracy >= 3.0 && position.accuracy <= 8.0) {
        // Rango típico de Fake GPS apps
        if (position.speed < 1.0) {
          // Velocidad baja o nula
          isFakeGps = true;
          detectedPattern = 'Precisión en rango sospechoso de Fake GPS';
        }
      }

      // 3. Patrón: Saltos de ubicación imposibles
      if (_locationHistory.isNotEmpty) {
        final lastPosition = _locationHistory.last;
        final distance = Geolocator.distanceBetween(
          lastPosition.latitude,
          lastPosition.longitude,
          position.latitude,
          position.longitude,
        );
        final timeDiff =
            position.timestamp.difference(lastPosition.timestamp).inSeconds;

        // Si hay un salto muy grande en poco tiempo
        if (distance > 1000 && timeDiff < 60) {
          isFakeGps = true;
          detectedPattern =
              'Salto de ubicación imposible: ${distance.toStringAsFixed(0)}m en ${timeDiff}s';
        }
      }

      // 4. Patrón: Coordenadas que alternan entre dos ubicaciones específicas
      if (_locationHistory.length >= 3) {
        final uniqueLocations = <String>{};
        final lastThree =
            _locationHistory.skip(_locationHistory.length - 3).toList();
        for (final pos in lastThree) {
          uniqueLocations.add(
            '${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}',
          );
        }

        if (uniqueLocations.length == 2) {
          // Solo dos ubicaciones únicas en las últimas 3 lecturas
          isFakeGps = true;
          detectedPattern = 'Alternancia entre dos ubicaciones fijas';
        }
      }

      if (isFakeGps) {
        // Removed debug print
      }

      return isFakeGps;
    } catch (e) {
      // Removed debug print
      return false;
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
    return 'BAJO';
  }

  Color get riskColor {
    if (riskScore >= 0.8) return Colors.red;
    if (riskScore >= 0.6) return Colors.orange;
    if (riskScore >= 0.4) return Colors.yellow;
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
