// map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:go_router/go_router.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        return FlutterMap(
          mapController: mapViewModel.mapController,
          options: MapOptions(
            initialCenter: mapViewModel.currentLocation,
            initialZoom: 15,
            minZoom: 3,
            maxZoom: 18,
            onMapReady: () => mapViewModel.onMapReady(),
            onTap: (tapPosition, point) => _handleMapTap(context, point),
            onPositionChanged: (position, hasGesture) {
              // 🔄 Listener automático para cambios de zoom y posición
              if (hasGesture) {
                mapViewModel.onMapPositionChanged(position);
              }
            },
          ),
          children: [
            // Capa base del mapa
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.safy',
            ),

            // Capa de ruta actual
            if (mapViewModel.currentRoute.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: mapViewModel.currentRoute,
                    strokeWidth: 6.0,
                    color: Colors.blue.withOpacity(0.8),
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),

            // ✨ NUEVA CAPA: Todos los marcadores combinados (clusters, reportes, ubicación, rutas)
            MarkerLayer(markers: mapViewModel.allMapMarkers),

            // Capa de información de ruta
            if (mapViewModel.routeOptions.isNotEmpty)
              _buildRouteInfoLayer(mapViewModel),
          ],
        );
      },
    );
  }

  void _handleMapTap(BuildContext context, LatLng point) {
    final mapViewModel = context.read<MapViewModel>();

    // Obtener información de seguridad de la ubicación tocada
    final safetyInfo = mapViewModel.getLocationSafetyInfo(point);

    // Mostrar diálogo para seleccionar punto de inicio o destino
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _buildLocationSelector(context, point, mapViewModel, safetyInfo),
    );
  }

  Widget _buildLocationSelector(
    BuildContext context,
    LatLng point,
    MapViewModel mapViewModel,
    String safetyInfo,
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

          Text(
            'Ubicación seleccionada',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Lat: ${point.latitude.toStringAsFixed(6)}\n'
            'Lng: ${point.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // 🆕 NUEVA: Información de seguridad de la zona
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  safetyInfo.startsWith('⚠️')
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    safetyInfo.startsWith('⚠️')
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
              ),
            ),
            child: Text(
              safetyInfo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    safetyInfo.startsWith('⚠️')
                        ? Colors.orange.shade800
                        : Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // 🎯 NUEVO: Solo botón de destino (automáticamente usa ubicación actual como inicio)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // 🎯 Establecer automáticamente la posición actual como punto de inicio
                mapViewModel.setCurrentLocationAsStart();

                // Establecer el punto tocado como destino
                mapViewModel.setEndPoint(point);

                Navigator.pop(context);

                // Mostrar confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.navigation, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Calculando ruta desde tu ubicación a: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text('Crear Ruta a este punto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón para reportar incidente en esta ubicación
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cerrar el bottom sheet
              // ✅ CORRECCIÓN: Usar context.go para navegar
              context.go(
                '/create-report',
                extra: {
                  'location': point,
                }, // Usa 'extra' para pasar objetos complejos
              );
            },
            icon: const Icon(Icons.report_problem, color: Colors.orange),
            label: const Text('Reportar incidente aquí'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoLayer(MapViewModel mapViewModel) {
    final recommendedRoute =
        mapViewModel.routeOptions
            .where((route) => route.isRecommended)
            .firstOrNull;

    if (recommendedRoute == null) return const SizedBox.shrink();

    // Encontrar punto medio de la ruta para mostrar información
    final middleIndex = recommendedRoute.points.length ~/ 2;
    final middlePoint = recommendedRoute.points[middleIndex];

    return MarkerLayer(
      markers: [
        Marker(
          point: middlePoint,
          width: 120,
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${recommendedRoute.distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${recommendedRoute.duration} min',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      size: 10,
                      color: recommendedRoute.safetyColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      recommendedRoute.safetyText,
                      style: TextStyle(
                        fontSize: 9,
                        color: recommendedRoute.safetyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
