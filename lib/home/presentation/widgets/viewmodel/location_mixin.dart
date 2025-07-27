import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import 'package:safy/core/services/firebase/notification_service.dart';

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

  // Determinar ubicación actual
  Future<void> determineCurrentLocation() async {
    try {
      print('[LocationMixin] 📍 Obteniendo ubicación actual...');
      final position = await _determinePosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      print(
        '[LocationMixin] ✅ Ubicación obtenida: ${_currentLocation.latitude}, ${_currentLocation.longitude}',
      );
    } catch (e) {
      print(
        '[LocationMixin] ⚠️ Error obteniendo ubicación, usando ubicación por defecto: $e',
      );
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
    print('[LocationMixin] 🔄 Iniciando seguimiento de ubicación...');

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print(
          '[LocationMixin] 📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}',
        );
        updateCurrentPosition(position);
      },
      onError: (error) {
        print('[LocationMixin] ❌ Error en tracking de ubicación: $error');
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

    // Verificar si se movió significativamente (más de 50 metros)
    final distance = Distance().as(
      LengthUnit.Meter,
      previousLocation,
      newLocation,
    );
    if (distance > 50) {
      print(
        '[LocationMixin] 🚶 Movimiento significativo detectado: ${distance.toInt()}m',
      );
      // Podrías recargar reportes cercanos aquí si es necesario
      // onLocationChanged(newLocation, distance);
    }

    // Notificar si está cerca de una zona peligrosa
    _checkProximityToDangerZones(newLocation);

    // Callback para el ViewModel principal
    onLocationUpdated(newLocation);
    notifyListeners();
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
    print('[LocationMixin] 🧭 Iniciando navegación...');

    // 🧹 Limpiar rutas previas antes de iniciar nueva navegación
    clearPreviousRoutes();

    _isNavigating = true;
    _positionStream?.cancel();
    startLocationTracking();
    notifyListeners();
  }

  void stopNavigation() {
    print('[LocationMixin] ⏹️ Deteniendo navegación...');
    _isNavigating = false;
    _positionStream?.cancel();
    startLocationTracking();
    notifyListeners();
  }

    // 🧹 NUEVO: Método para limpiar rutas previas
  void clearPreviousRoutes() {
    print('[LocationMixin] 🧹 Limpiando rutas previas...');
    
    // Notificar al ViewModel principal para limpiar rutas
    onRoutesCleared();
  }

  // Callback abstracto para limpiar rutas (implementar en ViewModel)
  void onRoutesCleared() {
    // Implementar en el ViewModel principal
  }

  Future<void> centerOnCurrentLocation() async {
    try {
      print('[LocationMixin] 🎯 Centrando en ubicación actual...');
      final position = await _determinePosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      _currentLocation = newLocation;

      print(
        '[LocationMixin] ✅ Centrado en: ${newLocation.latitude}, ${newLocation.longitude}',
      );

      // Callback para el ViewModel principal
      onLocationCentered(newLocation);
      notifyListeners();
    } catch (e) {
      print('[LocationMixin] ❌ Error centrando ubicación: $e');
      onLocationError('Error: $e');
      notifyListeners();
    }
  }

  // Método para obtener ubicación fresca para reportes
  Future<LatLng> getCurrentLocationForReports() async {
    try {
      print('[LocationMixin] 📍 Obteniendo ubicación fresca para reportes...');
      final position = await _determinePosition();
      final freshLocation = LatLng(position.latitude, position.longitude);

      // Actualizar ubicación actual si es diferente
      final distance = Distance().as(
        LengthUnit.Meter,
        _currentLocation,
        freshLocation,
      );
      if (distance > 10) {
        print(
          '[LocationMixin] 🔄 Actualizando ubicación actual (${distance.toInt()}m de diferencia)',
        );
        _currentLocation = freshLocation;
        notifyListeners();
      }

      return freshLocation;
    } catch (e) {
      print(
        '[LocationMixin] ⚠️ Error obteniendo ubicación fresca, usando ubicación actual',
      );
      return _currentLocation;
    }
  }

  void disposeLocation() {
    print('[LocationMixin] 🧹 Limpiando recursos de ubicación...');
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Callbacks abstractos para implementar en el ViewModel principal
  void onLocationUpdated(LatLng location);
  void onLocationCentered(LatLng location);
  void onLocationError(String error);

  // Callback opcional para cambios significativos de ubicación
  void onLocationChanged(LatLng newLocation, double distanceMoved) {
    // Implementar en el ViewModel si se necesita recargar reportes
  }
}
