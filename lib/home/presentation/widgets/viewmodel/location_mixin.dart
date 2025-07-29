import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import 'package:safy/core/services/firebase/notification_service.dart';
import 'package:safy/core/services/security/gps_spoofing_detector.dart';
import 'package:safy/core/services/cluster_detection_service.dart';
import 'package:safy/core/services/location_tracking_service.dart';
import 'package:safy/core/services/movement_detection_service.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:get_it/get_it.dart';

/// Mixin para gestión de ubicación del usuario
mixin LocationMixin on ChangeNotifier {
  // Agrega esta propiedad para las zonas peligrosas
  List<LatLng> _dangerZones = [];
  final Distance _distance = Distance();

  // Propiedades de ubicación
  late LatLng _currentLocation;
  LatLng get currentLocation => _currentLocation;

  StreamSubscription<Position>? _positionStream;
  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  // 🔒 NUEVO: Propiedades para detección de GPS falso
  final GpsSpoofingDetector _gpsDetector = GpsSpoofingDetector();
  SpoofingDetectionResult? _lastSpoofingResult;
  SpoofingDetectionResult? get lastSpoofingResult => _lastSpoofingResult;
  bool get isGpsSpoofed => _lastSpoofingResult?.isSpoofed ?? false;

  // 🚨 NUEVO: Servicio de detección de clusters
  final ClusterDetectionService _clusterDetectionService =
      ClusterDetectionService();

  // 🚀 NUEVO: Servicio de tracking de ubicación en hilo separado
  late LocationTrackingService _locationTrackingService;

  // 🚶 NUEVO: Servicio de detección de movimiento
  late MovementDetectionService _movementDetectionService;

  // Determinar ubicación actual
  Future<void> determineCurrentLocation() async {
    try {
      final position = await _determinePosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      // 🔒 NUEVO: Detectar GPS falso inmediatamente
      await _detectGpsSpoofing(position);
    } catch (e) {
      // Ubicación por defecto (Tuxtla Gutiérrez, Centro)
      _currentLocation = LatLng(16.7569, -93.1292);
    }
  }

  Future<Position> _determinePosition() async {
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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(
        seconds: 10,
      ), // Timeout para evitar esperas largas
    );
  }

  // Seguimiento de ubicación
  void startLocationTracking() {
    // Removed debug print

    // Configuración de ubicación
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Actualizar cada 5 metros
    );

    // Iniciar stream de ubicación directamente (como funcionaba antes)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // Removed debug print
        updateCurrentPosition(position);
      },
      onError: (error) {
        // Removed debug print
        onLocationError('Error en tracking: $error');
      },
    );

    // Inicializar servicios adicionales
    _movementDetectionService = GetIt.instance<MovementDetectionService>();
    _locationTrackingService = GetIt.instance<LocationTrackingService>();

    // Removed debug print
  }

  void setDangerZones(List<LatLng> zones) {
    _dangerZones = zones;
  }

  void updateCurrentPosition(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    final previousLocation = _currentLocation;
    _currentLocation = newLocation;

    // 🔒 NUEVO: Detectar GPS falso en cada actualización
    _detectGpsSpoofing(position);

    // Verificar si se movió significativamente (más de 50 metros)
    final distance = Distance().as(
      LengthUnit.Meter,
      previousLocation,
      newLocation,
    );

    // Debug: Mostrar información de movimiento
    print(
      '[LocationMixin] 📍 Ubicación actualizada: (${newLocation.latitude.toStringAsFixed(6)}, ${newLocation.longitude.toStringAsFixed(6)})',
    );
    print(
      '[LocationMixin] 📏 Distancia movida: ${distance.toStringAsFixed(1)}m',
    );

    if (distance > 50) {
      print(
        '[LocationMixin] 🚶 Movimiento significativo detectado: ${distance.toStringAsFixed(1)}m',
      );
      // Movimiento significativo detectado
      // Podrías recargar reportes cercanos aquí si es necesario
      // onLocationChanged(newLocation, distance);
    }

    // 🚨 NUEVO: Verificar clusters de zonas peligrosas
    _checkClustersForDangerZones(newLocation);

    // Callback para el ViewModel principal
    onLocationUpdated(newLocation);
    notifyListeners();
  }

  // 🔒 NUEVO: Método para detectar GPS falso
  Future<void> _detectGpsSpoofing(Position position) async {
    try {
      // Removed debug print

      // Debug de la posición para entender qué está causando la detección
      _gpsDetector.debugPosition(position);

      // Usar detección nativa - más precisa y confiable
      final result = await _gpsDetector.detectWithNativeLibrary(position);

      // Actualizar resultado
      _lastSpoofingResult = result;

      if (result.isSpoofed) {
        // Removed debug print
        print(
          '[LocationMixin] 🎯 Riesgo: ${(result.riskScore * 100).toStringAsFixed(1)}%',
        );
        // Removed debug print

        // Mostrar detalles de los problemas detectados
        for (final issue in result.detectedIssues) {
          print(
            '[LocationMixin]   - ${issue.description} (${(issue.severity * 100).toStringAsFixed(1)}%)',
          );
        }

        // Mostrar notificación al usuario
        _showGpsSpoofingWarning(result);

        // Callback para el ViewModel principal
        onGpsSpoofingDetected(result);
      } else {
        // Removed debug print

        // Si antes estaba detectado como falso y ahora es real, limpiar
        if (_lastSpoofingResult?.isSpoofed == true) {
          // Removed debug print
          _gpsDetector.clearHistoryForRealGps();
        }
      }
    } catch (e) {
      // Removed debug print
    }
  }

  // 🔒 NUEVO: Mostrar advertencia de GPS falso
  void _showGpsSpoofingWarning(SpoofingDetectionResult result) {
    final riskLevel = result.riskLevel;
    final riskPercentage = (result.riskScore * 100).toStringAsFixed(1);

    String title = '⚠️ GPS Sospechoso';
    String body =
        'Se detectó posible GPS falso (${riskPercentage}% de riesgo).';

    if (result.riskScore >= 0.8) {
      title = '🚨 GPS Falso Detectado';
      body =
          'Se detectó GPS falso con alta confianza (${riskPercentage}% de riesgo).';
    }

    NotificationService().showDangerZoneNotification(title: title, body: body);
  }

  // 🚨 NUEVO: Verificar clusters de zonas peligrosas
  void _checkClustersForDangerZones(LatLng currentLocation) {
    // Obtener clusters del ViewModel principal (se implementará en el ViewModel)
    final clusters = getCurrentClusters();

    if (clusters.isNotEmpty) {
      // Usar el servicio de detección de clusters
      _clusterDetectionService.checkLocationInDangerZone(
        currentLocation,
        clusters,
      );
    }
  }

  // Método abstracto para obtener clusters actuales (implementar en ViewModel)
  List<ClusterEntity> getCurrentClusters() {
    return []; // Implementar en el ViewModel principal
  }

  void startNavigation() {
    // Limpiar rutas previas antes de iniciar nueva navegación
    clearPreviousRoutes();

    _isNavigating = true;
    _positionStream?.cancel();
    startLocationTracking();
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _positionStream?.cancel();
    startLocationTracking();
    notifyListeners();
  }

  // Método para limpiar rutas previas
  void clearPreviousRoutes() {
    // Notificar al ViewModel principal para limpiar rutas
    onRoutesCleared();
  }

  // Callback abstracto para limpiar rutas (implementar en ViewModel)
  void onRoutesCleared() {
    // Implementar en el ViewModel principal
  }

  Future<void> centerOnCurrentLocation() async {
    try {
      final position = await _determinePosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      _currentLocation = newLocation;

      // 🔒 NUEVO: Detectar GPS falso al centrar
      await _detectGpsSpoofing(position);

      // Callback para el ViewModel principal
      onLocationCentered(newLocation);
      notifyListeners();
    } catch (e) {
      onLocationError('Error: $e');
      notifyListeners();
    }
  }

  // Método para obtener ubicación fresca para reportes
  Future<LatLng> getCurrentLocationForReports() async {
    try {
      final position = await _determinePosition();
      final freshLocation = LatLng(position.latitude, position.longitude);

      // 🔒 NUEVO: Detectar GPS falso antes de reportar
      await _detectGpsSpoofing(position);

      // Actualizar ubicación actual si es diferente
      final distance = Distance().as(
        LengthUnit.Meter,
        _currentLocation,
        freshLocation,
      );
      if (distance > 10) {
        _currentLocation = freshLocation;
        notifyListeners();
      }

      return freshLocation;
    } catch (e) {
      return _currentLocation;
    }
  }

  void disposeLocation() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // 🔒 NUEVO: Método para resetear el detector de GPS falso
  void resetGpsSpoofingDetector() {
    _gpsDetector.resetDetector();
    _lastSpoofingResult = null;
    notifyListeners();
  }

  // Callbacks abstractos para implementar en el ViewModel principal
  void onLocationUpdated(LatLng location);
  void onLocationCentered(LatLng location);
  void onLocationError(String error);

  /// Obtener estadísticas del tracking
  Map<String, dynamic> getTrackingStats() {
    return {
      'isActive': _positionStream != null,
      'currentLocation':
          '(${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)})',
      'isNavigating': _isNavigating,
    };
  }

  /// Forzar actualización de ubicación (para el botón de recargar)
  Future<void> forceLocationUpdate() async {
    try {
      // Removed debug print

      final position = await _determinePosition();
      final newLocation = LatLng(position.latitude, position.longitude);

      print(
        '[LocationMixin] 📍 Ubicación forzada: (${newLocation.latitude.toStringAsFixed(6)}, ${newLocation.longitude.toStringAsFixed(6)})',
      );

      _currentLocation = newLocation;
      onLocationUpdated(newLocation);
      notifyListeners();
    } catch (e) {
      // Removed debug print
      onLocationError('Error actualizando ubicación: $e');
    }
  }

  // 🔒 NUEVO: Callback para GPS falso detectado
  void onGpsSpoofingDetected(SpoofingDetectionResult result);

  // Callback opcional para cambios significativos de ubicación
  void onLocationChanged(LatLng newLocation, double distanceMoved) {
    // Implementar en el ViewModel si se necesita recargar reportes
  }
}
