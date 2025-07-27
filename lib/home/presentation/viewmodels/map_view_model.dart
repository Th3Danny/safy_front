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
import '../widgets/viewmodel/navigation_tracking_mixin.dart';

/// ViewModel principal del mapa que integra todas las funcionalidades
/// usando mixins para mejor organización y mantenibilidad
class MapViewModel extends ChangeNotifier
    with
        LocationMixin,
        RouteMixin,
        ClustersMixin,
        ReportsMixin,
        SearchMixin,
        MarkersMixin,
        NavigationTrackingMixin {
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
  }) {
    // Listener para cambios de zoom
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove ||
          event is MapEventMoveEnd ||
          event is MapEventMoveStart) {
        final newZoom = _mapController.camera.zoom;
        if (newZoom != _currentZoom) {
          _currentZoom = newZoom;
          notifyListeners();
        }
      }
    });
  }

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

  double _currentZoom = 15.0;
  double get currentZoom => _currentZoom;

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
      final freshLocation = await getCurrentLocationForReports();
      await loadDangerousClusters(freshLocation, zoom: currentZoom);
      print(
        '[MapViewModel] ✅ Clusters de zonas peligrosas cargados correctamente',
      );
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
      await loadDangerZones(freshLocation, zoom: currentZoom);
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

    // Si estamos navegando, actualizar el seguimiento de navegación
    if (isNavigating) {
      updateNavigationPosition(location);

      if (_mapReady) {
        _mapController.move(location, _mapController.camera.zoom);
      }
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
      print(
        '[MapViewModel] 🔄 Recargando clusters por cambio de ubicación (${distanceMoved.toInt()}m)',
      );
      loadDangerousClusters(newLocation);
    }
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE CLUSTERS_MIXIN
  // ============================================================================

  @override
  void onClusterSelected(ClusterEntity cluster) {
    if (_mapReady) {
      final clusterLocation = LatLng(
        cluster.centerLatitude,
        cluster.centerLongitude,
      );
      _mapController.move(clusterLocation, 17.0);

      print(
        '[MapViewModel] 🎯 Cluster seleccionado: ${cluster.dominantIncidentName}',
      );
      print(
        '[MapViewModel] 📊 Información: ${cluster.reportCount} reportes, zona ${cluster.zone}',
      );

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
    _errorMessage =
        'Zona ${cluster.severity}: ${cluster.dominantIncidentName} (${cluster.reportCount} reportes)';
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
    print(
      '[MapViewModel] 👁️ Reportes individuales ${visible ? 'mostrados' : 'ocultados'}',
    );
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
    print(
      '[MapViewModel] 🛣️ Ruta seleccionada: ${route.name} - ${route.safetyText}',
    );
  }

  @override
  void onRoutesCleared() {
    print('[MapViewModel] 🧹 Limpiando rutas del mapa...');
    clearRouteMarkers();
    hideRoutePanel();

    // NO llamar a clearRoute() aquí para evitar recursión infinita
    // Las rutas ya se limpian en el RouteMixin

    notifyListeners();
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
    print('[MapViewModel] 🔍 Lugar seleccionado: ${place.displayName}'); // Debug print
    _mapController.move(placeLocation, 15.0);
    addDestinationMarker(placeLocation, place.displayName);
    setEndPoint(placeLocation);

    if (startPoint == null) {
      print('[MapViewModel] 📍 Estableciendo punto de inicio en ubicación actual.'); // Debug print
      setStartPoint(currentLocation);
    } else {
      print('[MapViewModel] 📍 Ya existe un punto de inicio. Recalculando rutas.'); // Debug print
      // No necesitas llamar a calculateRoutes() aquí, ya que setEndPoint() o setStartPoint() lo harán automáticamente
      // si ambos puntos están definidos.
    }
  }

  // ============================================================================
  // LISTENER AUTOMÁTICO PARA CAMBIOS DE MAPA
  // ============================================================================

  // Variables para controlar la frecuencia de actualización
  DateTime _lastClusterUpdate = DateTime.now();
  static const Duration _clusterUpdateCooldown = Duration(
    seconds: 1,
  ); // Reducido a 1 segundo para mejor respuesta
  double _lastZoom = 15.0;
  LatLng _lastCenter = LatLng(16.7569, -93.1292);
  bool _isUpdatingClusters =
      false; // Evitar actualizaciones múltiples simultáneas

  /// Listener automático para cambios de posición y zoom del mapa
  void onMapPositionChanged(dynamic position) {
    // Evitar actualizaciones múltiples simultáneas
    if (_isUpdatingClusters) {
      return;
    }

    final newZoom = position.zoom ?? _lastZoom;
    final newCenter = position.center ?? _lastCenter;
    final now = DateTime.now();

    // Verificar si ha pasado suficiente tiempo desde la última actualización
    if (now.difference(_lastClusterUpdate) < _clusterUpdateCooldown) {
      return;
    }

    // Detectar cambios significativos
    final zoomChanged =
        (newZoom - _lastZoom).abs() >
        0.3; // Reducido a 0.3 para mayor sensibilidad
    final centerChanged =
        _calculateDistance(newCenter, _lastCenter) >
        300; // Reducido a 300 metros

    if (zoomChanged || centerChanged) {
      print('[MapViewModel] 🔄 Cambio detectado en el mapa:');
      print('[MapViewModel] 📍 Zoom: $_lastZoom → $newZoom');
      print('[MapViewModel] 📍 Centro: $_lastCenter → $newCenter');
      print(
        '[MapViewModel] 🔍 Distancia movida: ${_calculateDistance(newCenter, _lastCenter).toInt()}m',
      );

      _lastZoom = newZoom;
      _lastCenter = newCenter;
      _lastClusterUpdate = now;

      // Actualizar clusters automáticamente
      _updateClustersForNewPosition(newCenter, newZoom);
    }
  }

  /// Actualizar clusters para la nueva posición y zoom
  Future<void> _updateClustersForNewPosition(
    LatLng newCenter,
    double newZoom,
  ) async {
    if (_isUpdatingClusters) return; // Evitar actualizaciones múltiples

    try {
      _isUpdatingClusters = true;
      print('[MapViewModel] 🔄 Actualizando clusters para nueva posición...');

      // Solo actualizar si los clusters están visibles
      if (showClusters) {
        await loadDangerousClusters(newCenter, zoom: newZoom);
        print('[MapViewModel] ✅ Clusters actualizados automáticamente');
      }
    } catch (e) {
      print('[MapViewModel] ❌ Error actualizando clusters automáticamente: $e');
    } finally {
      _isUpdatingClusters = false;
    }
  }

  /// Calcular distancia entre dos puntos en metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Obtener información del estado del listener automático
  Map<String, dynamic> getAutoUpdateInfo() {
    return {
      'isUpdating': _isUpdatingClusters,
      'lastUpdate': _lastClusterUpdate,
      'currentZoom': _lastZoom,
      'currentCenter': _lastCenter,
      'showClusters': showClusters,
      'clustersCount': clusterMarkers.length,
    };
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

  // 🧹 NUEVO: Método para limpiar completamente todas las rutas
  void clearAllRoutes() {
    print('[MapViewModel] 🧹 Limpiando todas las rutas y marcadores...');

    // Limpiar marcadores de ruta
    clearRouteMarkers();

    // Ocultar panel de rutas
    hideRoutePanel();

    // Limpiar errores
    _errorMessage = null;

    // Limpiar rutas del RouteMixin sin recursión
    clearRouteSilently();

    notifyListeners();
  }

  // 🧭 NUEVO: Método para iniciar navegación con seguimiento
  void startNavigationWithTracking() {
    if (currentRoute.isEmpty) {
      print('[MapViewModel] ⚠️ No hay ruta para navegar');
      return;
    }

    print('[MapViewModel] 🧭 Iniciando navegación con seguimiento...');

    // Iniciar navegación normal
    startNavigation();

    // Iniciar seguimiento de navegación
    startNavigationTracking(currentRoute, currentLocation);
  }

  // ⏹️ NUEVO: Método para detener navegación
  void stopNavigation() {
    print('[MapViewModel] ⏹️ Deteniendo navegación...');

    // Detener navegación del LocationMixin
    super.stopNavigation();

    // Detener seguimiento de navegación
    stopNavigationTracking();

    // Limpiar todas las rutas
    clearAllRoutes();

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
  // IMPLEMENTACIÓN DE CALLBACKS DE NAVIGATION_TRACKING_MIXIN
  // ============================================================================

  @override
  void updateRouteDisplay(List<LatLng> route) {
    print(
      '[MapViewModel] 🛣️ Actualizando visualización de ruta: ${route.length} puntos',
    );
    // Actualizar la ruta actual del RouteMixin
    selectRoute(
      RouteOption(
        name: 'Ruta en Progreso',
        points: route,
        distance: _calculateTotalDistance(route),
        duration: _calculateTotalDuration(route),
        safetyLevel: 85.0,
        isRecommended: true,
      ),
    );
    notifyListeners();
  }

  @override
  void onDestinationReached() {
    print('[MapViewModel] 🎯 ¡Destino alcanzado!');

    // Detener navegación automáticamente sin recursión
    print('[MapViewModel] ⏹️ Deteniendo navegación por destino alcanzado...');

    // Detener navegación del LocationMixin
    super.stopNavigation();

    // Detener seguimiento de navegación
    stopNavigationTracking();

    // Limpiar todas las rutas
    clearAllRoutes();

    // Notificar al usuario (se manejará en la UI)
    _errorMessage = null;
    notifyListeners();
  }

  // Métodos auxiliares para cálculos
  double _calculateTotalDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += Distance().as(
        LengthUnit.Kilometer,
        route[i],
        route[i + 1],
      );
    }
    return totalDistance;
  }

  int _calculateTotalDuration(List<LatLng> route) {
    final distance = _calculateTotalDistance(route);
    const double speed = 5.0; // km/h para caminar
    return (distance / speed * 60).round();
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
