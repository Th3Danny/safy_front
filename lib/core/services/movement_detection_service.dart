import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math';

/// Servicio para detectar cambios de estado de movimiento del usuario
class MovementDetectionService {
  static final MovementDetectionService _instance =
      MovementDetectionService._internal();
  factory MovementDetectionService() => _instance;
  MovementDetectionService._internal();

  // Configuración de detección
  static const double _movementThreshold =
      10.0; // 10 metros para considerar movimiento
  static const Duration _movementTimeout = Duration(
    seconds: 30,
  ); // 30 segundos sin movimiento
  static const Duration _checkInterval = Duration(
    seconds: 10,
  ); // Verificar cada 10 segundos

  // Estado del servicio
  bool _isActive = false;
  bool _isMoving = false;
  DateTime? _lastMovementTime;
  LatLng? _lastKnownLocation;
  Timer? _movementTimer;

  // Callbacks
  Function(bool)? _onMovementStateChanged;
  Function(LatLng)? _onLocationUpdate;

  // Estadísticas
  int _totalChecks = 0;
  int _movementDetections = 0;
  double _totalDistanceMoved = 0.0;

  /// Inicializar el servicio
  Future<void> init() async {
    if (_isActive) return;

    try {
      // Verificar permisos
      await _checkLocationPermissions();

      _isActive = true;
      // Removed debug print
      // Removed debug print
      // Removed debug print
    } catch (e) {
      // Removed debug print
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

  /// Iniciar detección de movimiento
  void startDetection({
    Function(bool)? onMovementStateChanged,
    Function(LatLng)? onLocationUpdate,
  }) {
    if (!_isActive) {
      // Removed debug print
      return;
    }

    // Configurar callbacks
    _onMovementStateChanged = onMovementStateChanged;
    _onLocationUpdate = onLocationUpdate;

    // Removed debug print

    // Configuración conservadora para detección
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium, // Precisión media para ahorrar batería
      distanceFilter: 5, // 5 metros
      timeLimit: Duration(seconds: 15), // 15 segundos máximo
    );

    // Iniciar stream de ubicación
    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      _handlePositionUpdate,
      onError: (error) {
        // Removed debug print

        // Manejar timeouts específicamente
        if (error.toString().contains('TimeoutException')) {
          // Removed debug print

          // Reintentar después de 5 segundos
          Future.delayed(Duration(seconds: 5), () {
            if (_isActive) {
              // Removed debug print
              startDetection(
                onMovementStateChanged: _onMovementStateChanged,
                onLocationUpdate: _onLocationUpdate,
              );
            }
          });
        }
      },
    );

    // Iniciar timer para verificar inactividad
    _startInactivityTimer();

    // Removed debug print
  }

  /// Manejar actualización de posición
  void _handlePositionUpdate(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    // Actualizar ubicación
    // Removed debug print
    _onLocationUpdate?.call(newLocation);

    // Calcular distancia movida
    double distanceMoved = 0.0;
    if (_lastKnownLocation != null) {
      distanceMoved = _calculateDistance(_lastKnownLocation!, newLocation);
      _totalDistanceMoved += distanceMoved;
    }

    // Actualizar estadísticas
    _totalChecks++;
    _lastKnownLocation = newLocation;

    // Debug: Información detallada
    print(
      '[MovementDetectionService] 📍 Verificación #$_totalChecks: (${newLocation.latitude.toStringAsFixed(6)}, ${newLocation.longitude.toStringAsFixed(6)})',
    );
    print(
      '[MovementDetectionService] 📏 Distancia movida: ${distanceMoved.toStringAsFixed(1)}m (Total: ${_totalDistanceMoved.toStringAsFixed(1)}m)',
    );

    // Verificar si hay movimiento significativo
    if (distanceMoved > _movementThreshold) {
      _handleMovementDetected(now, distanceMoved);
    } else {
      _handleNoMovement(now);
    }

    // Reiniciar timer de inactividad
    _resetInactivityTimer();
  }

  /// Manejar movimiento detectado
  void _handleMovementDetected(DateTime now, double distance) {
    if (!_isMoving) {
      _isMoving = true;
      _movementDetections++;
      _lastMovementTime = now;

      print(
        '[MovementDetectionService] 🚶 MOVIMIENTO DETECTADO: ${distance.toStringAsFixed(1)}m',
      );
      // Removed debug print

      // Notificar cambio de estado
      _onMovementStateChanged?.call(true);

      // Mostrar notificación de movimiento
      _showMovementNotification(true, distance);
    }
  }

  /// Manejar ausencia de movimiento
  void _handleNoMovement(DateTime now) {
    if (_isMoving) {
      // Verificar si ha pasado suficiente tiempo sin movimiento
      if (_lastMovementTime != null) {
        final timeSinceLastMovement = now.difference(_lastMovementTime!);
        if (timeSinceLastMovement > _movementTimeout) {
          _isMoving = false;

          // Removed debug print

          // Notificar cambio de estado
          _onMovementStateChanged?.call(false);

          // Mostrar notificación de inactividad
          _showMovementNotification(false, 0.0);
        }
      }
    }
  }

  /// Iniciar timer de inactividad
  void _startInactivityTimer() {
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(_checkInterval, (timer) {
      if (_isMoving && _lastMovementTime != null) {
        final timeSinceLastMovement = DateTime.now().difference(
          _lastMovementTime!,
        );
        if (timeSinceLastMovement > _movementTimeout) {
          _handleNoMovement(DateTime.now());
        }
      }
    });
  }

  /// Reiniciar timer de inactividad
  void _resetInactivityTimer() {
    _movementTimer?.cancel();
    _startInactivityTimer();
  }

  /// Mostrar notificación de cambio de estado
  void _showMovementNotification(bool isMoving, double distance) {
    if (isMoving) {
      print(
        '[MovementDetectionService] 📱 Notificación: Usuario en movimiento (${distance.toStringAsFixed(1)}m)',
      );
      // Aquí podrías mostrar una notificación al usuario
    } else {
      // Removed debug print
      // Aquí podrías mostrar una notificación al usuario
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

  /// Detener detección
  void stopDetection() {
    _movementTimer?.cancel();
    _movementTimer = null;
    _isActive = false;
    _isMoving = false;

    // Removed debug print
  }

  /// Obtener estado actual
  bool get isMoving => _isMoving;
  bool get isActive => _isActive;

  /// Obtener estadísticas del servicio
  Map<String, dynamic> getStats() {
    return {
      'isActive': _isActive,
      'isMoving': _isMoving,
      'totalChecks': _totalChecks,
      'movementDetections': _movementDetections,
      'totalDistanceMoved': _totalDistanceMoved,
      'lastMovementTime': _lastMovementTime?.toIso8601String(),
      'lastKnownLocation':
          _lastKnownLocation != null
              ? '(${_lastKnownLocation!.latitude.toStringAsFixed(6)}, ${_lastKnownLocation!.longitude.toStringAsFixed(6)})'
              : null,
    };
  }

  /// Obtener ubicación actual
  LatLng? get currentLocation => _lastKnownLocation;
}
