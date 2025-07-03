import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Domain


// Core
import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/usecases/calculate_safe_routes_use_case.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/domain/value_objects/danger_level.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';

class MapViewModel extends ChangeNotifier {
  // Dependencies
  final CalculateSafeRoutesUseCase _calculateSafeRoutesUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final CheckDangerZonesUseCase _checkDangerZonesUseCase;
  final GetDangerZonesUseCase _getDangerZonesUseCase;

  MapViewModel({
    required CalculateSafeRoutesUseCase calculateSafeRoutesUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required CheckDangerZonesUseCase checkDangerZonesUseCase,
    required GetDangerZonesUseCase getDangerZonesUseCase,
  })  : _calculateSafeRoutesUseCase = calculateSafeRoutesUseCase,
        _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _checkDangerZonesUseCase = checkDangerZonesUseCase,
        _getDangerZonesUseCase = getDangerZonesUseCase;

  // MapController
  final MapController _mapController = MapController();
  MapController get mapController => _mapController;

  // Estado del mapa
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _mapReady = false;
  bool get mapReady => _mapReady;

  bool _showDangerZones = true;
  bool get showDangerZones => _showDangerZones;

  // Ubicación actual
  Location? _currentLocation;
  Location? get currentLocation => _currentLocation;

  // Rutas
  Location? _startPoint;
  Location? get startPoint => _startPoint;

  Location? _endPoint;
  Location? get endPoint => _endPoint;

  TransportMode _selectedTransportMode = TransportMode.walking;
  TransportMode get selectedTransportMode => _selectedTransportMode;

  List<RouteEntity> _routeOptions = [];
  List<RouteEntity> get routeOptions => _routeOptions;

  RouteEntity? _selectedRoute;
  RouteEntity? get selectedRoute => _selectedRoute;

  // Zonas peligrosas
  List<DangerZone> _dangerZones = [];
  List<DangerZone> get dangerZones => _dangerZones;

  // Marcadores para el mapa (conversión a LatLng para flutter_map)
  List<Marker> get markers {
    final markers = <Marker>[];

    // Marcador de ubicación actual
    if (_currentLocation != null) {
      markers.add(_createLocationMarker(
        _currentLocation!.toLatLng(),
        Icons.my_location,
        Colors.blue,
        'current_location',
      ));
    }

    // Marcadores de ruta
    if (_startPoint != null) {
      markers.add(_createLocationMarker(
        _startPoint!.toLatLng(),
        Icons.play_arrow,
        Colors.green,
        'start_point',
      ));
    }

    if (_endPoint != null) {
      markers.add(_createLocationMarker(
        _endPoint!.toLatLng(),
        Icons.stop,
        Colors.red,
        'end_point',
      ));
    }

    return markers;
  }

  List<Marker> get dangerMarkers {
    if (!_showDangerZones) return [];

    return _dangerZones.map((zone) {
      return Marker(
        point: zone.center.toLatLng(),
        width: zone.dangerLevel.radius * 2,
        height: zone.dangerLevel.radius * 2,
        child: Container(
          decoration: BoxDecoration(
            color: zone.dangerLevel.color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: zone.dangerLevel.color, width: 2),
          ),
          child: Center(
            child: Text(
              '${zone.reportCount}',
              style: TextStyle(
                color: zone.dangerLevel.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<LatLng> get currentRoutePoints {
    if (_selectedRoute == null) return [];
    return _selectedRoute!.waypoints.map((location) => location.toLatLng()).toList();
  }

  // Errores
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Inicialización del mapa
  Future<void> initializeMap() async {
    try {
      _setLoading(true);
      
      // Obtener ubicación actual
      await _loadCurrentLocation();
      
      // Cargar zonas peligrosas
      await _loadDangerZones();
      
      _setLoading(false);
    } catch (e) {
      _setError(_handleFailure(e));
      _setLoading(false);
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      _currentLocation = await _getCurrentLocationUseCase.execute();
    } catch (e) {
      // Ubicación por defecto si falla
      _currentLocation = Location(
        latitude: 16.7569,
        longitude: -93.1292,
      );
      debugPrint('Usando ubicación por defecto: $e');
    }
  }

  Future<void> _loadDangerZones() async {
    if (_currentLocation == null) return;

   try {
  // Cargar zonas peligrosas en un radio de 10km
  _dangerZones = await _getDangerZonesUseCase.execute(
    center: _currentLocation!,
    radiusKm: 10.0,
  );
} catch (e) {
  debugPrint('Error cargando zonas peligrosas: $e');
  // Usar datos simulados en caso de error
  _loadMockDangerZones();
}
  }

  void _loadMockDangerZones() {
    if (_currentLocation == null) return;

    _dangerZones = [
      DangerZone(
        id: '1',
        center: Location(latitude: 16.7500, longitude: -93.1300),
        radiusMeters: 200,
        dangerLevel: DangerLevel.high,
        reportCount: 5,
        lastReportAt: DateTime.now().subtract(const Duration(hours: 2)),
        incidentTypes: ['asalto', 'acoso'],
        isActive: true,
      ),
      DangerZone(
        id: '2',
        center: Location(latitude: 16.7600, longitude: -93.1250),
        radiusMeters: 150,
        dangerLevel: DangerLevel.medium,
        reportCount: 3,
        lastReportAt: DateTime.now().subtract(const Duration(hours: 8)),
        incidentTypes: ['robo'],
        isActive: true,
      ),
      DangerZone(
        id: '3',
        center: Location(latitude: 16.7400, longitude: -93.1400),
        radiusMeters: 250,
        dangerLevel: DangerLevel.critical,
        reportCount: 8,
        lastReportAt: DateTime.now().subtract(const Duration(minutes: 30)),
        incidentTypes: ['secuestro', 'asalto', 'violencia'],
        isActive: true,
      ),
    ];
  }

  // Funciones del mapa
  void onMapReady() {
    _mapReady = true;
    notifyListeners();
    _moveToCurrentLocation();
  }

  void _moveToCurrentLocation() {
    if (_mapReady && _currentLocation != null) {
      try {
        _mapController.move(_currentLocation!.toLatLng(), 15.0);
      } catch (e) {
        debugPrint("Error moviendo mapa: $e");
      }
    }
  }

  void toggleDangerZones() {
    _showDangerZones = !_showDangerZones;
    notifyListeners();
  }

  void setTransportMode(TransportMode mode) {
    _selectedTransportMode = mode;
    
    // Recalcular rutas si hay puntos seleccionados
    if (_startPoint != null && _endPoint != null) {
      calculateRoutes();
    }
    
    notifyListeners();
  }

  // Sistema de rutas
  void setStartPoint(Location point) {
    _startPoint = point;
    
    if (_endPoint != null) {
      calculateRoutes();
    }
    
    notifyListeners();
  }

  void setEndPoint(Location point) {
    _endPoint = point;
    
    if (_startPoint != null) {
      calculateRoutes();
    }
    
    notifyListeners();
  }

  Future<void> calculateRoutes() async {
    if (_startPoint == null || _endPoint == null) return;

    try {
      _setLoading(true);
      
      final routes = await _calculateSafeRoutesUseCase.execute(
        startPoint: _startPoint!,
        endPoint: _endPoint!,
        transportMode: _selectedTransportMode,
      );

      _routeOptions = routes;
      
      // Seleccionar la ruta recomendada por defecto
      final recommendedRoute = routes.where((route) => route.isRecommended).firstOrNull;
      _selectedRoute = recommendedRoute ?? routes.firstOrNull;
      
      _setLoading(false);
    } catch (e) {
      _setError(_handleFailure(e));
      _setLoading(false);
    }
  }

  void selectRoute(RouteEntity route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void clearRoute() {
    _startPoint = null;
    _endPoint = null;
    _selectedRoute = null;
    _routeOptions.clear();
    notifyListeners();
  }

  // Centrar en ubicación actual
  Future<void> centerOnCurrentLocation() async {
    if (!_mapReady) return;
    
    try {
      final newLocation = await _getCurrentLocationUseCase.execute();
      _currentLocation = newLocation;
      _mapController.move(newLocation.toLatLng(), 15.0);
      notifyListeners();
    } catch (e) {
      _setError(_handleFailure(e));
    }
  }

  // Helpers privados
  Marker _createLocationMarker(
    LatLng point,
    IconData icon,
    Color color,
    String key,
  ) {
    return Marker(
      key: Key(key),
      point: point,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  String _handleFailure(dynamic error) {
    if (error is Failure) {
      return error.message;
    }
    return 'Error inesperado: $error';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}