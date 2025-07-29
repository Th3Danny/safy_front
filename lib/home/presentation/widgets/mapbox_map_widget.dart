import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/route_suggestions_widget.dart';

// Importar componentes modulares
import 'map/map_layers/map_layers.dart';
import 'map/map_handlers/map_handlers.dart';
import 'map/services/route_service.dart';
import 'map/services/notification_service.dart';

class MapboxMapWidget extends StatefulWidget {
  const MapboxMapWidget({super.key});

  @override
  State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();

  // Variables para notificaciones dinámicas
  Timer? _locationUpdateTimer;
  double _currentZoom = 15.0;

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        // Manejar notificaciones dinámicas
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NotificationService.handleDynamicNotifications(mapViewModel);
          }
        });

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapViewModel.currentLocation,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 18,
                onMapReady: () {},
                onTap:
                    (tapPosition, point) =>
                        MapHandlers.handleMapTap(context, point),
                onPositionChanged: (position, hasGesture) {
                  if (_currentZoom != position.zoom) {
                    setState(() {
                      _currentZoom = position.zoom;
                    });
                  }

                  if (hasGesture) {
                    mapViewModel.loadClustersForMapViewFromWidget(
                      position.center,
                      position.zoom,
                    );
                  }
                },
              ),
              children: [
                // Capa base del mapa
                MapLayers.buildTileLayer(),

                // Capa de rutas con gradiente
                if (mapViewModel.currentRoute.isNotEmpty)
                  ...(() {
                    final validPoints = _filterValidCoordinates(
                      mapViewModel.currentRoute,
                    );
                    if (validPoints.isNotEmpty) {
                      return [
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: validPoints,
                              strokeWidth: 8.0,
                              color: Colors.blue.withOpacity(0.9),
                              borderStrokeWidth: 3.0,
                              borderColor: Colors.white,
                              gradientColors: [
                                Colors.blue.withOpacity(0.8),
                                Colors.lightBlue.withOpacity(0.6),
                              ],
                            ),
                          ],
                        ),
                      ];
                    }
                    return <Widget>[];
                  })(),

                // 🆕 NUEVO: Capa de todos los marcadores (incluye predicciones)
                MapLayers.buildAllMarkersLayer(mapViewModel),
              ],
            ),

            // Controles del mapa
            _buildAdvancedMapControls(context, mapViewModel),
          ],
        );
      },
    );
  }

  List<Marker> _buildDynamicMarkers(MapViewModel mapViewModel) {
    final markers = <Marker>[];

    // Marcador de ubicación actual con sombra
    markers.add(
      Marker(
        point: mapViewModel.currentLocation,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    );

    // Marcador de destino con sombra
    if (mapViewModel.endPoint != null) {
      markers.add(
        Marker(
          point: mapViewModel.endPoint!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 28),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildAdvancedMapControls(
    BuildContext context,
    MapViewModel mapViewModel,
  ) {
    return Stack(
      children: [
        // Botón de ubicación actual
        Positioned(
          bottom: 160,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              _mapController.move(mapViewModel.currentLocation, 16.0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Centrado en tu ubicación'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.my_location),
            mini: true,
          ),
        ),

        // Botón de sugerencias de ruta
        if (mapViewModel.currentRoute.isNotEmpty)
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed:
                  () => _showAdvancedRouteSuggestions(context, mapViewModel),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.route),
              mini: true,
            ),
          ),

        // Botón de detener navegación
        if (mapViewModel.isNavigating)
          Positioned(
            bottom: 220,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                mapViewModel.stopNavigation();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.stop, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Navegación detenida'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(Icons.stop),
              mini: true,
            ),
          ),
      ],
    );
  }

  void _showAdvancedRouteSuggestions(
    BuildContext context,
    MapViewModel mapViewModel,
  ) async {
    final startPoint = mapViewModel.currentLocation;
    final endPoint = mapViewModel.endPoint;

    if (endPoint == null) return;

    try {
      // Usar el RouteService para calcular rutas
      final routes = await _routeService.calculateRoutes(
        startPoint,
        endPoint,
        mapViewModel,
      );

      // Validar que las rutas no estén vacías
      final safeRoute = routes['safe'] ?? [];
      final fastRoute = routes['fast'] ?? [];
      final extraSafeRoute = routes['extraSafe'] ?? [];

      // Si todas las rutas están vacías, mostrar error
      if (safeRoute.isEmpty && fastRoute.isEmpty && extraSafeRoute.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron calcular las rutas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.8,
              builder:
                  (context, scrollController) => RouteSuggestionsWidget(
                    safeRoutePoints:
                        safeRoute.isNotEmpty
                            ? safeRoute
                            : mapViewModel.currentRoute,
                    fastRoutePoints:
                        fastRoute.isNotEmpty
                            ? fastRoute
                            : (safeRoute.isNotEmpty
                                ? safeRoute
                                : mapViewModel.currentRoute),
                    extraSafeRoutePoints:
                        extraSafeRoute.isNotEmpty
                            ? extraSafeRoute
                            : (safeRoute.isNotEmpty
                                ? safeRoute
                                : mapViewModel.currentRoute),
                    safeDistance: 1000.0,
                    safeDuration: 600,
                    safeSafetyLevel: 0.8,
                  ),
            ),
      );
    } catch (e) {
      // Fallback con ruta original
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.8,
              builder:
                  (context, scrollController) => RouteSuggestionsWidget(
                    safeRoutePoints: mapViewModel.currentRoute,
                    fastRoutePoints: mapViewModel.currentRoute,
                    extraSafeRoutePoints: mapViewModel.currentRoute,
                    safeDistance: 1000.0,
                    safeDuration: 600,
                    safeSafetyLevel: 0.8,
                  ),
            ),
      );
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  List<LatLng> _filterValidCoordinates(List<LatLng> points) {
    return points.where((point) {
      // Validar que las coordenadas estén en rangos válidos
      if (point.latitude < -90 || point.latitude > 90) {
        // Removed debug print
        return false;
      }
      if (point.longitude < -180 || point.longitude > 180) {
        // Removed debug print
        return false;
      }
      return true;
    }).toList();
  }
}
