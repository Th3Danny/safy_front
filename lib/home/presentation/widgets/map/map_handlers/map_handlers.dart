import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/home/data/datasources/mapbox_directions_client.dart';

class MapHandlers {
  static final MapboxDirectionsClient _directionsClient =
      MapboxDirectionsClient();

  static void handleMapTap(BuildContext context, LatLng coordinates) {
    print('🗺️ [MapHandlers] Tap en coordenadas: $coordinates');

    // Mostrar selector de ubicación
    _showLocationSelector(context, coordinates);
  }

  static void _showLocationSelector(BuildContext context, LatLng point) {
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
                    const Icon(Icons.location_on, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubicación seleccionada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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
                    // Establecer como destino
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final mapViewModel = context.read<MapViewModel>();
                          mapViewModel.setEndPoint(point);
                          Navigator.pop(context);
                          _calculateRoute(context, mapViewModel);
                        },
                        icon: const Icon(Icons.flag),
                        label: const Text('Establecer como Destino'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Crear reporte
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go(
                            AppRoutesConstant.createReport,
                            extra: {'location': point},
                          );
                        },
                        icon: const Icon(Icons.report),
                        label: const Text('Crear Reporte Aquí'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  static Future<void> _calculateRoute(
    BuildContext context,
    MapViewModel mapViewModel,
  ) async {
    final startPoint = mapViewModel.currentLocation;
    final endPoint = mapViewModel.endPoint;

    if (endPoint == null) return;

    try {
      print('🗺️ Calculando ruta segura con Mapbox...');
      print('📍 Inicio: ${startPoint.latitude}, ${startPoint.longitude}');
      print('🎯 Destino: ${endPoint.latitude}, ${endPoint.longitude}');

      // Calcular ruta básica
      final routeCoordinates = await _directionsClient.getRoute(
        start: startPoint,
        end: endPoint,
        profile: 'walking',
      );

      if (routeCoordinates.isNotEmpty) {
        final route =
            routeCoordinates
                .map(
                  (coord) => LatLng(
                    coord[0],
                    coord[1],
                  ), // coord[0] = lat, coord[1] = lon
                )
                .toList();

        mapViewModel.setCurrentRoute(route);
        mapViewModel.setStartPoint(startPoint);

        print('🗺️ Ruta calculada con ${route.length} puntos');
        print('🗺️ Primer punto: ${route.first}');
        print('🗺️ Último punto: ${route.last}');

        // Verificar que el contexto aún esté montado antes de mostrar SnackBar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.route, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Ruta calculada: ${route.length} puntos'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error calculando ruta: $e');

      // Verificar que el contexto aún esté montado antes de mostrar SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculando ruta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
