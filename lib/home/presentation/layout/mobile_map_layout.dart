import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/danger_zone_overlay.dart';
import 'package:safy/home/presentation/widgets/map_controls_widget.dart';
import 'package:safy/home/presentation/widgets/map_widget.dart';
import 'package:safy/home/presentation/widgets/navigation_fab.dart';
import 'package:safy/home/presentation/widgets/route_options_widget.dart';
import 'package:safy/home/presentation/widgets/route_search_widget.dart';
import 'package:safy/home/presentation/widgets/weather_widget.dart';


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

              // 🌤 Widget de clima
              const Positioned(
                top: 50,
                left: 16,
                child: WeatherWidget(),
              ),

              // 🎯 Controles del mapa
              Positioned(
                top: 50,
                right: 16,
                child: MapControlsWidget(
                  onLocationPressed: () => mapViewModel.centerOnCurrentLocation(),
                  onToggleDangerZones: () => mapViewModel.toggleDangerZones(),
                  showDangerZones: mapViewModel.showDangerZones,
                ),
              ),

              // 🔍 Búsqueda de rutas
              const Positioned(
                top: 120,
                left: 16,
                right: 16,
                child: RouteSearchWidget(),
              ),

              // 📋 Opciones de ruta (cuando hay rutas calculadas)
              if (mapViewModel.routeOptions.isNotEmpty)
                Positioned(
                  top: 200,
                  left: 16,
                  right: 16,
                  child: RouteOptionsWidget(
                    routes: mapViewModel.routeOptions,
                    onRouteSelected: (route) => mapViewModel.selectRoute(route),
                    onClearRoute: () => mapViewModel.clearRoute(),
                  ),
                ),

              // 🚨 Overlay de zona peligrosa
              if (_shouldShowDangerWarning(mapViewModel))
                const DangerZoneOverlay(),

              // 🧭 Panel de navegación inferior
              NavigationFab(
                onNavigationTap: (type) => _handleNavigationTap(context, type),
                //selectedMode: mapViewModel.selectedTransportMode,
              ),

              // ❌ Mensaje de error
              if (mapViewModel.errorMessage != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mapViewModel.errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => mapViewModel.clearError(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowDangerWarning(MapViewModel mapViewModel) {
    // Lógica para determinar si mostrar advertencia de zona peligrosa
    // Podrías verificar si el usuario está cerca de una zona peligrosa
    return false; // Por ahora desactivado
  }

  void _handleNavigationTap(BuildContext context, String type) {
    final mapViewModel = context.read()<MapViewModel>();
    
    switch (type) {
      case 'add':
        Navigator.pushNamed(context, '/create-report');
        break;
      case 'walk':
      case 'car':
      case 'bus':
        mapViewModel.setTransportMode(type);
        _showTransportModeMessage(context, type);
        break;
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
      ),
    );
  }
}