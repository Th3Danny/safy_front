import 'package:flutter/material.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/core/errors/failures.dart';
import 'package:geolocator/geolocator.dart';

class MapViewModelEnhanced extends ChangeNotifier {
  final SearchPlacesUseCase _searchPlacesUseCase;
  final GetOpenRouteUseCase _getOpenRouteUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final CheckDangerZonesUseCase _checkDangerZonesUseCase;
  final GetDangerZonesUseCase _getDangerZonesUseCase;

  MapViewModelEnhanced({
    required SearchPlacesUseCase searchPlacesUseCase,
    required GetOpenRouteUseCase getOpenRouteUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required CheckDangerZonesUseCase checkDangerZonesUseCase,
    required GetDangerZonesUseCase getDangerZonesUseCase,
  })  : _searchPlacesUseCase = searchPlacesUseCase,
        _getOpenRouteUseCase = getOpenRouteUseCase,
        _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _checkDangerZonesUseCase = checkDangerZonesUseCase,
        _getDangerZonesUseCase = getDangerZonesUseCase;

  // Estado interno
  Location? _currentLocation;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  List<DangerZone> _dangerZones = [];
  bool _showDangerZones = false;
  DangerZoneCheckResult? _currentLocationSafety;

  // Getters
  Location? get currentLocation => _currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get errorMessage => _errorMessage;
  List<DangerZone> get dangerZones => _dangerZones;
  bool get showDangerZones => _showDangerZones;
  DangerZoneCheckResult? get currentLocationSafety => _currentLocationSafety;
  bool get hasLocation => _currentLocation != null;
  String get locationText => _currentLocation != null 
    ? '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}'
    : '';

  // Método principal para obtener ubicación
  Future<void> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_isLoadingLocation) return;

    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentLocation = await _getCurrentLocationUseCase.execute(
        accuracy: accuracy,
        timeout: timeout,
      );

      // Verificar seguridad de la ubicación actual
      await _checkCurrentLocationSafety();

      // Cargar zonas de peligro cercanas
      await _loadNearbyDangerZones();

      _errorMessage = null;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _currentLocation = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _currentLocation = null;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _currentLocation = null;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Verificar seguridad de la ubicación actual
  Future<void> _checkCurrentLocationSafety() async {
    if (_currentLocation == null) return;

    try {
      _currentLocationSafety = await _checkDangerZonesUseCase.execute(_currentLocation!);
    } catch (e) {
      print('Error verificando seguridad: $e');
      _currentLocationSafety = null;
    }
  }

  // Cargar zonas de peligro cercanas
  Future<void> _loadNearbyDangerZones() async {
    if (_currentLocation == null) return;

    try {
      _dangerZones = await _getDangerZonesUseCase.execute(_currentLocation!);
    } catch (e) {
      print('Error cargando zonas de peligro: $e');
      _dangerZones = [];
    }
  }

  // Toggle para mostrar/ocultar zonas de peligro
  void toggleDangerZones() {
    _showDangerZones = !_showDangerZones;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Limpiar ubicación
  void clearLocation() {
    _currentLocation = null;
    _currentLocationSafety = null;
    notifyListeners();
  }

  // Centrar en ubicación actual
  void centerOnCurrentLocation() {
    if (_currentLocation != null) {
      // Implementar lógica para centrar mapa
      print('Centrando en: ${_currentLocation!.toString()}');
    } else {
      getCurrentLocation();
    }
  }
}