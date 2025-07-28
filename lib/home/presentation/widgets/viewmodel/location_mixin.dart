import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import 'package:safy/core/services/firebase/notification_service.dart';
import 'package:safy/core/services/security/gps_spoofing_detector.dart';

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
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Actualizar cada 5 metros (más frecuente)
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        updateCurrentPosition(position);
      },
      onError: (error) {
        // Error en tracking de ubicación
      },
    );
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
    if (distance > 50) {
      // Movimiento significativo detectado
      // Podrías recargar reportes cercanos aquí si es necesario
      // onLocationChanged(newLocation, distance);
    }

    // Notificar si está cerca de una zona peligrosa
    _checkProximityToDangerZones(newLocation);

    // Callback para el ViewModel principal
    onLocationUpdated(newLocation);
    notifyListeners();
  }

  // 🔒 NUEVO: Método para detectar GPS falso
  Future<void> _detectGpsSpoofing(Position position) async {
    try {
      print('[LocationMixin] 🔍 Verificando GPS falso...');

      // Debug de la posición para entender qué está causando la detección
      _gpsDetector.debugPosition(position);

      // Usar detección nativa - más precisa y confiable
      final result = await _gpsDetector.detectWithNativeLibrary(position);

      // Actualizar resultado
      _lastSpoofingResult = result;

      if (result.isSpoofed) {
        print('[LocationMixin] 🚨 GPS FALSO DETECTADO!');
        print(
          '[LocationMixin] 🎯 Riesgo: ${(result.riskScore * 100).toStringAsFixed(1)}%',
        );
        print('[LocationMixin] 📋 Problemas: ${result.detectedIssues.length}');

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
        print('[LocationMixin] ✅ GPS parece ser real');

        // Si antes estaba detectado como falso y ahora es real, limpiar
        if (_lastSpoofingResult?.isSpoofed == true) {
          print(
            '[LocationMixin] 🔄 GPS ahora parece ser real - limpiando alertas',
          );
          _gpsDetector.clearHistoryForRealGps();
        }
      }
    } catch (e) {
      print('[LocationMixin] ❌ Error en detección de GPS falso: $e');
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

  void _checkProximityToDangerZones(LatLng currentLocation) {
    for (final zone in _dangerZones) {
      final meters = Distance().call(currentLocation, zone);
      if (meters < 200) {
        NotificationService().showDangerZoneNotification(
          title: 'Zona peligrosa cercana',
          body: 'Estás a menos de 200 metros de una zona con reportes.',
        );
        break;
      }
    }
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

  // 🔒 NUEVO: Callback para GPS falso detectado
  void onGpsSpoofingDetected(SpoofingDetectionResult result);

  // Callback opcional para cambios significativos de ubicación
  void onLocationChanged(LatLng newLocation, double distanceMoved) {
    // Implementar en el ViewModel si se necesita recargar reportes
  }
}
