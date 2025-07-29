import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/core/services/firebase/notification_service.dart';
import 'package:safy/core/services/vibration_service.dart';
import 'package:safy/home/presentation/widgets/danger_zone_alert_widget.dart';
import 'dart:async';
import 'dart:math';

/// Servicio para detectar cuando el usuario entra en clusters de zonas peligrosas
class ClusterDetectionService {
  static final ClusterDetectionService _instance =
      ClusterDetectionService._internal();
  factory ClusterDetectionService() => _instance;
  ClusterDetectionService._internal();

  final NotificationService _notificationService = NotificationService();
  final VibrationService _vibrationService = VibrationService();

  // Estado del servicio
  bool _isActive = false;
  bool get isActive => _isActive;

  // Callback para mostrar el widget de alerta
  Function(ClusterEntity, double)? _showAlertCallback;

  // Historial de clusters visitados para evitar notificaciones repetidas
  final Set<String> _visitedClusters = {};
  final Map<String, DateTime> _lastAlertTime = {};

  // Configuración
  static const Duration _alertCooldown = Duration(minutes: 2);
  static const double _dangerZoneRadius =
      150.0; // metros - Reducido para ser más preciso
  static const double _warningZoneRadius =
      300.0; // metros - Reducido para ser más preciso

  /// Inicializar el servicio
  Future<void> init() async {
    await _vibrationService.init();
    _isActive = true;

    // Test del cálculo de distancia
    final testPoint1 = LatLng(0.0, 0.0);
    final testPoint2 = LatLng(0.001, 0.001); // Aproximadamente 111 metros
    final testDistance = _calculateDistance(testPoint1, testPoint2);
    print(
      '[ClusterDetectionService] 🧪 Test distancia: ${testDistance.toStringAsFixed(1)}m (esperado ~111m)',
    );

    // Removed debug print
  }

  /// Configurar callback para mostrar alertas
  void setAlertCallback(Function(ClusterEntity, double) callback) {
    _showAlertCallback = callback;
  }

  /// Verificar si la ubicación actual está en una zona peligrosa
  void checkLocationInDangerZone(
    LatLng currentLocation,
    List<ClusterEntity> clusters,
  ) {
    if (!_isActive || clusters.isEmpty) return;

    for (final cluster in clusters) {
      final clusterLocation = LatLng(
        cluster.centerLatitude,
        cluster.centerLongitude,
      );

      final distance = _calculateDistance(currentLocation, clusterLocation);
      final clusterId = cluster.clusterId;

      // Debug: Mostrar información de distancia
      print(
        '[ClusterDetectionService] 📍 Cluster: ${cluster.clusterId} - Distancia calculada: ${distance.toStringAsFixed(1)}m',
      );
      print(
        '[ClusterDetectionService] 📍 Tu ubicación: (${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)})',
      );
      print(
        '[ClusterDetectionService] 📍 Centro del cluster: (${clusterLocation.latitude.toStringAsFixed(6)}, ${clusterLocation.longitude.toStringAsFixed(6)})',
      );

      // Verificar si está dentro del radio de peligro
      if (distance <= _dangerZoneRadius) {
        _handleDangerZoneEntry(cluster, distance);
      }
      // Verificar si está en zona de advertencia
      else if (distance <= _warningZoneRadius) {
        _handleWarningZoneEntry(cluster, distance);
      }
      // Si está fuera de ambas zonas, remover del historial
      else {
        _visitedClusters.remove(clusterId);
      }
    }
  }

  /// Manejar entrada en zona de peligro
  void _handleDangerZoneEntry(ClusterEntity cluster, double distance) {
    final clusterId = cluster.clusterId;
    final now = DateTime.now();

    // Verificar cooldown
    if (_lastAlertTime.containsKey(clusterId)) {
      final timeSinceLastAlert = now.difference(_lastAlertTime[clusterId]!);
      if (timeSinceLastAlert < _alertCooldown) {
        return; // Aún en cooldown
      }
    }

    // Verificar si ya fue notificado
    if (_visitedClusters.contains(clusterId)) {
      return; // Ya fue notificado
    }

    // Marcar como visitado
    _visitedClusters.add(clusterId);
    _lastAlertTime[clusterId] = now;

    // Determinar severidad del cluster
    final severity = cluster.severityNumber ?? 1;
    final reportCount = cluster.reportCount;
    final incidentType = cluster.dominantIncidentName;

    // Mostrar alerta con vibración
    _showDangerZoneAlert(
      cluster,
      distance,
      severity,
      reportCount,
      incidentType,
    );

    // Mostrar widget de alerta si hay callback configurado
    if (_showAlertCallback != null) {
      _showAlertCallback!(cluster, distance);
    }

    // Removed debug print
    print(
      '[ClusterDetectionService] 📍 Distancia: ${distance.toStringAsFixed(0)}m (Radio de detección: ${_dangerZoneRadius.toInt()}m)',
    );
    // Removed debug print
    print(
      '[ClusterDetectionService] 🎯 Radio visual del cluster: ${cluster.calculatedRadius.toStringAsFixed(0)}m',
    );
  }

  /// Manejar entrada en zona de advertencia
  void _handleWarningZoneEntry(ClusterEntity cluster, double distance) {
    final clusterId = cluster.clusterId;
    final now = DateTime.now();

    // Verificar cooldown para advertencias
    if (_lastAlertTime.containsKey('warning_$clusterId')) {
      final timeSinceLastAlert = now.difference(
        _lastAlertTime['warning_$clusterId']!,
      );
      if (timeSinceLastAlert < _alertCooldown) {
        return;
      }
    }

    final severity = cluster.severityNumber ?? 1;

    // Solo mostrar advertencia para clusters de severidad alta
    if (severity >= 3) {
      _lastAlertTime['warning_$clusterId'] = now;
      _showWarningZoneAlert(cluster, distance);

      // Removed debug print
      print(
        '[ClusterDetectionService] 📍 Distancia: ${distance.toStringAsFixed(0)}m',
      );
    }
  }

  /// Mostrar alerta de zona peligrosa
  void _showDangerZoneAlert(
    ClusterEntity cluster,
    double distance,
    int severity,
    int reportCount,
    String incidentType,
  ) {
    // Vibración de alerta
    _vibrationService.dangerZoneAlert();

    // Determinar color y mensaje según severidad
    Color alertColor;
    String severityText;
    String message;

    if (severity >= 5) {
      alertColor = Colors.red[700]!;
      severityText = 'CRÍTICA';
      message =
          '¡ZONA DE ALTO RIESGO! Estás en una zona con múltiples incidentes críticos.';
    } else if (severity >= 4) {
      alertColor = Colors.red[500]!;
      severityText = 'ALTA';
      message =
          'Zona de alto riesgo detectada. Mantente alerta y considera cambiar de ruta.';
    } else {
      alertColor = Colors.orange[600]!;
      severityText = 'MEDIA';
      message = 'Zona con reportes recientes. Ten precaución.';
    }

    // Mostrar notificación
    _notificationService.showDangerZoneNotification(
      title: '🚨 ZONA PELIGROSA DETECTADA',
      body:
          '$message\n\nDistancia: ${distance.toStringAsFixed(0)}m\nRadio de detección: ${_dangerZoneRadius.toInt()}m\nSeveridad: $severityText\nReportes: $reportCount',
    );

    // Removed debug print
  }

  /// Mostrar alerta de zona de advertencia
  void _showWarningZoneAlert(ClusterEntity cluster, double distance) {
    // Vibración de notificación
    _vibrationService.notificationVibrate();

    // Notificación de advertencia
    _notificationService.showDangerZoneNotification(
      title: '⚠️ Zona Peligrosa Cercana',
      body:
          'Estás acercándote a una zona con reportes recientes.\n\nDistancia: ${distance.toStringAsFixed(0)}m',
    );

    // Removed debug print
  }

  /// Calcular distancia entre dos puntos usando la fórmula de Haversine
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros

    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Limpiar historial de clusters visitados
  void clearHistory() {
    _visitedClusters.clear();
    _lastAlertTime.clear();
    // Removed debug print
  }

  /// Detener el servicio
  void stop() {
    _isActive = false;
    clearHistory();
    // Removed debug print
  }

  /// Obtener estadísticas del servicio
  Map<String, dynamic> getStats() {
    return {
      'isActive': _isActive,
      'visitedClusters': _visitedClusters.length,
      'lastAlertTime': _lastAlertTime.length,
      'hasVibrator': _vibrationService.hasVibrator,
      'dangerZoneRadius': _dangerZoneRadius,
      'warningZoneRadius': _warningZoneRadius,
    };
  }

  /// Obtener radio de detección de zona peligrosa
  double get dangerZoneRadius => _dangerZoneRadius;

  /// Obtener radio de advertencia
  double get warningZoneRadius => _warningZoneRadius;
}
