import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';

class MapViewModel extends ChangeNotifier {
  // Casos de uso
  final SearchPlacesUseCase? _searchPlacesUseCase;
  final GetOpenRouteUseCase? _getOpenRouteUseCase;

  // Constructor actualizado
  MapViewModel({
    SearchPlacesUseCase? searchPlacesUseCase,
    GetOpenRouteUseCase? getOpenRouteUseCase,
  }) : _searchPlacesUseCase = searchPlacesUseCase,
       _getOpenRouteUseCase = getOpenRouteUseCase;

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

  // Ubicación
  late LatLng _currentLocation;
  LatLng get currentLocation => _currentLocation;

  // Marcadores y rutas
  List<Marker> _markers = [];
  List<Marker> get markers => _markers;

  List<Marker> _dangerMarkers = [];
  List<Marker> get dangerMarkers => _dangerMarkers;

  List<LatLng> _currentRoute = [];
  List<LatLng> get currentRoute => _currentRoute;

  // Sistema de rutas
  LatLng? _startPoint;
  LatLng? get startPoint => _startPoint;

  LatLng? _endPoint;
  LatLng? get endPoint => _endPoint;

  String _selectedTransportMode = 'walk';
  String get selectedTransportMode => _selectedTransportMode;

  List<RouteOption> _routeOptions = [];
  List<RouteOption> get routeOptions => _routeOptions;

  // Propiedades para búsqueda
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<Place> _searchResults = [];
  List<Place> get searchResults => _searchResults;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Place? _selectedDestination;
  Place? get selectedDestination => _selectedDestination;

  // Errores
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Inicialización del mapa
  Future<void> initializeMap() async {
    try {
      await _determineCurrentLocation();
      await _loadDangerZones();
      _createCurrentLocationMarker();

      // 👈 NUEVO: Iniciar seguimiento de ubicación siempre
      _startLocationTracking();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Determinar ubicación actual
  Future<void> _determineCurrentLocation() async {
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

  // Seguimiento de ubicación (siempre activo)
  void _startLocationTracking() {
  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1, // 👈 Cada 1 metros (muy frecuente pero no continuo)
    // ❌ NO usar timeLimit - causa timeout
  );

  _positionStream = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen(
    (Position position) {
      print('📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}');
      _updateCurrentPosition(position);
    },
    onError: (error) {
      print('Error en tracking de ubicación: $error');
    },
  );
}

  // Crear marcador de ubicación actual
  void _createCurrentLocationMarker() {
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains('current_location') == true,
    );

    _markers.add(
      Marker(
        key: const Key('current_location'),
        point: _currentLocation,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color:
                _isNavigating ? Colors.green : Colors.blue, // 👈 Color dinámico
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isNavigating
                ? Icons.navigation
                : Icons.my_location, // 👈 Ícono dinámico
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Cargar zonas de peligro
  Future<void> _loadDangerZones() async {
    final dangerZones = [
      {'lat': 16.7500, 'lng': -93.1300, 'reports': 5, 'type': 'high'},
      {'lat': 16.7600, 'lng': -93.1250, 'reports': 3, 'type': 'medium'},
      {'lat': 16.7400, 'lng': -93.1400, 'reports': 8, 'type': 'high'},
      {'lat': 16.7650, 'lng': -93.1350, 'reports': 2, 'type': 'low'},
      {'lat': 16.7520, 'lng': -93.1280, 'reports': 4, 'type': 'medium'},
    ];

    _dangerMarkers =
        dangerZones.map((zone) {
          Color zoneColor;
          double zoneRadius;

          switch (zone['type']) {
            case 'high':
              zoneColor = Colors.red;
              zoneRadius = 25;
              break;
            case 'medium':
              zoneColor = Colors.orange;
              zoneRadius = 20;
              break;
            default:
              zoneColor = Colors.yellow;
              zoneRadius = 15;
          }

          return Marker(
            point: LatLng(zone['lat'] as double, zone['lng'] as double),
            width: zoneRadius * 2,
            height: zoneRadius * 2,
            child: Container(
              decoration: BoxDecoration(
                color: zoneColor.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: zoneColor, width: 2),
              ),
              child: Center(
                child: Text(
                  '${zone['reports']}',
                  style: TextStyle(
                    color: zoneColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList();
  }

  // Métodos para búsqueda
  Future<void> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      if (_searchPlacesUseCase != null) {
        final currentLoc = Location(
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
        );

        _searchResults = await _searchPlacesUseCase!.execute(
          query,
          nearLocation: currentLoc,
          limit: 8,
        );
      } else {
        _searchResults = [];
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error buscando lugares: $e';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults.clear();
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }

  void selectPlace(Place place) {
    _selectedDestination = place;
    final placeLatLng = LatLng(place.latitude, place.longitude);

    _mapController.move(placeLatLng, 15.0);
    _addDestinationMarker(placeLatLng, place.displayName);
    setEndPoint(placeLatLng);

    if (_startPoint == null) {
      setStartPoint(_currentLocation);
    }

    notifyListeners();
  }

  void _addDestinationMarker(LatLng location, String name) {
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains('destination') == true,
    );

    _markers.add(
      Marker(
        key: const Key('destination'),
        point: location,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.place, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // Funciones del mapa
  void onMapReady() {
    _mapReady = true;
    notifyListeners();
    _moveToCurrentLocation();
  }

  void _moveToCurrentLocation() {
    if (_mapReady) {
      try {
        _mapController.move(_currentLocation, 15.0);
      } catch (e) {
        print("Error moviendo mapa: $e");
      }
    }
  }

  void toggleDangerZones() {
    _showDangerZones = !_showDangerZones;
    notifyListeners();
  }

  void setTransportMode(String mode) {
    _selectedTransportMode = mode;
    if (_startPoint != null && _endPoint != null) {
      calculateRoutes();
    }
    notifyListeners();
  }

  // Sistema de rutas
  void setStartPoint(LatLng point) {
    _startPoint = point;
    _addRouteMarker(point, Colors.green, Icons.play_arrow, 'start');
    if (_endPoint != null) {
      calculateRoutes();
    }
    notifyListeners();
  }

  void clearStartPoint() {
    _startPoint = null;
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains('start') == true,
    );
    _createCurrentLocationMarker();
    notifyListeners();
  }

  void clearEndPoint() {
    _endPoint = null;
    _selectedDestination = null;
    _markers.removeWhere(
      (marker) =>
          marker.key?.toString().contains('end') == true ||
          marker.key?.toString().contains('destination') == true,
    );
    _createCurrentLocationMarker();
    notifyListeners();
  }

  void setEndPoint(LatLng point) {
    _endPoint = point;
    _addRouteMarker(point, Colors.red, Icons.stop, 'end');
    if (_startPoint != null) {
      calculateRoutes();
    }
    notifyListeners();
  }

  void _addRouteMarker(LatLng point, Color color, IconData icon, String type) {
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains(type) == true,
    );

    _markers.add(
      Marker(
        key: Key(type),
        point: point,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // Calcular ruta real usando OpenRouteService
  Future<List<LatLng>> _calculateRealRoute(LatLng start, LatLng end) async {
    try {
      if (_getOpenRouteUseCase != null) {
        final coordinates = await _getOpenRouteUseCase!.call(
          start: [start.longitude, start.latitude],
          end: [end.longitude, end.latitude],
        );

        return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
      }
    } catch (e) {
      print('Error calculating real route: $e');
    }

    // Fallback a ruta directa
    return [start, end];
  }

  // Calcular rutas seguras
  Future<void> calculateRoutes() async {
    if (_startPoint == null || _endPoint == null) return;

    try {
      _routeOptions.clear();

      // Ruta real usando OpenRouteService
      final realRoute = await _calculateRealRoute(_startPoint!, _endPoint!);
      final realSafety = _calculateRouteSafety(realRoute);

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Directa',
          points: realRoute,
          distance: _calculateDistance(realRoute),
          duration: _calculateDuration(realRoute, _selectedTransportMode),
          safetyLevel: realSafety,
          isRecommended: realSafety >= 70,
        ),
      );

      // Ruta segura (evita zonas peligrosas)
      final safeRoute = await _calculateSafeRouteReal(_startPoint!, _endPoint!);
      final safeSafety = _calculateRouteSafety(safeRoute);

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Segura',
          points: safeRoute,
          distance: _calculateDistance(safeRoute),
          duration: _calculateDuration(safeRoute, _selectedTransportMode),
          safetyLevel: safeSafety,
          isRecommended: true,
        ),
      );

      // Ruta alternativa
      final altRoute = await _calculateAlternativeRouteReal(
        _startPoint!,
        _endPoint!,
      );
      final altSafety = _calculateRouteSafety(altRoute);

      _routeOptions.add(
        RouteOption(
          name: 'Ruta Alternativa',
          points: altRoute,
          distance: _calculateDistance(altRoute),
          duration: _calculateDuration(altRoute, _selectedTransportMode),
          safetyLevel: altSafety,
          isRecommended: false,
        ),
      );

      // Establecer la ruta recomendada como actual
      final recommendedRoute = _routeOptions.firstWhere(
        (route) => route.isRecommended,
        orElse: () => _routeOptions.first,
      );

      selectRoute(recommendedRoute);
    } catch (e) {
      _errorMessage = 'Error calculando rutas: $e';
    }

    notifyListeners();
  }

  // Nuevas propiedades
  StreamSubscription<Position>? _positionStream;
  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  // AGREGAR ESTE MÉTODO SIMPLE ✅
  void startNavigation() {
  if (_currentRoute.isEmpty) return;
  
  _isNavigating = true;
  
  // Reiniciar tracking con mayor precisión
  _positionStream?.cancel();
  _startLocationTracking();
  
  notifyListeners();
}

  // Método para actualizar posición
  void _updateCurrentPosition(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);

    // Actualizar ubicación actual
    _currentLocation = newLocation;

    // Actualizar marcador de ubicación
    _createCurrentLocationMarker();

    // Centrar mapa en nueva ubicación (opcional)
    if (_mapReady) {
      _mapController.move(newLocation, _mapController.camera.zoom);
    }

    notifyListeners();
  }

  // Método para detener navegación
  void stopNavigation() {
  _isNavigating = false;
  
  // Reiniciar tracking con menor frecuencia
  _positionStream?.cancel();
  _startLocationTracking();
  
  notifyListeners();
}

  // Actualizar dispose
  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // Métodos mejorados para calcular rutas reales
  Future<List<LatLng>> _calculateSafeRouteReal(LatLng start, LatLng end) async {
    // Intentar calcular una ruta que evite zonas peligrosas
    // Por ahora, usamos la ruta real y si pasa por zonas peligrosas, añadimos puntos de desvío
    final directRoute = await _calculateRealRoute(start, end);

    // Si la ruta pasa por zonas muy peligrosas, crear puntos de desvío
    if (_calculateRouteSafety(directRoute) < 50) {
      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;
      final safePoint = LatLng(midLat + 0.002, midLng - 0.002);

      final firstSegment = await _calculateRealRoute(start, safePoint);
      final secondSegment = await _calculateRealRoute(safePoint, end);

      // Combinar segmentos evitando duplicar puntos
      final combinedRoute = <LatLng>[
        ...firstSegment,
        ...secondSegment.skip(
          1,
        ), // Saltar el primer punto para evitar duplicación
      ];

      return combinedRoute;
    }

    return directRoute;
  }

  Future<List<LatLng>> _calculateAlternativeRouteReal(
    LatLng start,
    LatLng end,
  ) async {
    // Crear un punto intermedio para generar una ruta alternativa
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final altPoint = LatLng(midLat - 0.001, midLng + 0.003);

    try {
      final firstSegment = await _calculateRealRoute(start, altPoint);
      final secondSegment = await _calculateRealRoute(altPoint, end);

      return [...firstSegment, ...secondSegment.skip(1)];
    } catch (e) {
      // Si falla, usar la ruta directa
      return await _calculateRealRoute(start, end);
    }
  }

  void selectRoute(RouteOption route) {
    _currentRoute = route.points;
    notifyListeners();
  }

  // Algoritmos de cálculo de seguridad y distancia
  double _calculateRouteSafety(List<LatLng> route) {
    double safetyScore = 1.0;
    for (final point in route) {
      for (final dangerMarker in _dangerMarkers) {
        final distance = _distanceBetween(point, dangerMarker.point);
        if (distance < 0.001) {
          safetyScore -= 0.3;
        } else if (distance < 0.002) {
          safetyScore -= 0.1;
        }
      }
    }
    return (safetyScore * 100).clamp(0, 100);
  }

  double _distanceBetween(LatLng point1, LatLng point2) {
    return Distance().as(LengthUnit.Kilometer, point1, point2);
  }

  double _calculateDistance(List<LatLng> route) {
    double totalDistance = 0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _distanceBetween(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  int _calculateDuration(List<LatLng> route, String transportMode) {
    final distance = _calculateDistance(route);
    final speeds = {'walk': 5.0, 'car': 40.0, 'bus': 25.0};
    final speed = speeds[transportMode] ?? 5.0;
    return (distance / speed * 60).round();
  }

  void clearRoute() {
    _startPoint = null;
    _endPoint = null;
    _selectedDestination = null;
    _currentRoute.clear();
    _routeOptions.clear();

    _markers.removeWhere(
      (marker) =>
          marker.key?.toString().contains('start') == true ||
          marker.key?.toString().contains('end') == true ||
          marker.key?.toString().contains('destination') == true,
    );

    _createCurrentLocationMarker();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> centerOnCurrentLocation() async {
    if (!_mapReady) return;

    try {
      final position = await _determinePosition();
      final newLocation = LatLng(position.latitude, position.longitude);

      _currentLocation = newLocation;
      _mapController.move(newLocation, 15.0);
      _createCurrentLocationMarker();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }
}

// Clase RouteOption
class RouteOption {
  final String name;
  final List<LatLng> points;
  final double distance;
  final int duration;
  final double safetyLevel;
  final bool isRecommended;

  RouteOption({
    required this.name,
    required this.points,
    required this.distance,
    required this.duration,
    required this.safetyLevel,
    required this.isRecommended,
  });

  Color get safetyColor {
    if (safetyLevel >= 80) return Colors.green;
    if (safetyLevel >= 60) return Colors.orange;
    return Colors.red;
  }

  String get safetyText {
    if (safetyLevel >= 80) return 'Segura';
    if (safetyLevel >= 60) return 'Moderada';
    return 'Peligrosa';
  }
}
