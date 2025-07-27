import 'package:flutter/material.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/calculate_safe_routes_use_case.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';
import 'package:safy/core/errors/failures.dart';
import 'package:geolocator/geolocator.dart';

class MapViewModelEnhanced extends ChangeNotifier {
  final SearchPlacesUseCase _searchPlacesUseCase;
  final GetOpenRouteUseCase _getOpenRouteUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final CheckDangerZonesUseCase _checkDangerZonesUseCase;
  final GetDangerZonesUseCase _getDangerZonesUseCase;
  final CalculateSafeRoutesUseCase _calculateSafeRoutesUseCase;

  MapViewModelEnhanced({
    required SearchPlacesUseCase searchPlacesUseCase,
    required GetOpenRouteUseCase getOpenRouteUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required CheckDangerZonesUseCase checkDangerZonesUseCase,
    required GetDangerZonesUseCase getDangerZonesUseCase,
    required CalculateSafeRoutesUseCase calculateSafeRoutesUseCase,
  }) : _searchPlacesUseCase = searchPlacesUseCase,
       _getOpenRouteUseCase = getOpenRouteUseCase,
       _getCurrentLocationUseCase = getCurrentLocationUseCase,
       _checkDangerZonesUseCase = checkDangerZonesUseCase,
       _getDangerZonesUseCase = getDangerZonesUseCase,
       _calculateSafeRoutesUseCase = calculateSafeRoutesUseCase;

  // Estado interno
  Location? _currentLocation;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  List<DangerZone> _dangerZones = [];
  bool _showDangerZones = false;
  DangerZoneCheckResult? _currentLocationSafety;

  // Nuevas propiedades para rutas seguras
  List<RouteEntity> _safeRoutes = [];
  RouteEntity? _selectedRoute;
  bool _isCalculatingRoutes = false;
  String? _routeCalculationError;

  // Getters
  Location? get currentLocation => _currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get errorMessage => _errorMessage;
  List<DangerZone> get dangerZones => _dangerZones;
  bool get showDangerZones => _showDangerZones;
  DangerZoneCheckResult? get currentLocationSafety => _currentLocationSafety;
  List<RouteEntity> get safeRoutes => _safeRoutes;
  RouteEntity? get selectedRoute => _selectedRoute;
  bool get isCalculatingRoutes => _isCalculatingRoutes;
  String? get routeCalculationError => _routeCalculationError;

  // Obtener ubicación actual
  Future<void> getCurrentLocation() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentLocation = await _getCurrentLocationUseCase.execute();
      await _checkCurrentLocationSafety();
      await _loadNearbyDangerZones();
    } catch (e) {
      _errorMessage = 'Error obteniendo ubicación: $e';
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Verificar seguridad de ubicación actual
  Future<void> _checkCurrentLocationSafety() async {
    if (_currentLocation == null) return;

    try {
      _currentLocationSafety = await _checkDangerZonesUseCase.execute(
        _currentLocation!,
      );
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

  // 🛡️ NUEVO: Calcular rutas seguras
  Future<void> calculateSafeRoutes({
    required Location startPoint,
    required Location endPoint,
    TransportMode transportMode = TransportMode.walking,
  }) async {
    _isCalculatingRoutes = true;
    _routeCalculationError = null;
    _safeRoutes.clear();
    _selectedRoute = null;
    notifyListeners();

    try {
      print('[MapViewModelEnhanced] 🛡️ Calculando rutas seguras...');

      _safeRoutes = await _calculateSafeRoutesUseCase.execute(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
      );

      if (_safeRoutes.isNotEmpty) {
        // Seleccionar la ruta recomendada por defecto
        _selectedRoute = _safeRoutes.firstWhere(
          (route) => route.isRecommended,
          orElse: () => _safeRoutes.first,
        );

        print(
          '[MapViewModelEnhanced] ✅ ${_safeRoutes.length} rutas seguras calculadas',
        );
        print(
          '[MapViewModelEnhanced] 🎯 Ruta seleccionada: ${_selectedRoute?.name}',
        );
      } else {
        _routeCalculationError = 'No se encontraron rutas seguras disponibles';
      }
    } catch (e) {
      _routeCalculationError = 'Error calculando rutas seguras: $e';
      print('[MapViewModelEnhanced] ❌ Error: $e');
    } finally {
      _isCalculatingRoutes = false;
      notifyListeners();
    }
  }

  // Seleccionar una ruta específica
  void selectRoute(RouteEntity route) {
    _selectedRoute = route;
    print('[MapViewModelEnhanced] 🎯 Ruta seleccionada: ${route.name}');
    notifyListeners();
  }

  // Limpiar rutas
  void clearRoutes() {
    _safeRoutes.clear();
    _selectedRoute = null;
    _routeCalculationError = null;
    notifyListeners();
  }

  // Obtener información de seguridad de una ruta
  String getRouteSafetyInfo(RouteEntity route) {
    final safetyPercentage = route.safetyLevel.percentage;
    final warnings = route.warnings;

    String info =
        'Seguridad: ${safetyPercentage.toInt()}% - ${route.safetyLevel.description}';

    if (warnings.isNotEmpty) {
      info += '\nAdvertencias: ${warnings.join(', ')}';
    }

    return info;
  }

  // Verificar si una ruta es segura
  bool isRouteSafe(RouteEntity route) {
    return route.safetyLevel.percentage >= 70;
  }

  // Obtener el color de seguridad de una ruta
  Color getRouteSafetyColor(RouteEntity route) {
    final safetyPercentage = route.safetyLevel.percentage;

    if (safetyPercentage >= 80) return Colors.green;
    if (safetyPercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  // Toggle para mostrar/ocultar zonas de peligro
  void toggleDangerZones() {
    _showDangerZones = !_showDangerZones;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    _routeCalculationError = null;
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

  // Buscar lugares
  Future<List<dynamic>> searchPlaces(String query) async {
    if (_currentLocation == null) return [];

    try {
      return await _searchPlacesUseCase.execute(query);
    } catch (e) {
      print('Error buscando lugares: $e');
      return [];
    }
  }

  // Obtener ruta usando OpenRouteService
  Future<List<List<double>>> getRoute({
    required List<double> start,
    required List<double> end,
  }) async {
    try {
      return await _getOpenRouteUseCase.call(start: start, end: end);
    } catch (e) {
      print('Error obteniendo ruta: $e');
      return [];
    }
  }
}
