// lib/features/home/presentation/pages/mobile_map_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/map_controls_widget.dart';
import 'package:safy/home/presentation/widgets/mapbox_map_widget.dart';
import 'package:safy/home/presentation/widgets/navigation_fab.dart';
import 'package:safy/home/presentation/widgets/place_search_widget.dart';
import 'package:safy/home/presentation/widgets/navigation_progress_widget.dart';
import 'package:safy/home/presentation/widgets/gps_security_widget.dart';
import 'package:safy/home/presentation/widgets/danger_zone_alert_widget.dart';
import 'package:safy/core/router/app_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';

class MobileMapLayout extends StatelessWidget {
  const MobileMapLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapViewModel>(
        builder: (context, mapViewModel, child) {
          return Stack(
            children: [
              // 🌍 Mapa principal con Mapbox
              const MapboxMapWidget(),

              // 🎯 Controles del mapa (SIMPLIFICADO - solo botones esenciales)
              Positioned(
                top: 50,
                right: 16,
                child: MapControlsWidget(
                  onLocationPressed:
                      () => mapViewModel.centerOnCurrentLocation(),
                  onToggleDangerZones: () => mapViewModel.toggleDangerZones(),
                  onToggleClusters: () => mapViewModel.toggleClusters(),
                  showDangerZones: mapViewModel.showDangerZones,
                  showClusters: mapViewModel.showClusters,
                  clustersLoading: mapViewModel.clustersLoading,
                ),
              ),

              // 🔍 Widget de búsqueda de lugares
              const Positioned(
                top: 50,
                left: 16,
                right: 80, // Espacio para los controles del mapa
                child: PlaceSearchWidget(),
              ),

              // 📋 MEJORADO: Widget de rutas mejorado (cuando hay rutas calculadas)
              if (mapViewModel.routeOptions.isNotEmpty &&
                  mapViewModel.showRoutePanel)
                Positioned(
                  top: 180, // Ajustado para dar espacio al PlaceSearchWidget
                  left: 0,
                  right: 0,
                  child: _buildEnhancedRoutePanel(mapViewModel),
                ),

         

              // 🚨 NUEVO: Alerta de zona peligrosa
              if (mapViewModel.showDangerAlert &&
                  mapViewModel.currentDangerZone != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: DangerZoneAlertWidget(
                        cluster: mapViewModel.currentDangerZone!,
                        distance: mapViewModel.currentDangerDistance ?? 0,
                        onSafeRoute: () => mapViewModel.navigateToSafeRoute(),
                        onReport: () => mapViewModel.reportIncident(),
                        onDismiss: () => mapViewModel.hideDangerAlert(),
                      ),
                    ),
                  ),
                ),

              // 🔒 Banner de GPS falso
              GpsSpoofingBanner(
                spoofingResult: mapViewModel.gpsSpoofingResult,
                onDismiss: () {
                  // Aquí puedes implementar lógica para ocultar el banner
                  print('Banner de GPS falso descartado');
                },
                onReset: () => mapViewModel.resetGpsSpoofingDetector(),
              ),

              // 🧭 Panel de navegación inferior
              NavigationFab(
                onNavigationTap: (type) => _handleNavigationTap(context, type),
              ),

              // 📊 MEJORADO: Widget de progreso de navegación
              if (mapViewModel.isNavigating)
                const Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: NavigationProgressWidget(),
                ),
            ],
          );
        },
      ),
    );
  }

  // 🆕 NUEVO: Widget simplificado para mostrar rutas
  Widget _buildEnhancedRoutePanel(MapViewModel mapViewModel) {
    if (mapViewModel.routeOptions.isEmpty) return const SizedBox.shrink();

    final selectedRoute = mapViewModel.routeOptions.first;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ruta Segura',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: () => mapViewModel.clearAllRoutes(),
                icon: Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRouteInfo(
            'Distancia',
            '${selectedRoute.distance.toStringAsFixed(1)} km',
          ),
          _buildRouteInfo(
            'Duración',
            '${(selectedRoute.duration / 60).round()} min',
          ),
          _buildRouteInfo(
            'Seguridad',
            '${(selectedRoute.safetyLevel * 100).round()}%',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(String label, String value) {
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

  // Método eliminado - ya no se usa el DangerZoneOverlay antiguo
  // bool _shouldShowDangerWarning(MapViewModel mapViewModel) {
  //   return mapViewModel.showDangerZones &&
  //       mapViewModel.clusters.isNotEmpty &&
  //       mapViewModel.clusters.any((cluster) => cluster.severityNumber >= 3);
  // }

  void _handleNavigationTap(BuildContext context, String type) {
    final mapViewModel = context.read<MapViewModel>();

    switch (type) {
      case 'start':
        if (mapViewModel.startPoint != null && mapViewModel.endPoint != null) {
          mapViewModel.startNavigation();
        } else {
          _showNavigationError(
            context,
            'Selecciona puntos de inicio y destino',
          );
        }
        break;
      case 'stop':
        mapViewModel.stopNavigation();
        break;
      case 'clear':
        mapViewModel.clearAllRoutes();
        break;
      case 'report':
        _showReportOptions(context, mapViewModel.currentLocation);
        break;
    }
  }

  void _showReportOptions(BuildContext context, LatLng location) {
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
                    Icon(Icons.report, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Crear Reporte',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información de ubicación
                Text(
                  'Ubicación: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutesConstant.createReport,
                            arguments: {
                              'latitude': location.latitude,
                              'longitude': location.longitude,
                            },
                          );
                        },
                        icon: Icon(Icons.add),
                        label: Text('Nuevo Reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botón de cancelar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showNavigationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
