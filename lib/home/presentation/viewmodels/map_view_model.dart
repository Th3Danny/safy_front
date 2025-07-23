// lib/features/home/presentation/viewmodels/map_view_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/place.dart';

import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';

import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';
import 'package:safy/report/domain/usecases/get_clusters_use_case.dart'; // NUEVO

// Importar los mixins
import '../widgets/viewmodel/location_mixin.dart';
import '../widgets/viewmodel/route_mixin.dart';
import '../widgets/viewmodel/clusters_mixin.dart';
import '../widgets/viewmodel/reports_mixin.dart';
import '../widgets/viewmodel/search_mixin.dart';
import '../widgets/viewmodel/markers_mixin.dart';

/// ViewModel principal del mapa que integra todas las funcionalidades
/// usando mixins para mejor organización y mantenibilidad
class MapViewModel extends ChangeNotifier
    with LocationMixin, RouteMixin, ClustersMixin, ReportsMixin, SearchMixin, MarkersMixin {
  
  // ============================================================================
  // DEPENDENCIAS E INYECCIÓN
  // ============================================================================

  @override
  final SearchPlacesUseCase? searchPlacesUseCase;

  @override
  final GetOpenRouteUseCase? getOpenRouteUseCase;

  @override
  final GetReportsForMapUseCase? getReportsForMapUseCase;

  // NUEVO: Caso de uso para clusters
  @override
  final GetClustersUseCase? getClustersUseCase;

  MapViewModel({
    this.searchPlacesUseCase,
    this.getOpenRouteUseCase,
    this.getReportsForMapUseCase,
    this.getClustersUseCase, // NUEVO
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

  bool _showRoutePanel = false;
  bool get showRoutePanel => _showRoutePanel;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ============================================================================
  // TODOS LOS MARCADORES PARA EL MAPA
  // ============================================================================

  // Combinar todos los marcadores para mostrar en el mapa
  List<Marker> get allMapMarkers {
    final allMarkers = <Marker>[];
    
    // Agregar marcadores de ubicación y rutas
    allMarkers.addAll(markers);
    
    // Agregar clusters de zonas peligrosas si están activados
    if (showClusters) {
      allMarkers.addAll(clusterMarkers);
    }
    
    // Agregar reportes individuales si están activados (por si los necesitas después)
    if (showDangerZones) {
      allMarkers.addAll(dangerMarkers);
    }
    
    return allMarkers;
  }

  // ============================================================================
  // INICIALIZACIÓN PRINCIPAL
  // ============================================================================

  Future<void> initializeMap() async {
    try {
      print('[MapViewModel] 🚀 Inicializando mapa...');
      
      // 1. Obtener ubicación actual
      await determineCurrentLocation();
      print('[MapViewModel] ✅ Ubicación inicial obtenida');
      
      // 2. Cargar clusters de zonas peligrosas basados en ubicación actual
      await loadDangerousClustersWithCurrentLocation();
      
      // 3. Opcional: Cargar reportes individuales (si los necesitas)
      // await loadDangerZonesWithCurrentLocation();
      
      // 4. Crear marcador de ubicación actual
      createCurrentLocationMarker(currentLocation, false);
      
      // 5. Iniciar seguimiento de ubicación
      startLocationTracking();

      _isLoading = false;
      notifyListeners();
      
      print('[MapViewModel] 🎉 Mapa inicializado correctamente');
    } catch (e) {
      print('[MapViewModel] ❌ Error inicializando mapa: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método específico para cargar clusters con ubicación actual
  Future<void> loadDangerousClustersWithCurrentLocation() async {
    try {
      print('[MapViewModel] 📍 Cargando clusters de zonas peligrosas...');
      
      // Obtener ubicación fresca para asegurar precisión
      final freshLocation = await getCurrentLocationForReports();
      
      // Cargar clusters de zonas peligrosas
      await loadDangerousClusters(freshLocation);
      
      print('[MapViewModel] ✅ Clusters de zonas peligrosas cargados correctamente');
    } catch (e) {
      print('[MapViewModel] ❌ Error cargando clusters: $e');
      _errorMessage = 'Error cargando zonas peligrosas: $e';
      notifyListeners();
    }
  }

  // Método opcional para cargar reportes individuales
  Future<void> loadDangerZonesWithCurrentLocation() async {
    try {
      print('[MapViewModel] 📍 Cargando reportes individuales...');
      
      final freshLocation = await getCurrentLocationForReports();
      await loadDangerZones(freshLocation);
      
      print('[MapViewModel] ✅ Reportes individuales cargados correctamente');
    } catch (e) {
      print('[MapViewModel] ❌ Error cargando reportes individuales: $e');
      _errorMessage = 'Error cargando reportes: $e';
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
        print('[MapViewModel] 🗺️ Centrando mapa en ubicación actual');
        _mapController.move(currentLocation, 15.0);
      } catch (e) {
        print('[MapViewModel] ❌ Error moviendo mapa: $e');
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
    notifyListeners();
  }

  @override
  void onLocationChanged(LatLng newLocation, double distanceMoved) {
    // Si se movió más de 1km, recargar clusters
    if (distanceMoved > 1000) {
      print('[MapViewModel] 🔄 Recargando clusters por cambio de ubicación (${distanceMoved.toInt()}m)');
      loadDangerousClusters(newLocation);
    }
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE CLUSTERS_MIXIN
  // ============================================================================

  @override
  void onClusterSelected(ClusterEntity cluster) {
    if (_mapReady) {
      final clusterLocation = LatLng(cluster.centerLatitude, cluster.centerLongitude);
      _mapController.move(clusterLocation, 17.0);
      
      print('[MapViewModel] 🎯 Cluster seleccionado: ${cluster.dominantIncidentName}');
      print('[MapViewModel] 📊 Información: ${cluster.reportCount} reportes, zona ${cluster.zone}');
      
      // Opcional: Mostrar información detallada del cluster
      _showClusterDetails(cluster);
    }
  }

  @override
  void onClustersToggled(bool visible) {
    print('[MapViewModel] 👁️ Clusters ${visible ? 'mostrados' : 'ocultados'}');
    notifyListeners(); // Importante para actualizar allMapMarkers
  }

  // Mostrar detalles del cluster seleccionado
  void _showClusterDetails(ClusterEntity cluster) {
    // Aquí puedes implementar una función para mostrar más detalles
    // Por ejemplo, un bottom sheet o dialog con información del cluster
    _errorMessage = 'Zona ${cluster.severity}: ${cluster.dominantIncidentName} (${cluster.reportCount} reportes)';
    notifyListeners();
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE REPORTS_MIXIN (si los usas)
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
    print('[MapViewModel] 👁️ Reportes individuales ${visible ? 'mostrados' : 'ocultados'}');
    notifyListeners(); // Importante para actualizar allMapMarkers
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
    print('[MapViewModel] 🛣️ Ruta seleccionada: ${route.name} - ${route.safetyText}');
  }

  @override
  void onRoutesCleared() {
    clearRouteMarkers();
    hideRoutePanel();
  }

  @override
  void onRoutesPanelShow() {
    _showRoutePanel = true;
    notifyListeners();
  }

  @override
  void onRouteError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE SEARCH_MIXIN
  // ============================================================================

  @override
  void onSearchSuccess() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void onSearchError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void onSearchCleared() {
    _errorMessage = null;
    notifyListeners();
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
  // MÉTODOS PÚBLICOS PARA REFRESCAR DATOS
  // ============================================================================

  Future<void> refreshDangerousZones() async {
    try {
      print('[MapViewModel] 🔄 Refrescando clusters de zonas peligrosas...');
      await loadDangerousClustersWithCurrentLocation();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('[MapViewModel] ❌ Error refrescando clusters: $e');
      _errorMessage = 'Error refrescando zonas peligrosas: $e';
      notifyListeners();
    }
  }

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

  // Obtener información de seguridad de una ubicación
  String getLocationSafetyInfo(LatLng location) {
    return getZoneSafetyInfo(location);
  }

  // Verificar si una ubicación está en zona peligrosa
  bool isLocationDangerous(LatLng location) {
    return isPointInDangerousCluster(location);
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    print('[MapViewModel] 🧹 Limpiando recursos...');
    disposeLocation();
    clearClusters();
    _mapController.dispose();
    super.dispose();
  }
}