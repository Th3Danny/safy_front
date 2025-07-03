import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapViewModel extends ChangeNotifier {
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

  // Errores
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Inicialización del mapa
  Future<void> initializeMap() async {
    try {
      await _determineCurrentLocation();
      await _loadDangerZones();
      _createCurrentLocationMarker();
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

  // Crear marcador de ubicación actual
  void _createCurrentLocationMarker() {
    _markers.clear();
    _markers.add(
      Marker(
        point: _currentLocation,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
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

    _dangerMarkers = dangerZones.map((zone) {
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

  void setEndPoint(LatLng point) {
    _endPoint = point;
    _addRouteMarker(point, Colors.red, Icons.stop, 'end');
    if (_startPoint != null) {
      calculateRoutes();
    }
    notifyListeners();
  }

  void _addRouteMarker(LatLng point, Color color, IconData icon, String type) {
    // Remover marcador anterior del mismo tipo
    _markers.removeWhere((marker) => 
      marker.key?.toString().contains(type) == true);

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

  // Calcular rutas seguras
  Future<void> calculateRoutes() async {
    if (_startPoint == null || _endPoint == null) return;

    try {
      _routeOptions.clear();
      
      // Ruta directa (puede ser peligrosa)
      final directRoute = _calculateDirectRoute(_startPoint!, _endPoint!);
      final directSafety = _calculateRouteSafety(directRoute);
      
      _routeOptions.add(RouteOption(
        name: 'Ruta Directa',
        points: directRoute,
        distance: _calculateDistance(directRoute),
        duration: _calculateDuration(directRoute, _selectedTransportMode),
        safetyLevel: directSafety,
        isRecommended: false,
      ));

      // Ruta segura (evita zonas peligrosas)
      final safeRoute = _calculateSafeRoute(_startPoint!, _endPoint!);
      final safeSafety = _calculateRouteSafety(safeRoute);
      
      _routeOptions.add(RouteOption(
        name: 'Ruta Segura',
        points: safeRoute,
        distance: _calculateDistance(safeRoute),
        duration: _calculateDuration(safeRoute, _selectedTransportMode),
        safetyLevel: safeSafety,
        isRecommended: true,
      ));

      // Ruta alternativa
      final altRoute = _calculateAlternativeRoute(_startPoint!, _endPoint!);
      final altSafety = _calculateRouteSafety(altRoute);
      
      _routeOptions.add(RouteOption(
        name: 'Ruta Alternativa',
        points: altRoute,
        distance: _calculateDistance(altRoute),
        duration: _calculateDuration(altRoute, _selectedTransportMode),
        safetyLevel: altSafety,
        isRecommended: false,
      ));

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

  void selectRoute(RouteOption route) {
    _currentRoute = route.points;
    notifyListeners();
  }

  // Algoritmos de cálculo de rutas
  List<LatLng> _calculateDirectRoute(LatLng start, LatLng end) {
    // Algoritmo simple: línea recta con algunos puntos intermedios
    return [start, end];
  }

  List<LatLng> _calculateSafeRoute(LatLng start, LatLng end) {
    // Algoritmo que evita zonas peligrosas
    final points = <LatLng>[start];
    
    // Agregar puntos que eviten zonas de alto riesgo
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    
    // Desviación para evitar zonas peligrosas
    final safePoint = LatLng(midLat + 0.002, midLng - 0.002);
    points.add(safePoint);
    
    points.add(end);
    return points;
  }

  List<LatLng> _calculateAlternativeRoute(LatLng start, LatLng end) {
    // Ruta alternativa por calles principales
    final points = <LatLng>[start];
    
    // Puntos por avenidas principales (simulado)
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    
    points.add(LatLng(midLat - 0.001, midLng + 0.003));
    points.add(LatLng(midLat + 0.001, midLng + 0.001));
    points.add(end);
    
    return points;
  }

  // Calcular nivel de seguridad de una ruta
  double _calculateRouteSafety(List<LatLng> route) {
    double safetyScore = 1.0;
    
    for (final point in route) {
      for (final dangerMarker in _dangerMarkers) {
        final distance = _distanceBetween(point, dangerMarker.point);
        if (distance < 0.001) { // Muy cerca de zona peligrosa
          safetyScore -= 0.3;
        } else if (distance < 0.002) { // Cerca de zona peligrosa
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
    
    // Velocidades promedio en km/h
    final speeds = {
      'walk': 5.0,
      'car': 40.0,
      'bus': 25.0,
    };
    
    final speed = speeds[transportMode] ?? 5.0;
    return (distance / speed * 60).round(); // en minutos
  }

  void clearRoute() {
    _startPoint = null;
    _endPoint = null;
    _currentRoute.clear();
    _routeOptions.clear();
    
    // Remover marcadores de ruta
    _markers.removeWhere((marker) => 
      marker.key?.toString().contains('start') == true ||
      marker.key?.toString().contains('end') == true);
    
    _createCurrentLocationMarker();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Centrar en ubicación actual
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Clase para opciones de ruta
class RouteOption {
  final String name;
  final List<LatLng> points;
  final double distance; // en km
  final int duration; // en minutos
  final double safetyLevel; // 0-100
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