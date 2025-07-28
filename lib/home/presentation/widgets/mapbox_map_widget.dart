import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:async';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/data/datasources/mapbox_directions_client.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/home/presentation/widgets/route_suggestions_widget.dart';

class MapboxMapWidget extends StatefulWidget {
  const MapboxMapWidget({super.key});

  @override
  State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  final MapController _mapController = MapController();
  final MapboxDirectionsClient _directionsClient = MapboxDirectionsClient();

  // 🆕 VARIABLES PARA NOTIFICACIONES DINÁMICAS
  LatLng? _lastKnownLocation;
  double _notificationDistance = 500.0; // metros
  Set<String> _shownNotifications = {};
  Timer? _locationUpdateTimer;

  // 🆕 VARIABLE PARA ZOOM ACTUAL
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
        // 🆕 LOG PARA VERIFICAR RECONSTRUCCIÓN
        print('🗺️ [MapboxMapWidget] Widget reconstruido');
        print(
          '🗺️ [MapboxMapWidget] Ruta actual: ${mapViewModel.currentRoute.length} puntos',
        );
        print(
          '🗺️ [MapboxMapWidget] Nombre de ruta: ${mapViewModel.currentRouteName ?? 'N/A'}',
        );

        // 🆕 MANEJAR NOTIFICACIONES DINÁMICAS
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleDynamicNotifications(mapViewModel);
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
                onTap: (tapPosition, point) => _handleMapTap(context, point),
                onPositionChanged: (position, hasGesture) {
                  // 🆕 ACTUALIZAR ZOOM ACTUAL Y FORZAR RECONSTRUCCIÓN
                  if (_currentZoom != position.zoom) {
                    setState(() {
                      _currentZoom = position.zoom;
                    });
                  }

                  if (hasGesture) {
                    // 🗺️ CARGAR CLUSTERS DINÁMICAMENTE CUANDO SE MUEVE EL MAPA
                    print('[MapboxMapWidget] 🗺️ Mapa movido por el usuario');
                    print(
                      '[MapboxMapWidget] 📍 Nueva posición: ${position.center.latitude}, ${position.center.longitude}',
                    );
                    print('[MapboxMapWidget] 🔍 Nuevo zoom: ${position.zoom}');

                    // Llamar al método del ViewModel para cargar clusters
                    mapViewModel.loadClustersForMapViewFromWidget(
                      position.center,
                      position.zoom,
                    );
                  }
                },
              ),
              children: [
                // Capa base del mapa con tiles de Mapbox
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoiZ2Vyc29uMjIiLCJhIjoiY21kbWptYmlzMXE4bzJsb2pyaWgwOHNjayJ9.Fz4sLUzyNfo95LZa0ITtkA',
                  userAgentPackageName: 'com.example.safy',
                  maxZoom: 18,
                  minZoom: 3,
                ),

                // Capa de ruta de Mapbox
                if (mapViewModel.currentRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: mapViewModel.currentRoute,
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

                // Capa de marcadores
                MarkerLayer(markers: _buildMarkers(mapViewModel)),
              ],
            ),

            // 🆕 BOTÓN FLOTANTE PARA REABRIR SUGERENCIAS (cuando hay ruta activa)
            if (mapViewModel.currentRoute.isNotEmpty)
              Positioned(
                bottom: 100,
                right: 16,
                child: FloatingActionButton(
                  onPressed:
                      () => _showRouteSuggestions(
                        context,
                        mapViewModel,
                        mapViewModel.currentRoute,
                      ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.route),
                  mini: true,
                ),
              ),

            // 🆕 BOTÓN DE UBICACIÓN ACTUAL
            Positioned(
              bottom: 160,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Centrar en ubicación actual
                  _mapController.move(mapViewModel.currentLocation, 16.0);

                  // Mostrar confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.my_location, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Centrado en tu ubicación'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: Icon(Icons.my_location),
                mini: true,
              ),
            ),

            // 🆕 BOTÓN DE DETENER NAVEGACIÓN (cuando hay navegación activa)
            if (mapViewModel.isNavigating)
              Positioned(
                bottom: 220,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    mapViewModel.stopNavigation();

                    // Mostrar confirmación
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.stop, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Navegación detenida'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.stop),
                  mini: true,
                ),
              ),
          ],
        );
      },
    );
  }

  List<Marker> _buildMarkers(MapViewModel mapViewModel) {
    final markers = <Marker>[];

    // 🆕 CALCULAR FACTOR DE ESCALADO BASADO EN ZOOM
    double getScaleFactor() {
      // Escalado más granular y sensible
      if (_currentZoom <= 8) return 0.3; // Muy pequeño en zoom muy bajo
      if (_currentZoom <= 10) return 0.5; // Pequeño en zoom bajo
      if (_currentZoom <= 12) return 0.7; // Pequeño en zoom medio-bajo
      if (_currentZoom <= 13) return 0.85; // Medio-pequeño
      if (_currentZoom <= 14) return 1.0; // Normal en zoom medio
      if (_currentZoom <= 15) return 1.15; // Medio-grande
      if (_currentZoom <= 16) return 1.3; // Grande en zoom alto
      if (_currentZoom <= 17) return 1.45; // Muy grande
      return 1.6; // Extremadamente grande en zoom muy alto
    }

    // Marcador de ubicación actual
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

    // 🚨 CLUSTERS DE ZONAS PELIGROSAS CON ESCALADO DINÁMICO
    if (mapViewModel.showClusters && mapViewModel.clusters.isNotEmpty) {
      for (final cluster in mapViewModel.clusters) {
        final severity = cluster.severityNumber ?? 1;
        final reportCount = cluster.reportCount ?? 0;

        // 🆕 CALCULAR TAMAÑO BASADO EN REPORTES Y SEVERIDAD
        double baseSize = 40.0;
        double sizeMultiplier = 1.0;

        // Multiplicador por cantidad de reportes
        if (reportCount >= 10) sizeMultiplier += 0.5;
        if (reportCount >= 20) sizeMultiplier += 0.3;
        if (reportCount >= 30) sizeMultiplier += 0.2;

        // Multiplicador por severidad
        if (severity >= 4) sizeMultiplier += 0.4;
        if (severity >= 3) sizeMultiplier += 0.2;

        // Aplicar factor de zoom
        final scaleFactor = getScaleFactor();
        final finalSize = (baseSize * sizeMultiplier * scaleFactor).clamp(
          20.0,
          80.0,
        );

        // Color según severidad
        Color clusterColor;
        if (severity >= 4) {
          clusterColor = Colors.red;
        } else if (severity >= 3) {
          clusterColor = Colors.orange;
        } else {
          clusterColor = Colors.yellow;
        }

        markers.add(
          Marker(
            point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
            width: finalSize,
            height: finalSize,
            child: GestureDetector(
              onTap: () => _showClusterInfo(context, cluster),
              child: Container(
                decoration: BoxDecoration(
                  color: clusterColor,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: (finalSize * 0.4).clamp(12.0, 24.0),
                    ),
                    Text(
                      '$reportCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: (finalSize * 0.25).clamp(8.0, 16.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    // 🎯 SOLO MARCADOR DE DESTINO (el inicio siempre es tu ubicación actual)
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

  void _handleMapTap(BuildContext context, LatLng coordinates) {
    final mapViewModel = context.read<MapViewModel>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _buildLocationSelector(context, coordinates, mapViewModel),
    );
  }

  Widget _buildLocationSelector(
    BuildContext context,
    LatLng point,
    MapViewModel mapViewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicador visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Información de la ubicación
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Column(
            children: [
              // 🎯 SOLO PUNTO FINAL (el inicio es tu ubicación actual)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    mapViewModel.setEndPoint(point);
                    Navigator.pop(context);
                    _calculateRoute(mapViewModel);
                  },
                  icon: Icon(Icons.flag),
                  label: Text('Establecer como Destino'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 📝 CREAR REPORTE EN ESTA UBICACIÓN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Usar context.go con extra data para pasar coordenadas
                    context.go(
                      AppRoutesConstant.createReport,
                      extra: {
                        'location': point, // Pasar como LatLng
                      },
                    );
                  },
                  icon: Icon(Icons.report),
                  label: Text('Crear Reporte Aquí'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _calculateRoute(MapViewModel mapViewModel) async {
    // 🎯 USAR UBICACIÓN ACTUAL COMO PUNTO DE INICIO
    final startPoint = mapViewModel.currentLocation;
    final endPoint = mapViewModel.endPoint;

    if (endPoint == null) {
      return;
    }

    try {
      print('🗺️ Calculando ruta segura con Mapbox...');
      print('📍 Inicio: ${startPoint.latitude}, ${startPoint.longitude}');
      print('🎯 Destino: ${endPoint.latitude}, ${endPoint.longitude}');

      // 🚨 EVITAR ZONAS DE RIESGO CON RADIO DE SEGURIDAD
      final avoidAreas = <Map<String, dynamic>>[];
      if (mapViewModel.showClusters && mapViewModel.clusters.isNotEmpty) {
        for (final cluster in mapViewModel.clusters) {
          if (cluster.severityNumber >= 3) {
            // Solo evitar zonas de alta severidad
            // Radio de seguridad de 200 metros alrededor del cluster
            final radius = 0.002; // Aproximadamente 200 metros
            avoidAreas.add({
              'center': LatLng(cluster.centerLatitude, cluster.centerLongitude),
              'radius': radius,
              'severity': cluster.severityNumber,
            });
          }
        }
      }

      // 🛣️ CALCULAR RUTA CON EVASIÓN DE CLUSTERS
      List<List<double>> routeCoordinates;

      if (avoidAreas.isNotEmpty) {
        // Intentar múltiples rutas evitando diferentes clusters
        routeCoordinates = await _calculateSafeRoute(
          startPoint,
          endPoint,
          avoidAreas,
        );
      } else {
        // Ruta directa si no hay clusters peligrosos
        routeCoordinates = await _directionsClient.getRoute(
          start: startPoint,
          end: endPoint,
          profile: 'walking',
        );
      }

      if (routeCoordinates.isNotEmpty) {
        final route =
            routeCoordinates
                .map((coord) => LatLng(coord[0], coord[1]))
                .toList();

        // Actualizar la ruta en el ViewModel
        mapViewModel.setCurrentRoute(route);

        print('🗺️ Ruta segura calculada con ${route.length} puntos');

        // Centrar el mapa en la ruta
        if (route.isNotEmpty) {
          // Centrar en el punto medio de la ruta
          final midPoint = route[route.length ~/ 2];
          _mapController.move(midPoint, 15.0);
        }

        // 🎯 ACTUALIZAR EL PUNTO DE INICIO EN EL VIEWMODEL
        mapViewModel.setStartPoint(startPoint);

        // 🆕 MOSTRAR SUGERENCIAS DE RUTAS
        _showRouteSuggestions(context, mapViewModel, route);

        // 🆕 AGREGAR BOTÓN PARA REABRIR SUGERENCIAS
        _addRouteSuggestionsButton(context, mapViewModel);
      }
    } catch (e) {
      print('❌ Error calculando ruta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculando ruta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🆕 MOSTRAR SUGERENCIAS DE RUTAS
  void _showRouteSuggestions(
    BuildContext context,
    MapViewModel mapViewModel,
    List<LatLng> route,
  ) async {
    // Calcular rutas alternativas
    final startPoint = mapViewModel.currentLocation;
    final endPoint = mapViewModel.endPoint;

    if (endPoint == null) return;

    try {
      // Ruta segura (la que ya tenemos)
      final safeRoute = route;

      // 🆕 RUTA RÁPIDA: Sin evasión de zonas peligrosas para ser más rápida
      List<List<double>> fastRouteCoords;
      try {
        fastRouteCoords = await _directionsClient.getRoute(
          start: startPoint,
          end: endPoint,
          profile:
              'driving', // Usar perfil de conducción para rutas más directas
        );
      } catch (e) {
        // Fallback a ruta directa
        fastRouteCoords = await _directionsClient.getRoute(
          start: startPoint,
          end: endPoint,
          profile: 'walking',
        );
      }

      // 🆕 RUTA EXTRA SEGURA: Con evasión más agresiva de zonas peligrosas
      List<List<double>> extraSafeRouteCoords = [];
      try {
        // Calcular zonas de evasión extra seguras
        final extraSafeAvoidAreas = _calculateExtraSafeAvoidanceAreas(
          mapViewModel,
        );

        if (extraSafeAvoidAreas.isNotEmpty) {
          print(
            '🛡️ [MapboxMapWidget] Calculando ruta extra segura con ${extraSafeAvoidAreas.length} zonas de evasión',
          );

          // 🆕 ESTRATEGIA 1: Intentar ruta con waypoints de evasión extra segura
          try {
            extraSafeRouteCoords = await _calculateExtraSafeRoute(
              startPoint,
              endPoint,
              extraSafeAvoidAreas,
            );

            if (extraSafeRouteCoords.isNotEmpty) {
              print(
                '🛡️ [MapboxMapWidget] Ruta extra segura calculada con waypoints',
              );
            }
          } catch (e) {
            print('❌ [MapboxMapWidget] Error en estrategia 1: $e');
          }

          // 🆕 ESTRATEGIA 2: Si falla, usar perfil de conducción con evasión manual
          if (extraSafeRouteCoords.isEmpty) {
            try {
              extraSafeRouteCoords = await _calculateExtraSafeRouteWithDriving(
                startPoint,
                endPoint,
                extraSafeAvoidAreas,
              );

              if (extraSafeRouteCoords.isNotEmpty) {
                print(
                  '🛡️ [MapboxMapWidget] Ruta extra segura calculada con perfil driving',
                );
              }
            } catch (e) {
              print('❌ [MapboxMapWidget] Error en estrategia 2: $e');
            }
          }

          // 🆕 ESTRATEGIA 3: Si aún falla, crear ruta manual evitando zonas
          if (extraSafeRouteCoords.isEmpty) {
            try {
              extraSafeRouteCoords = await _createManualExtraSafeRoute(
                startPoint,
                endPoint,
                extraSafeAvoidAreas,
              );

              if (extraSafeRouteCoords.isNotEmpty) {
                print(
                  '🛡️ [MapboxMapWidget] Ruta extra segura creada manualmente',
                );
              }
            } catch (e) {
              print('❌ [MapboxMapWidget] Error en estrategia 3: $e');
            }
          }
        } else {
          // Si no hay zonas peligrosas, usar ruta normal
          print(
            '🛡️ [MapboxMapWidget] No hay zonas peligrosas, usando ruta normal',
          );
          extraSafeRouteCoords = await _directionsClient.getRoute(
            start: startPoint,
            end: endPoint,
            profile: 'walking',
          );
        }
      } catch (e) {
        print(
          '❌ [MapboxMapWidget] Error general calculando ruta extra segura: $e',
        );
        // Fallback a ruta normal
        extraSafeRouteCoords = await _directionsClient.getRoute(
          start: startPoint,
          end: endPoint,
          profile: 'walking',
        );
      }

      // Convertir coordenadas a LatLng
      final fastRoute =
          fastRouteCoords.isNotEmpty
              ? fastRouteCoords
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList()
              : safeRoute;

      final extraSafeRoute =
          extraSafeRouteCoords.isNotEmpty
              ? extraSafeRouteCoords
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList()
              : safeRoute;

      // 🆕 VERIFICAR QUE LAS RUTAS SEAN DIFERENTES
      print('🛣️ [MapboxMapWidget] Rutas calculadas:');
      print('🛣️ [MapboxMapWidget] Ruta Segura: ${safeRoute.length} puntos');
      print('🛣️ [MapboxMapWidget] Ruta Rápida: ${fastRoute.length} puntos');
      print(
        '🛣️ [MapboxMapWidget] Ruta Extra Segura: ${extraSafeRoute.length} puntos',
      );

      // Verificar si las rutas son diferentes
      bool routesAreDifferent = false;
      if (safeRoute.length != fastRoute.length ||
          safeRoute.length != extraSafeRoute.length ||
          fastRoute.length != extraSafeRoute.length) {
        routesAreDifferent = true;
      } else {
        // Comparar algunos puntos clave
        if (safeRoute.isNotEmpty &&
            fastRoute.isNotEmpty &&
            extraSafeRoute.isNotEmpty) {
          final safeMid = safeRoute[safeRoute.length ~/ 2];
          final fastMid = fastRoute[fastRoute.length ~/ 2];
          final extraMid = extraSafeRoute[extraSafeRoute.length ~/ 2];

          final dist1 = _calculateDistance(safeMid, fastMid);
          final dist2 = _calculateDistance(safeMid, extraMid);
          final dist3 = _calculateDistance(fastMid, extraMid);

          routesAreDifferent =
              dist1 > 50 || dist2 > 50 || dist3 > 50; // 50 metros de diferencia
        }
      }

      print('🛣️ [MapboxMapWidget] Rutas son diferentes: $routesAreDifferent');

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
                    safeRoutePoints: safeRoute,
                    fastRoutePoints: fastRoute,
                    extraSafeRoutePoints: extraSafeRoute,
                    safeDistance: _calculateRouteDistance(safeRoute),
                    safeDuration: _calculateRouteDuration(safeRoute),
                    safeSafetyLevel: _calculateRouteSafety(
                      safeRoute,
                      mapViewModel,
                    ),
                  ),
            ),
      );
    } catch (e) {
      print('❌ [MapboxMapWidget] Error calculando rutas alternativas: $e');
      // Mostrar con la ruta original si hay error
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
                    safeRoutePoints: route,
                    fastRoutePoints: route,
                    extraSafeRoutePoints: route,
                    safeDistance: _calculateRouteDistance(route),
                    safeDuration: _calculateRouteDuration(route),
                    safeSafetyLevel: _calculateRouteSafety(route, mapViewModel),
                  ),
            ),
      );
    }
  }

  // 🆕 CALCULAR ZONAS DE EVASIÓN EXTRA SEGURAS
  List<Map<String, dynamic>> _calculateExtraSafeAvoidanceAreas(
    MapViewModel mapViewModel,
  ) {
    final avoidAreas = <Map<String, dynamic>>[];
    if (mapViewModel.showClusters && mapViewModel.clusters.isNotEmpty) {
      for (final cluster in mapViewModel.clusters) {
        // 🆕 INCLUIR TODAS LAS ZONAS DE RIESGO, NO SOLO LAS ALTAS
        if (cluster.severityNumber >= 1) {
          // Incluir desde severidad 1
          // Radio más grande para evasión extra segura
          double radius = 0.005; // 500 metros base

          // Ajustar radio según severidad
          if (cluster.severityNumber >= 4) {
            radius = 0.008; // 800 metros para severidad alta
          } else if (cluster.severityNumber >= 3) {
            radius = 0.006; // 600 metros para severidad media-alta
          } else if (cluster.severityNumber >= 2) {
            radius = 0.004; // 400 metros para severidad media
          }

          // Ajustar según cantidad de reportes
          final reportCount = cluster.reportCount ?? 1;
          if (reportCount >= 10) {
            radius += 0.002; // +200m por 10+ reportes
          }
          if (reportCount >= 20) {
            radius += 0.001; // +100m adicional por 20+ reportes
          }

          avoidAreas.add({
            'center': LatLng(cluster.centerLatitude, cluster.centerLongitude),
            'radius': radius,
            'severity': cluster.severityNumber,
            'reportCount': reportCount,
          });

          print('🚨 [MapboxMapWidget] Zona de evasión extra segura:');
          print('🚨 [MapboxMapWidget] Severidad: ${cluster.severityNumber}');
          print('🚨 [MapboxMapWidget] Reportes: $reportCount');
          print('🚨 [MapboxMapWidget] Radio: ${radius.toStringAsFixed(4)}');
        }
      }
    }

    print(
      '🚨 [MapboxMapWidget] Total zonas de evasión extra segura: ${avoidAreas.length}',
    );
    return avoidAreas;
  }

  // 🆕 CALCULAR DISTANCIA DE LA RUTA
  double _calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }

    // Convertir a kilómetros (aproximadamente)
    return totalDistance * 111.0; // 1 grado ≈ 111 km
  }

  // 🆕 CALCULAR DURACIÓN DE LA RUTA
  int _calculateRouteDuration(List<LatLng> route) {
    final distance = _calculateRouteDistance(route);
    // Velocidad promedio de caminata: 5 km/h
    return (distance / 5.0 * 60).round(); // en minutos
  }

  // 🆕 CALCULAR NIVEL DE SEGURIDAD DE LA RUTA
  double _calculateRouteSafety(List<LatLng> route, MapViewModel mapViewModel) {
    if (route.isEmpty) return 1.0;

    // Verificar si la ruta pasa cerca de clusters peligrosos
    double safetyScore = 1.0;
    final dangerousClusters =
        mapViewModel.clusters
            .where((cluster) => cluster.severityNumber >= 3)
            .toList();

    for (final cluster in dangerousClusters) {
      final clusterPoint = LatLng(
        cluster.centerLatitude,
        cluster.centerLongitude,
      );

      // Verificar si algún punto de la ruta está cerca del cluster
      for (final routePoint in route) {
        final distance = _calculateDistance(clusterPoint, routePoint);
        if (distance < 0.002) {
          // 200 metros
          safetyScore -= 0.2; // Reducir seguridad
          break;
        }
      }
    }

    return safetyScore.clamp(0.0, 1.0);
  }

  // 🆕 AGREGAR BOTÓN PARA REABRIR SUGERENCIAS DE RUTAS
  void _addRouteSuggestionsButton(
    BuildContext context,
    MapViewModel mapViewModel,
  ) {
    // Mostrar un botón flotante para reabrir sugerencias
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.route, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Toca para ver más opciones de ruta')),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver Rutas',
          textColor: Colors.white,
          onPressed:
              () => _showRouteSuggestions(
                context,
                mapViewModel,
                mapViewModel.currentRoute,
              ),
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 🆕 MANEJAR NOTIFICACIONES DINÁMICAS DE ZONAS PELIGROSAS
  void _handleDynamicNotifications(MapViewModel mapViewModel) {
    final currentLocation = mapViewModel.currentLocation;

    // Si es la primera vez, solo guardar la ubicación
    if (_lastKnownLocation == null) {
      _lastKnownLocation = currentLocation;
      return;
    }

    // Calcular distancia movida
    final distance = _calculateDistance(_lastKnownLocation!, currentLocation);

    // Si se movió más de la distancia de notificación
    if (distance > _notificationDistance) {
      _checkNearbyDangerZones(mapViewModel);
      _lastKnownLocation = currentLocation;
    }
  }

  // 🆕 VERIFICAR ZONAS PELIGROSAS CERCANAS
  void _checkNearbyDangerZones(MapViewModel mapViewModel) {
    if (!mapViewModel.showClusters || mapViewModel.clusters.isEmpty) return;

    final currentLocation = mapViewModel.currentLocation;
    final nearbyZones = <String>[];

    for (final cluster in mapViewModel.clusters) {
      final distance = _calculateDistance(
        currentLocation,
        LatLng(cluster.centerLatitude, cluster.centerLongitude),
      );

      // Si está a menos de 1km y es de alta severidad
      if (distance < 1000 && cluster.severityNumber >= 3) {
        final zoneId = '${cluster.centerLatitude}_${cluster.centerLongitude}';
        if (!_shownNotifications.contains(zoneId)) {
          nearbyZones.add(zoneId);
          _showDangerZoneNotification(cluster, distance);
        }
      }
    }

    // Limpiar notificaciones antiguas
    _shownNotifications.clear();
    _shownNotifications.addAll(nearbyZones);
  }

  // 🆕 MOSTRAR NOTIFICACIÓN DE ZONA PELIGROSA
  void _showDangerZoneNotification(dynamic cluster, double distance) {
    final severity = cluster.severityNumber ?? 1;
    final reportCount = cluster.reportCount ?? 0;

    Color notificationColor;
    String severityText;

    if (severity >= 4) {
      notificationColor = Colors.red;
      severityText = 'ALTA';
    } else if (severity >= 3) {
      notificationColor = Colors.orange;
      severityText = 'MEDIA';
    } else {
      notificationColor = Colors.yellow;
      severityText = 'BAJA';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Zona Peligrosa Cercana',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${distance.toStringAsFixed(0)}m - $severityText ($reportCount reportes)',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: notificationColor,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            // Mover mapa a la zona
            _mapController.move(
              LatLng(cluster.centerLatitude, cluster.centerLongitude),
              16.0,
            );
          },
        ),
      ),
    );
  }

  // 🆕 CALCULAR DISTANCIA ENTRE DOS PUNTOS
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

  // 🆕 MÉTODO PARA CALCULAR RUTA SEGURA EVITANDO CLUSTERS
  Future<List<List<double>>> _calculateSafeRoute(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) async {
    try {
      print(
        '🛣️ Calculando ruta segura evitando ${avoidAreas.length} zonas peligrosas...',
      );

      // 🚨 ESTRATEGIA 1: RUTA CON WAYPOINTS DE EVASIÓN MÚLTIPLES
      if (avoidAreas.isNotEmpty) {
        final optimalWaypoints = _calculateOptimalAvoidanceWaypoints(
          start,
          end,
          avoidAreas,
        );

        if (optimalWaypoints.isNotEmpty) {
          try {
            final route = await _directionsClient.getRoute(
              start: start,
              end: end,
              profile: 'walking',
              waypoints: optimalWaypoints,
            );

            if (route.isNotEmpty && _verifyRouteSafety(route, avoidAreas)) {
              return route;
            }
          } catch (e) {}
        }
      }

      // 🛣️ ESTRATEGIA 2: RUTA CON PERFIL ALTERNATIVO
      try {
        final route = await _directionsClient.getRoute(
          start: start,
          end: end,
          profile:
              'driving', // Usar perfil de conducción para rutas más amplias
        );

        if (route.isNotEmpty && _verifyRouteSafety(route, avoidAreas)) {
          return route;
        }
      } catch (e) {}

      // 🛣️ ESTRATEGIA 3: RUTA DIRECTA COMO ÚLTIMO RECURSO

      return await _directionsClient.getRoute(
        start: start,
        end: end,
        profile: 'walking',
      );
    } catch (e) {
      rethrow;
    }
  }

  // 🆕 CALCULAR WAYPOINTS ÓPTIMOS DE EVASIÓN
  List<LatLng> _calculateOptimalAvoidanceWaypoints(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) {
    final waypoints = <LatLng>[];

    for (final area in avoidAreas) {
      final center = area['center'] as LatLng;
      final radius = area['radius'] as double;
      final severity = area['severity'] as int;

      // Calcular dirección desde el cluster hacia el destino
      final direction = _calculateDirection(center, end);

      // Crear múltiples puntos de evasión en diferentes direcciones
      final avoidanceDistance =
          radius * 2.0; // Doble del radio para mayor seguridad

      // Punto de evasión principal (opuesto al destino)
      final mainAvoidancePoint = LatLng(
        center.latitude - cos(direction) * avoidanceDistance,
        center.longitude - sin(direction) * avoidanceDistance,
      );

      // Punto de evasión secundario (perpendicular)
      final secondaryAvoidancePoint = LatLng(
        center.latitude + sin(direction) * avoidanceDistance,
        center.longitude - cos(direction) * avoidanceDistance,
      );

      // Verificar que los puntos no estén muy lejos de la ruta original
      final directDistance = _calculateDistance(start, end);
      final totalDistanceWithMain =
          _calculateDistance(start, mainAvoidancePoint) +
          _calculateDistance(mainAvoidancePoint, end);
      final totalDistanceWithSecondary =
          _calculateDistance(start, secondaryAvoidancePoint) +
          _calculateDistance(secondaryAvoidancePoint, end);

      if (totalDistanceWithMain < directDistance * 1.5) {
        waypoints.add(mainAvoidancePoint);
        print(
          '🚨 Waypoint principal creado: ${mainAvoidancePoint.latitude}, ${mainAvoidancePoint.longitude}',
        );
      }

      if (totalDistanceWithSecondary < directDistance * 1.5) {
        waypoints.add(secondaryAvoidancePoint);
        print(
          '🚨 Waypoint secundario creado: ${secondaryAvoidancePoint.latitude}, ${secondaryAvoidancePoint.longitude}',
        );
      }
    }

    return waypoints;
  }

  // 🆕 VERIFICAR SEGURIDAD DE LA RUTA
  bool _verifyRouteSafety(
    List<List<double>> route,
    List<Map<String, dynamic>> avoidAreas,
  ) {
    if (avoidAreas.isEmpty) return true;

    final routePoints =
        route.map((coord) => LatLng(coord[0], coord[1])).toList();

    for (final area in avoidAreas) {
      final center = area['center'] as LatLng;
      final radius = area['radius'] as double;

      // Verificar cada punto de la ruta
      for (final point in routePoints) {
        final distance = _calculateDistance(center, point);
        if (distance < radius) {
          print(
            '❌ Ruta pasa por zona peligrosa: distancia ${distance.toStringAsFixed(4)} < radio ${radius.toStringAsFixed(4)}',
          );
          return false;
        }
      }
    }

    return true;
  }

  // 🆕 CALCULAR PUNTOS DE EVASIÓN ALREDEDOR DE UN CLUSTER
  List<LatLng> _calculateAvoidancePoints(
    LatLng clusterCenter,
    double radius,
    LatLng start,
    LatLng end,
  ) {
    final points = <LatLng>[];

    // Calcular dirección general de la ruta
    final direction = _calculateDirection(start, end);

    // Crear puntos de evasión en dirección opuesta al cluster
    final angles = [45, 90, 135, 180, 225, 270, 315];

    for (final angle in angles) {
      final radians = angle * (3.14159 / 180);
      final latOffset = radius * cos(radians);
      final lngOffset = radius * sin(radians);

      final avoidancePoint = LatLng(
        clusterCenter.latitude + latOffset,
        clusterCenter.longitude + lngOffset,
      );

      // Verificar que el punto no esté muy cerca del cluster
      final distance = _calculateDistance(clusterCenter, avoidancePoint);
      if (distance > radius * 0.5) {
        points.add(avoidancePoint);
      }
    }

    return points;
  }

  // 🆕 CALCULAR DIRECCIÓN ENTRE DOS PUNTOS
  double _calculateDirection(LatLng start, LatLng end) {
    final deltaLng = end.longitude - start.longitude;
    final deltaLat = end.latitude - start.latitude;
    return atan2(deltaLng, deltaLat) * (180 / 3.14159);
  }

  // 🆕 MÉTODO PARA CALCULAR RUTA EXTRA SEGURA CON WAYPOINTS
  Future<List<List<double>>> _calculateExtraSafeRoute(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) async {
    try {
      print(
        '🛡️ [MapboxMapWidget] Calculando ruta extra segura con waypoints...',
      );

      // Crear waypoints de evasión más agresivos
      final extraSafeWaypoints = _calculateExtraSafeWaypoints(
        start,
        end,
        avoidAreas,
      );

      if (extraSafeWaypoints.isNotEmpty) {
        final route = await _directionsClient.getRoute(
          start: start,
          end: end,
          profile: 'walking',
          waypoints: extraSafeWaypoints,
        );

        if (route.isNotEmpty && _verifyExtraSafeRoute(route, avoidAreas)) {
          print('🛡️ [MapboxMapWidget] Ruta extra segura verificada');
          return route;
        }
      }

      return [];
    } catch (e) {
      print('❌ [MapboxMapWidget] Error en _calculateExtraSafeRoute: $e');
      return [];
    }
  }

  // 🆕 MÉTODO PARA CALCULAR RUTA EXTRA SEGURA CON PERFIL DRIVING
  Future<List<List<double>>> _calculateExtraSafeRouteWithDriving(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) async {
    try {
      print(
        '🛡️ [MapboxMapWidget] Calculando ruta extra segura con perfil driving...',
      );

      // Usar perfil de conducción para rutas más amplias
      final route = await _directionsClient.getRoute(
        start: start,
        end: end,
        profile: 'driving',
      );

      if (route.isNotEmpty && _verifyExtraSafeRoute(route, avoidAreas)) {
        print('🛡️ [MapboxMapWidget] Ruta extra segura con driving verificada');
        return route;
      }

      return [];
    } catch (e) {
      print(
        '❌ [MapboxMapWidget] Error en _calculateExtraSafeRouteWithDriving: $e',
      );
      return [];
    }
  }

  // 🆕 MÉTODO PARA CREAR RUTA EXTRA SEGURA MANUALMENTE
  Future<List<List<double>>> _createManualExtraSafeRoute(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) async {
    try {
      print('🛡️ [MapboxMapWidget] Creando ruta extra segura manualmente...');

      // Crear una ruta que evite completamente las zonas peligrosas
      final safePoints = _createSafeRoutePoints(start, end, avoidAreas);

      if (safePoints.length >= 2) {
        // Convertir puntos a formato de coordenadas
        final route =
            safePoints
                .map((point) => [point.latitude, point.longitude])
                .toList();
        print(
          '🛡️ [MapboxMapWidget] Ruta manual creada con ${route.length} puntos',
        );
        return route;
      }

      return [];
    } catch (e) {
      print('❌ [MapboxMapWidget] Error en _createManualExtraSafeRoute: $e');
      return [];
    }
  }

  // 🆕 CALCULAR WAYPOINTS EXTRA SEGUROS
  List<LatLng> _calculateExtraSafeWaypoints(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) {
    final waypoints = <LatLng>[];

    for (final area in avoidAreas) {
      final center = area['center'] as LatLng;
      final radius = area['radius'] as double;

      // Crear múltiples puntos de evasión en diferentes direcciones
      final avoidanceDistance = radius * 2.5; // Más agresivo que el normal

      // Calcular dirección desde el cluster hacia el destino
      final direction = _calculateDirection(center, end);

      // Punto de evasión principal (opuesto al destino)
      final mainAvoidancePoint = LatLng(
        center.latitude - cos(direction) * avoidanceDistance,
        center.longitude - sin(direction) * avoidanceDistance,
      );

      // Punto de evasión secundario (perpendicular)
      final secondaryAvoidancePoint = LatLng(
        center.latitude + sin(direction) * avoidanceDistance,
        center.longitude - cos(direction) * avoidanceDistance,
      );

      // Verificar que los puntos no estén muy lejos de la ruta original
      final directDistance = _calculateDistance(start, end);
      final totalDistanceWithMain =
          _calculateDistance(start, mainAvoidancePoint) +
          _calculateDistance(mainAvoidancePoint, end);
      final totalDistanceWithSecondary =
          _calculateDistance(start, secondaryAvoidancePoint) +
          _calculateDistance(secondaryAvoidancePoint, end);

      if (totalDistanceWithMain < directDistance * 2.0) {
        waypoints.add(mainAvoidancePoint);
      }

      if (totalDistanceWithSecondary < directDistance * 2.0) {
        waypoints.add(secondaryAvoidancePoint);
      }
    }

    return waypoints;
  }

  // 🆕 VERIFICAR RUTA EXTRA SEGURA
  bool _verifyExtraSafeRoute(
    List<List<double>> route,
    List<Map<String, dynamic>> avoidAreas,
  ) {
    if (avoidAreas.isEmpty) return true;

    final routePoints =
        route.map((coord) => LatLng(coord[0], coord[1])).toList();

    for (final area in avoidAreas) {
      final center = area['center'] as LatLng;
      final radius = area['radius'] as double;

      // Verificar cada punto de la ruta
      for (final point in routePoints) {
        final distance = _calculateDistance(center, point);
        if (distance < radius) {
          print(
            '❌ [MapboxMapWidget] Ruta extra segura pasa por zona peligrosa',
          );
          return false;
        }
      }
    }

    return true;
  }

  // 🆕 CREAR PUNTOS DE RUTA SEGURA MANUALMENTE
  List<LatLng> _createSafeRoutePoints(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) {
    final safePoints = <LatLng>[start];

    // Crear puntos intermedios que eviten las zonas peligrosas
    final midPoint = LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );

    // Verificar si el punto medio está en zona peligrosa
    bool midPointIsSafe = true;
    for (final area in avoidAreas) {
      final center = area['center'] as LatLng;
      final radius = area['radius'] as double;
      final distance = _calculateDistance(midPoint, center);

      if (distance < radius) {
        midPointIsSafe = false;
        break;
      }
    }

    if (midPointIsSafe) {
      safePoints.add(midPoint);
    } else {
      // Crear punto alternativo que evite las zonas peligrosas
      final alternativePoint = _findSafeAlternativePoint(
        start,
        end,
        avoidAreas,
      );
      if (alternativePoint != null) {
        safePoints.add(alternativePoint);
      }
    }

    safePoints.add(end);
    return safePoints;
  }

  // 🆕 ENCONTRAR PUNTO ALTERNATIVO SEGURO
  LatLng? _findSafeAlternativePoint(
    LatLng start,
    LatLng end,
    List<Map<String, dynamic>> avoidAreas,
  ) {
    // Intentar diferentes ángulos para encontrar un punto seguro
    final angles = [45, 90, 135, 180, 225, 270, 315];
    final midPoint = LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );

    for (final angle in angles) {
      final radians = angle * (pi / 180);
      final offset = 0.001; // Aproximadamente 100 metros

      final alternativePoint = LatLng(
        midPoint.latitude + cos(radians) * offset,
        midPoint.longitude + sin(radians) * offset,
      );

      // Verificar si el punto es seguro
      bool isSafe = true;
      for (final area in avoidAreas) {
        final center = area['center'] as LatLng;
        final radius = area['radius'] as double;
        final distance = _calculateDistance(alternativePoint, center);

        if (distance < radius) {
          isSafe = false;
          break;
        }
      }

      if (isSafe) {
        return alternativePoint;
      }
    }

    return null;
  }

  // Método para centrar en ubicación
  void centerOnLocation(LatLng location) {
    _mapController.move(location, 15.0);
  }

  // 🚨 Método para mostrar información del cluster
  void _showClusterInfo(BuildContext context, dynamic cluster) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador visual
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Zona de Riesgo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información del cluster
                _buildInfoRow(
                  'Tipo de Incidente',
                  cluster.dominantIncidentName ?? 'N/A',
                ),
                _buildInfoRow('Reportes', '${cluster.reportCount ?? 0}'),
                _buildInfoRow('Severidad', '${cluster.severityNumber ?? 0}/5'),
                _buildInfoRow('Zona', cluster.zone ?? 'N/A'),
                _buildInfoRow(
                  'Distancia',
                  '${(cluster.distanceFromUser ?? 0).toStringAsFixed(2)} km',
                ),

                const SizedBox(height: 16),

                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cerrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }
}
