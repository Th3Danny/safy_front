import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:safy/core/services/cluster_detection_service.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';

/// Servicio dedicado para tracking de ubicación en hilo separado
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  // Configuración de tracking
  static const double _minDistanceFilter =
      5.0; // 5 metros - balance entre precisión y estabilidad
  static const double _highAccuracyDistanceFilter =
      2.0; // 2 metros - máxima precisión
  static const Duration _updateInterval = Duration(
    seconds: 5,
  ); // Actualizar cada 5 segundos máximo

  // Estado del servicio
  bool _isActive = false;
  bool get isActive => _isActive;

  // Stream de ubicación
  StreamSubscription<Position>? _positionStream;
  LatLng? _lastKnownLocation;
  DateTime? _lastUpdateTime;

  // Callbacks
  Function(LatLng)? _onLocationUpdate;
  Function(LatLng, double)? _onSignificantMovement;
  Function(String)? _onError;
  Function()? _getClustersCallback; // Callback para obtener clusters

  // Servicio de detección de clusters
  final ClusterDetectionService _clusterDetectionService =
      ClusterDetectionService();

  // Estadísticas
  int _totalUpdates = 0;
  double _totalDistanceMoved = 0.0;
  DateTime? _startTime;

  /// Inicializar el servicio
  Future<void> init() async {
    if (_isActive) return;

    try {
      // Verificar permisos
      await _checkLocationPermissions();

      // Inicializar servicio de clusters
      await _clusterDetectionService.init();

      _isActive = true;
      _startTime = DateTime.now();

      print('[LocationTrackingService] 🚀 Servicio de tracking iniciado');
      print(
        '[LocationTrackingService] 📏 Distancia mínima: ${_minDistanceFilter}m',
      );
      print(
        '[LocationTrackingService] ⏱️ Intervalo máximo: ${_updateInterval.inSeconds}s',
      );
    } catch (e) {
      print('[LocationTrackingService] ❌ Error inicializando: $e');
      rethrow;
    }
  }

  /// Verificar permisos de ubicación
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están desactivados.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permiso de ubicación denegado.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permisos de ubicación permanentemente denegados.';
    }
  }

  /// Iniciar tracking de ubicación
  void startTracking({
    Function(LatLng)? onLocationUpdate,
    Function(LatLng, double)? onSignificantMovement,
    Function(String)? onError,
    Function()? getClustersCallback,
  }) {
    if (!_isActive) {
      print('[LocationTrackingService] ❌ Servicio no inicializado');
      return;
    }

    // Configurar callbacks
    _onLocationUpdate = onLocationUpdate;
    _onSignificantMovement = onSignificantMovement;
    _onError = onError;
    _getClustersCallback = getClustersCallback;

    // Configuración balanceada entre precisión y estabilidad
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Alta precisión pero más estable
      distanceFilter: _minDistanceFilter.toInt(), // 5 metros
      timeLimit: _updateInterval, // Máximo 5 segundos entre actualizaciones
    );

    // Verificar si el GPS está disponible antes de iniciar
    _checkGpsAvailability().then((isAvailable) {
      if (isAvailable) {
        _startPositionStream(locationSettings);
      } else {
        print(
          '[LocationTrackingService] ⚠️ GPS no disponible, usando configuración conservadora',
        );
        _startPositionStream(_getConservativeSettings());
      }
    });
  }

  /// Verificar disponibilidad del GPS
  Future<bool> _checkGpsAvailability() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 3),
      );
      return position != null;
    } catch (e) {
      print('[LocationTrackingService] ⚠️ GPS lento o no disponible: $e');
      return false;
    }
  }

  /// Configuración conservadora para GPS lento
  LocationSettings _getConservativeSettings() {
    return LocationSettings(
      accuracy: LocationAccuracy.medium, // Precisión media
      distanceFilter: 10, // 10 metros
      timeLimit: Duration(seconds: 10), // 10 segundos máximo
    );
  }

  /// Iniciar stream de posición
  void _startPositionStream(LocationSettings settings) {
    print('[LocationTrackingService] 📡 Iniciando stream de ubicación...');

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _handlePositionUpdate,
      onError: (error) {
        print('[LocationTrackingService] ❌ Error en stream: $error');

        // Manejar timeouts específicamente
        if (error.toString().contains('TimeoutException')) {
          print(
            '[LocationTrackingService] ⏰ Timeout detectado, reintentando en 3 segundos...',
          );

          // Reintentar después de 3 segundos
          Future.delayed(Duration(seconds: 3), () {
            if (_isActive && _positionStream == null) {
              print(
                '[LocationTrackingService] 🔄 Reintentando conexión GPS...',
              );
              startTracking(
                onLocationUpdate: _onLocationUpdate,
                onSignificantMovement: _onSignificantMovement,
                onError: _onError,
                getClustersCallback: _getClustersCallback,
              );
            }
          });
        }

        _onError?.call(error.toString());
      },
    );

    print('[LocationTrackingService] ✅ Tracking iniciado con alta precisión');
  }

  /// Manejar actualización de posición
  void _handlePositionUpdate(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    // Calcular distancia movida
    double distanceMoved = 0.0;
    if (_lastKnownLocation != null) {
      distanceMoved = _calculateDistance(_lastKnownLocation!, newLocation);
      _totalDistanceMoved += distanceMoved;
    }

    // Actualizar estadísticas
    _totalUpdates++;
    _lastKnownLocation = newLocation;
    _lastUpdateTime = now;

    // Debug: Información detallada
    print(
      '[LocationTrackingService] 📍 Actualización #$_totalUpdates: (${newLocation.latitude.toStringAsFixed(6)}, ${newLocation.longitude.toStringAsFixed(6)})',
    );
    print(
      '[LocationTrackingService] 📏 Distancia movida: ${distanceMoved.toStringAsFixed(1)}m (Total: ${_totalDistanceMoved.toStringAsFixed(1)}m)',
    );

    // Verificar movimiento significativo (más de 10 metros)
    if (distanceMoved > 10.0) {
      print(
        '[LocationTrackingService] 🚶 Movimiento significativo: ${distanceMoved.toStringAsFixed(1)}m',
      );
      _onSignificantMovement?.call(newLocation, distanceMoved);
    }

    // Callback de actualización
    _onLocationUpdate?.call(newLocation);

    // Verificar clusters de zonas peligrosas
    _checkClustersForDangerZones(newLocation);
  }

  /// Verificar clusters de zonas peligrosas
  void _checkClustersForDangerZones(LatLng currentLocation) {
    // Obtener clusters del ViewModel (se implementará)
    final clusters = getCurrentClusters();

    if (clusters.isNotEmpty) {
      _clusterDetectionService.checkLocationInDangerZone(
        currentLocation,
        clusters,
      );
    }
  }

  /// Obtener clusters actuales usando callback
  List<ClusterEntity> getCurrentClusters() {
    try {
      if (_getClustersCallback != null) {
        final clusters = _getClustersCallback!();
        return clusters is List<ClusterEntity> ? clusters : [];
      }
      print('[LocationTrackingService] ⚠️ Callback de clusters no configurado');
      return [];
    } catch (e) {
      print('[LocationTrackingService] ⚠️ Error obteniendo clusters: $e');
      return [];
    }
  }

  /// Calcular distancia entre dos puntos usando Haversine
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

  /// Detener tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isActive = false;

    print('[LocationTrackingService] ⏹️ Tracking detenido');
  }

  /// Obtener estadísticas del servicio
  Map<String, dynamic> getStats() {
    final duration =
        _startTime != null
            ? DateTime.now().difference(_startTime!)
            : Duration.zero;

    return {
      'isActive': _isActive,
      'totalUpdates': _totalUpdates,
      'totalDistanceMoved': _totalDistanceMoved,
      'duration': duration.inSeconds,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'lastKnownLocation':
          _lastKnownLocation != null
              ? '(${_lastKnownLocation!.latitude.toStringAsFixed(6)}, ${_lastKnownLocation!.longitude.toStringAsFixed(6)})'
              : null,
      'averageUpdateInterval':
          _totalUpdates > 0
              ? (duration.inSeconds / _totalUpdates).toStringAsFixed(1)
              : '0',
    };
  }

  /// Obtener ubicación actual
  LatLng? get currentLocation => _lastKnownLocation;

  /// Verificar si el servicio está funcionando
  bool get isTracking => _positionStream != null && _isActive;
}
