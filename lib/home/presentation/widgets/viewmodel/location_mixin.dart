import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

/// Mixin para gestión de ubicación del usuario
mixin LocationMixin on ChangeNotifier {
  
  // Propiedades de ubicación
  late LatLng _currentLocation;
  LatLng get currentLocation => _currentLocation;

  StreamSubscription<Position>? _positionStream;
  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  // Determinar ubicación actual
  Future<void> determineCurrentLocation() async {
    try {
      final position = await _determinePosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Ubicación por defecto (Tuxtla Gutiérrez)
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
    );
  }

  // Seguimiento de ubicación
  void startLocationTracking() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print('📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}');
        updateCurrentPosition(position);
      },
      onError: (error) {
        print('Error en tracking de ubicación: $error');
      },
    );
  }

  void updateCurrentPosition(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    _currentLocation = newLocation;
    
    // Callback para el ViewModel principal
    onLocationUpdated(newLocation);
    notifyListeners();
  }

  void startNavigation() {
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

  Future<void> centerOnCurrentLocation() async {
    try {
      final position = await _determinePosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      _currentLocation = newLocation;
      
      // Callback para el ViewModel principal
      onLocationCentered(newLocation);
      notifyListeners();
    } catch (e) {
      onLocationError('Error: $e');
      notifyListeners();
    }
  }

  void disposeLocation() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Callbacks abstractos para implementar en el ViewModel principal
  void onLocationUpdated(LatLng location);
  void onLocationCentered(LatLng location);
  void onLocationError(String error);
}