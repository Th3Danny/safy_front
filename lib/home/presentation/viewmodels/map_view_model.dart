// lib/features/home/presentation/viewmodels/map_view_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/entities/prediction.dart';
import 'dart:async';

import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_predictions_use_case.dart';

import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';
import 'package:safy/report/domain/usecases/get_clusters_use_case.dart'; // NUEVO
import 'package:safy/core/services/cluster_detection_service.dart';
import 'package:get_it/get_it.dart';

// Importar los mixins
import '../widgets/viewmodel/location_mixin.dart';
import '../widgets/viewmodel/route_mixin.dart';
import '../widgets/viewmodel/clusters_mixin.dart';
import '../widgets/viewmodel/reports_mixin.dart';
import '../widgets/viewmodel/search_mixin.dart';
import '../widgets/viewmodel/markers_mixin.dart';
import '../widgets/viewmodel/navigation_tracking_mixin.dart';
import '../widgets/viewmodel/predictions_mixin.dart';
import 'package:safy/core/services/security/gps_spoofing_detector.dart';

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
        NavigationTrackingMixin,
        PredictionsMixin {
  // ============================================================================
  // DEPENDENCIAS E INYECCIÓN
  // ============================================================================

  @override
  final SearchPlacesUseCase? searchPlacesUseCase;

  @override
  final GetReportsForMapUseCase? getReportsForMapUseCase;

  // NUEVO: Caso de uso para clusters
  @override
  final GetClustersUseCase? getClustersUseCase;

  // 🆕 NUEVO: Caso de uso para predicciones
  @override
  final GetPredictionsUseCase? getPredictionsUseCase;

  MapViewModel({
    this.searchPlacesUseCase,
    this.getReportsForMapUseCase,
    this.getClustersUseCase, // NUEVO
    this.getPredictionsUseCase, // 🆕 NUEVO
  }) {
    // Listener para cambios de zoom y movimiento del mapa
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove ||
          event is MapEventMoveEnd ||
          event is MapEventMoveStart) {
        final newZoom = _mapController.camera.zoom;
        if (newZoom != _currentZoom) {
          _currentZoom = newZoom;
          notifyListeners();
        }

        // Cargar clusters dinámicamente según la vista del mapa
        _loadClustersForMapView();
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

  // Propiedades para carga dinámica de clusters
  LatLng? _lastMapCenter;
  double _lastMapZoom = 15.0;
  bool _isLoadingClusters = false;
  Timer? _clusterLoadDebounceTimer;

  // ============================================================================
  // 🔒 PROPIEDADES DE SEGURIDAD GPS
  // ============================================================================

  // Getter para acceder al resultado de detección de GPS falso
  SpoofingDetectionResult? get gpsSpoofingResult => lastSpoofingResult;

  // ============================================================================
  // 🚨 PROPIEDADES DE ALERTAS DE ZONAS PELIGROSAS
  // ============================================================================

  ClusterEntity? _currentDangerZone;
  ClusterEntity? get currentDangerZone => _currentDangerZone;

  double? _currentDangerDistance;
  double? get currentDangerDistance => _currentDangerDistance;

  bool _showDangerAlert = false;
  bool get showDangerAlert => _showDangerAlert;

  // ============================================================================
  // 🛣️ MÉTODOS DE RUTA
  // ============================================================================

  // Método para establecer la ruta actual
  void setCurrentRoute(List<LatLng> route) {
    // Crear un RouteOption temporal para usar el método existente
    final routeOption = RouteOption(
      name: 'Ruta Calculada',
      points: route,
      distance: 0.0,
      duration: 0,
      safetyLevel: 1.0,
      isRecommended: true,
    );
    selectRoute(routeOption);
  }

  // Propiedad para el nombre de la ruta actual
  String? get currentRouteName => _currentRouteName;
  String? _currentRouteName;

  // Método para establecer la ruta con nombre
  void setCurrentRouteWithName(List<LatLng> route, String name) {
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print

    _currentRouteName = name;
    final routeOption = RouteOption(
      name: name,
      points: route,
      distance: 0.0,
      duration: 0,
      safetyLevel: 1.0,
      isRecommended: name.contains('Segura'),
    );

    // Removed debug print
    selectRoute(routeOption);

    // 🆕 NUEVO: Cargar predicciones automáticamente para la ruta
    if (route.isNotEmpty) {
      // Removed debug print
      loadPredictionsForRouteAutomatically(route);
    }

    // Removed debug print
    // Removed debug print
    notifyListeners();
    // Removed debug print
  }

  // Getter para verificar si el GPS está siendo falsificado
  bool get isGpsBeingSpoofed => isGpsSpoofed;

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

    // 🆕 NUEVO: Agregar marcadores de predicciones si están activados
    if (showPredictions) {
      allMarkers.addAll(predictionMarkers);
      // Removed debug print
    }

    return allMarkers;
  }

  // ============================================================================
  // INICIALIZACIÓN PRINCIPAL
  // ============================================================================

  Future<void> initializeMap() async {
    try {
      // 1. Obtener ubicación actual
      await determineCurrentLocation();

      // 2. Cargar clusters de zonas peligrosas basados en ubicación actual
      await loadDangerousClustersWithCurrentLocation();

      // 3. Opcional: Cargar reportes individuales (si los necesitas)
      // await loadDangerZonesWithCurrentLocation();

      // 4. Crear marcador de ubicación actual
      createCurrentLocationMarker(currentLocation, false);

      // 5. Iniciar seguimiento de ubicación (esto también inicializa el servicio de detección de clusters)
      startLocationTracking();

      // 🚨 NUEVO: Configurar callback para alertas de zonas peligrosas
      _setupDangerZoneAlertCallback();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método específico para cargar clusters con ubicación actual
  Future<void> loadDangerousClustersWithCurrentLocation() async {
    try {
      final freshLocation = await getCurrentLocationForReports();
      await loadDangerousClusters(freshLocation, zoom: currentZoom);
    } catch (e) {
      _errorMessage = 'Error cargando zonas peligrosas: $e';
      notifyListeners();
    }
  }

  // Método opcional para cargar reportes individuales
  Future<void> loadDangerZonesWithCurrentLocation() async {
    try {
      final freshLocation = await getCurrentLocationForReports();
      await loadDangerZones(freshLocation, zoom: currentZoom);
    } catch (e) {
      _errorMessage = 'Error cargando reportes: $e';
      notifyListeners();
    }
  }

  void onMapReady() {
    _mapReady = true;
    notifyListeners();
    _moveToCurrentLocation();

    // Inicializar clusters cuando el mapa está listo
    // Removed debug print
    initializeMapClusters();
  }

  void _moveToCurrentLocation() {
    if (_mapReady) {
      try {
        _mapController.move(currentLocation, 15.0);
      } catch (e) {}
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
    } else {
      // Si no estamos navegando, solo actualizar el marcador de ubicación
      // pero mantener el zoom y posición del mapa para no molestar al usuario
      if (_mapReady) {
        // Solo actualizar el marcador sin mover la cámara
        print(
          '[MapViewModel] 📍 Ubicación actualizada: (${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})',
        );
      }
    }
  }

  // 🚨 NUEVO: Implementar método para obtener clusters actuales
  @override
  List<ClusterEntity> getCurrentClusters() {
    return clusters;
  }

  // 🚨 NUEVO: Configurar callback para alertas de zonas peligrosas
  void _setupDangerZoneAlertCallback() {
    // Obtener el servicio de detección de clusters desde GetIt
    try {
      final clusterDetectionService = GetIt.instance<ClusterDetectionService>();
      clusterDetectionService.setAlertCallback(_onDangerZoneDetected);
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }

  // 🚨 NUEVO: Callback cuando se detecta una zona peligrosa
  void _onDangerZoneDetected(ClusterEntity cluster, double distance) {
    _currentDangerZone = cluster;
    _currentDangerDistance = distance;
    _showDangerAlert = true;
    notifyListeners();

    // Removed debug print
  }

  // 🚨 NUEVO: Ocultar alerta de zona peligrosa
  void hideDangerAlert() {
    _showDangerAlert = false;
    _currentDangerZone = null;
    _currentDangerDistance = null;
    notifyListeners();
  }

  // 🚨 NUEVO: Navegar a ruta segura
  void navigateToSafeRoute() {
    if (_currentDangerZone != null) {
      // Aquí podrías implementar la lógica para calcular una ruta que evite la zona peligrosa
      // Removed debug print
      hideDangerAlert();
    }
  }

  // 🚨 NUEVO: Reportar incidente
  void reportIncident() {
    if (_currentDangerZone != null) {
      // Aquí podrías navegar a la pantalla de reportes
      // Removed debug print
      hideDangerAlert();
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

      // Opcional: Mostrar información detallada del cluster
      _showClusterDetails(cluster);
    }
  }

  @override
  void onClustersToggled(bool visible) {
    // Removed debug print
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
    // 🆕 NUEVO: Cargar predicciones automáticamente cuando se selecciona una ruta
    if (route.points.isNotEmpty) {
      // Removed debug print
      loadPredictionsForRouteAutomatically(route.points);
    }
  }

  @override
  void onRoutesCleared() {
    clearRouteMarkers();
    hideRoutePanel();

    // 🆕 NUEVO: Limpiar predicciones cuando se limpia la ruta
    clearPredictions();

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
    // Removed debug print // Debug print
    _mapController.move(placeLocation, 15.0);
    addDestinationMarker(placeLocation, place.displayName);
    setEndPoint(placeLocation);

    if (startPoint == null) {
      // Removed debug print // Debug print
      setStartPoint(currentLocation);
    } else {
      // Removed debug print // Debug print
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
      // Removed debug print
      // Removed debug print
      // Removed debug print
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
      // Removed debug print

      // Solo actualizar si los clusters están visibles
      if (showClusters) {
        await loadDangerousClusters(newCenter, zoom: newZoom);
      }
    } catch (e) {
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
      await loadDangerousClustersWithCurrentLocation();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
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
    // Limpiar marcadores de ruta
    clearRouteMarkers();

    // Ocultar panel de rutas
    hideRoutePanel();

    // Limpiar errores
    _errorMessage = null;

    // 🆕 NUEVO: Limpiar predicciones cuando se limpian todas las rutas
    clearPredictions();

    // Limpiar rutas del RouteMixin sin recursión
    clearRouteSilently();

    notifyListeners();
  }

  // 🧭 NUEVO: Método para iniciar navegación con seguimiento
  void startNavigationWithTracking() {
    if (currentRoute.isEmpty) {
      return;
    }

    // Removed debug print

    // Iniciar navegación normal
    startNavigation();

    // Iniciar seguimiento de navegación
    startNavigationTracking(currentRoute, currentLocation);
  }

  // ⏹️ NUEVO: Método para detener navegación
  void stopNavigation() {
    // Removed debug print

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
  // IMPLEMENTACIÓN DE CALLBACKS DE PREDICTIONS_MIXIN
  // ============================================================================

  @override
  void onPredictionSelected(Prediction prediction) {
    if (_mapReady) {
      final predictionLocation = LatLng(
        prediction.location.latitude,
        prediction.location.longitude,
      );
      _mapController.move(predictionLocation, 17.0);
      // Removed debug print
    }
  }

  @override
  void onPredictionsToggled(bool visible) {
    // Removed debug print
    notifyListeners();
  }

  // ============================================================================
  // IMPLEMENTACIÓN DE CALLBACKS DE NAVIGATION_TRACKING_MIXIN
  // ============================================================================

  @override
  void updateRouteDisplay(List<LatLng> route) {
    // Removed debug print
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
    // Removed debug print

    // Detener navegación automáticamente sin recursión
    // Removed debug print

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
  // 🔒 IMPLEMENTACIÓN DE CALLBACKS DE SEGURIDAD GPS
  // ============================================================================

  @override
  void onGpsSpoofingDetected(SpoofingDetectionResult result) {
    // Notificar cambios
    notifyListeners();
  }

  // 🔒 NUEVO: Método para resetear el detector de GPS falso
  void resetGpsSpoofingDetector() {
    super.resetGpsSpoofingDetector();
    notifyListeners();
  }

  // ============================================================================
  // 🗺️ CARGA DINÁMICA DE CLUSTERS SEGÚN VISTA DEL MAPA
  // ============================================================================

  /// Método para inicializar clusters cuando el mapa está listo
  void initializeMapClusters() {
    // Removed debug print
    if (_mapController.camera.center != null) {
      _loadClustersForMapView();
    }
  }

  /// Método público para cargar clusters desde el widget del mapa
  void loadClustersForMapViewFromWidget(LatLng center, double zoom) {
    // Removed debug print
    // Removed debug print
    // Removed debug print

    // Actualizar propiedades del ViewModel
    _currentZoom = zoom;

    // Llamar al método interno
    _performClusterLoad(center, zoom);
  }

  /// Método de prueba para verificar que el listener funciona
  void testMapListener() {
    // Removed debug print
    // Removed debug print
    // Removed debug print

    // Forzar una carga de clusters para probar
    _loadClustersForMapView();
  }

  /// Carga clusters dinámicamente según la vista actual del mapa
  void _loadClustersForMapView() {
    if (_isLoadingClusters) {
      // Removed debug print
      return;
    }

    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;

    print(
      '[MapViewModel] 🗺️ Movimiento detectado: ${currentCenter.latitude}, ${currentCenter.longitude} (zoom: $currentZoom)',
    );

    // Verificar si la vista del mapa ha cambiado significativamente
    if (_lastMapCenter != null) {
      final distance = Distance().as(
        LengthUnit.Kilometer,
        _lastMapCenter!,
        currentCenter,
      );

      print(
        '[MapViewModel] 📏 Distancia desde última carga: ${distance.toStringAsFixed(2)}km',
      );

      // Solo recargar si se movió más de 0.5km o cambió el zoom significativamente
      if (distance < 0.5 && (currentZoom - _lastMapZoom).abs() < 1.0) {
        // Removed debug print
        return;
      }
    }

    // Cancelar timer anterior si existe
    _clusterLoadDebounceTimer?.cancel();

    // Usar debounce más corto para respuesta más rápida
    _clusterLoadDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      // Removed debug print
      _performClusterLoad(currentCenter, currentZoom);
    });
  }

  /// Realiza la carga efectiva de clusters
  void _performClusterLoad(LatLng center, double zoom) async {
    if (_isLoadingClusters) {
      // Removed debug print
      return;
    }

    // Removed debug print
    _isLoadingClusters = true;
    _lastMapCenter = center;
    _lastMapZoom = zoom;

    print(
      '[MapViewModel] 🗺️ Cargando clusters para vista: ${center.latitude}, ${center.longitude} (zoom: $zoom)',
    );

    try {
      // Cargar clusters para el centro de la vista del mapa
      // Removed debug print
      await loadClustersForMapView(center, zoom: zoom, radiusKm: 5.0);

      // Removed debug print
      notifyListeners(); // Asegurar que la UI se actualice
    } catch (e) {
      // Removed debug print
    } finally {
      _isLoadingClusters = false;
      // Removed debug print
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    _clusterLoadDebounceTimer?.cancel();
    disposeLocation();
    clearClusters();
    _mapController.dispose();
    super.dispose();
  }
}
