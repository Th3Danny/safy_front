// lib/features/home/presentation/pages/mobile_map_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/danger_zone_overlay.dart';
import 'package:safy/home/presentation/widgets/map_controls_widget.dart';
import 'package:safy/home/presentation/widgets/map_widget.dart';
import 'package:safy/home/presentation/widgets/navigation_fab.dart';
import 'package:safy/home/presentation/widgets/place_search_widget.dart';
import 'package:safy/home/presentation/widgets/route_options_widget.dart';
import 'package:safy/home/presentation/widgets/navigation_progress_widget.dart';
import 'package:safy/home/presentation/widgets/gps_security_widget.dart';

class MobileMapLayout extends StatelessWidget {
  const MobileMapLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapViewModel>(
        builder: (context, mapViewModel, child) {
          return Stack(
            children: [
              // 🌍 Mapa principal
              const MapWidget(),

              // 🎯 Controles del mapa (ACTUALIZADO con todos los parámetros)
              Positioned(
                top: 50,
                right: 16,
                child: MapControlsWidget(
                  onLocationPressed:
                      () => mapViewModel.centerOnCurrentLocation(),
                  onToggleDangerZones: () => mapViewModel.toggleDangerZones(),
                  onToggleClusters: () => mapViewModel.toggleClusters(),
                  onRefreshClusters: () => mapViewModel.refreshDangerousZones(),
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

              // 📋 Opciones de ruta (cuando hay rutas calculadas)
              if (mapViewModel.routeOptions.isNotEmpty &&
                  mapViewModel.showRoutePanel)
                Positioned(
                  top: 180, // Ajustado para dar espacio al PlaceSearchWidget
                  left: 16,
                  right: 16,
                  child: FloatingRouteControl(
                    routes: mapViewModel.routeOptions,
                    onRouteSelected: (route) => mapViewModel.selectRoute(route),
                    onClearRoute: () => mapViewModel.clearAllRoutes(),
                    onClose: () => mapViewModel.hideRoutePanel(),
                  ),
                ),

              // 🚨 Overlay de zona peligrosa
              if (_shouldShowDangerWarning(mapViewModel))
                const DangerZoneOverlay(),

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

              // ⚠️ Mensaje de error (mejorado para clusters) - EXCLUYENDO GPS FALSO
              if ((mapViewModel.errorMessage != null &&
                      !mapViewModel.errorMessage!.contains('GPS Falso')) ||
                  mapViewModel.clustersError != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: _buildErrorMessage(
                    context,
                    mapViewModel.errorMessage ?? mapViewModel.clustersError!,
                    () => mapViewModel.clearError(),
                  ),
                ),

              // 🔄 Indicador de carga para clusters (mejorado)
              if (mapViewModel.clustersLoading)
                Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  child: _buildLoadingIndicator(),
                ),

              // 🧭 Widget de progreso de navegación
              const NavigationProgressWidget(),

              // 🔒 Widget de seguridad GPS - SOLO CUANDO HAY GPS FALSO
              GpsSecurityWidget(
                spoofingResult: mapViewModel.gpsSpoofingResult,
                onReset: () => mapViewModel.resetGpsSpoofingDetector(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage(
    BuildContext context,
    String message,
    VoidCallback onDismiss,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error en el mapa',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close, color: Colors.red.shade600, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Actualizando mapa',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cargando zonas peligrosas...',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDangerWarning(MapViewModel mapViewModel) {
    // Verificar si el usuario está cerca de una zona peligrosa usando los clusters
    try {
      return mapViewModel.isLocationDangerous(mapViewModel.currentLocation);
    } catch (e) {
      return false;
    }
  }

  void _handleNavigationTap(BuildContext context, String type) {
    final mapViewModel = context.read<MapViewModel>();

    switch (type) {
      case 'add':
        // 🧹 Limpiar todas las rutas previas antes de iniciar nueva navegación
        mapViewModel.clearAllRoutes();

        // Mostrar mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧹 Rutas limpiadas. Listo para nueva navegación.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        break;
      // Los siguientes modos de transporte se reactivarán en una versión futura:
      // case 'walk':
      // case 'car':
      // case 'bus':
      //   mapViewModel.setTransportMode(type);
      //   _showTransportModeMessage(context, type);
      //   break;
    }
  }

  void _showTransportModeMessage(BuildContext context, String mode) {
    final modeNames = {
      'walk': 'Caminar',
      'car': 'Auto',
      'bus': 'Transporte público',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modo de transporte: ${modeNames[mode]}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
