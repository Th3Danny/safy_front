import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';

// Importar los mixins
import '../widgets/viewmodel/location_mixin.dart';
import '../widgets/viewmodel/route_mixin.dart';
import '../widgets/viewmodel/reports_mixin.dart';
import '../widgets/viewmodel/search_mixin.dart';
import '../widgets/viewmodel/markers_mixin.dart';

/// ViewModel principal del mapa que integra todas las funcionalidades
/// usando mixins para mejor organización y mantenibilidad
class MapViewModel extends ChangeNotifier
    with LocationMixin, RouteMixin, ReportsMixin, SearchMixin, MarkersMixin {
  // ============================================================================
  // DEPENDENCIAS E INYECCIÓN
  // ============================================================================

  @override
  final SearchPlacesUseCase? searchPlacesUseCase;

  @override
  final GetOpenRouteUseCase? getOpenRouteUseCase;

  @override
  final GetReportsForMapUseCase? getReportsForMapUseCase;

  MapViewModel({
    this.searchPlacesUseCase,
    this.getOpenRouteUseCase,
    this.getReportsForMapUseCase,
  });

  // ============================================================================
  // CONFIGURACIÓN DEL MAPA
  // ============================================================================

  final MapController _mapController = MapController();
  MapController get mapController => _mapController;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _mapReady = false;
  bool get mapReady => _mapReady;

  bool _showRoutePanel = false; // ← AGREGAR ESTO
  bool get showRoutePanel => _showRoutePanel; // ← AGREGAR ESTO

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ============================================================================
  // INICIALIZACIÓN PRINCIPAL
  // ============================================================================

  Future<void> initializeMap() async {
    try {
      await determineCurrentLocation();
      await loadDangerZones(currentLocation);
      createCurrentLocationMarker(currentLocation, false);
      startLocationTracking();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void onMapReady() {
    _mapReady = true;
    notifyListeners();
    _moveToCurrentLocation();
  }

  void _moveToCurrentLocation() {
    if (_mapReady) {
      try {
        _mapController.move(currentLocation, 15.0);
      } catch (e) {
        print("Error moviendo mapa: $e");
      }
    }
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE LOCATION_MIXIN
  // ============================================================================

  @override
  void onLocationUpdated(LatLng location) {
    createCurrentLocationMarker(location, isNavigating);
    if (isNavigating && _mapReady) {
      _mapController.move(location, _mapController.camera.zoom);
    }
  }

  @override
  void onLocationCentered(LatLng location) {
    if (_mapReady) {
      _mapController.move(location, 15.0);
      createCurrentLocationMarker(location, isNavigating);
    }
  }

  @override
  void onLocationError(String error) {
    _errorMessage = error;
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE ROUTE_MIXIN
  // ============================================================================

  @override
  void onStartPointChanged(LatLng point) {
    addRouteMarker(point, Colors.green, Icons.play_arrow, 'start');
  }

  @override
  void onEndPointChanged(LatLng point) {
    addRouteMarker(point, Colors.red, Icons.stop, 'end');
  }

  @override
  void onStartPointCleared() {
    clearRouteMarkers();
    createCurrentLocationMarker(currentLocation, isNavigating);
  }

  @override
  void onEndPointCleared() {
    clearRouteMarkers();
    createCurrentLocationMarker(currentLocation, isNavigating);
  }

  @override
  void onRouteSelected(RouteOption route) {
    print('Ruta seleccionada: ${route.name} - ${route.safetyText}');
  }

  @override
  void onRoutesCleared() {
    clearRouteMarkers();
    hideRoutePanel(); // ← AGREGAR ESTO
  }

  @override
  void onRoutesPanelShow() {
    // ← CAMBIAR A ESTO
    _showRoutePanel = true;
    notifyListeners();
  }

  @override
  void onRouteError(String error) {
    _errorMessage = error;
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE SEARCH_MIXIN
  // ============================================================================

  @override
  void onSearchSuccess() {
    _errorMessage = null;
  }

  @override
  void onSearchError(String error) {
    _errorMessage = error;
  }

  @override
  void onSearchCleared() {
    _errorMessage = null;
  }

  @override
  void onPlaceSelected(
    Place place,
    LatLng placeLocation,
    LatLng currentLocation,
  ) {
    _mapController.move(placeLocation, 15.0);
    addDestinationMarker(placeLocation, place.displayName);
    setEndPoint(placeLocation);

    if (startPoint == null) {
      setStartPoint(currentLocation);
    }
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE REPORTS_MIXIN
  // ============================================================================

  @override
  void onReportSelected(ReportInfoEntity report) {
    if (_mapReady) {
      final reportLocation = LatLng(report.latitude, report.longitude);
      _mapController.move(reportLocation, 17.0);
    }
  }

  @override
  void onDangerZonesToggled(bool visible) {
    print('Zonas peligrosas ${visible ? 'mostradas' : 'ocultadas'}');
  }

  // ============================================================================
  // MÉTODOS PÚBLICOS SIMPLIFICADOS
  // ============================================================================

  Future<void> searchAndSelectPlace(String query) async {
    await searchPlaces(query, currentLocation);
  }

  void hideRoutePanel() {
    _showRoutePanel = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    disposeLocation();
    _mapController.dispose();
    super.dispose();
  }
}
