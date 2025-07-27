import 'package:flutter/material.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';

class DesktopControlPanel extends StatelessWidget {
  final MapViewModel mapViewModel;

  const DesktopControlPanel({super.key, required this.mapViewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del panel
          Text(
            'Panel de Control',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Sección de controles del mapa
          _buildSection(
            title: 'Controles del Mapa',
            children: [
              SwitchListTile(
                title: const Text('Mostrar zonas peligrosas'),
                subtitle: const Text('Visualizar áreas de riesgo'),
                value: mapViewModel.showDangerZones,
                onChanged: (_) => mapViewModel.toggleDangerZones(),
                secondary: Icon(
                  Icons.warning,
                  color:
                      mapViewModel.showDangerZones ? Colors.red : Colors.grey,
                ),
              ),

              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text('Centrar en mi ubicación'),
                subtitle: const Text('Volver a la posición actual'),
                onTap: () => mapViewModel.centerOnCurrentLocation(),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sección de modo de transporte deshabilitada para esta versión. Reactivar en el futuro si es necesario.
          // _buildSection(
          //   title: 'Modo de Transporte',
          //   children: [
          //     _buildTransportOption('walk', 'Caminar', Icons.directions_walk),
          //     _buildTransportOption('car', 'Auto', Icons.directions_car),
          //     _buildTransportOption('bus', 'Transporte público', Icons.directions_bus),
          //   ],
          // ),
          const SizedBox(height: 20),

          // Información de ruta actual
          if (mapViewModel.routeOptions.isNotEmpty)
            _buildSection(title: 'Ruta Actual', children: [_buildRouteInfo()]),

          const Spacer(),

          // Acciones rápidas
          _buildSection(
            title: 'Acciones Rápidas',
            children: [
              ListTile(
                leading: const Icon(Icons.add_box, color: Colors.red),
                title: const Text('Reportar incidente'),
                onTap: () => context.go(AppRoutesConstant.createReport),
              ),

              ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.green),
                title: const Text('Contactos de emergencia'),
                onTap: () => context.go(AppRoutesConstant.helpInstitutions),
              ),

              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Configuración'),
                onTap: () => context.go(AppRoutesConstant.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTransportOption(String mode, String label, IconData icon) {
    final isSelected = mapViewModel.selectedTransportMode == mode;

    return RadioListTile<String>(
      value: mode,
      groupValue: mapViewModel.selectedTransportMode,
      onChanged: (value) {
        if (value != null) {
          mapViewModel.setTransportMode(value);
        }
      },
      title: Text(label),
      secondary: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
    );
  }

  Widget _buildRouteInfo() {
    final recommendedRoute =
        mapViewModel.routeOptions
            .where((route) => route.isRecommended)
            .firstOrNull;

    if (recommendedRoute == null) {
      return const ListTile(
        title: Text('No hay ruta seleccionada'),
        subtitle: Text('Selecciona origen y destino en el mapa'),
      );
    }

    return Column(
      children: [
        ListTile(
          title: Text(recommendedRoute.name),
          subtitle: Text(
            '${recommendedRoute.distance.toStringAsFixed(1)} km • '
            '${recommendedRoute.duration} min',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: recommendedRoute.safetyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendedRoute.safetyText,
              style: TextStyle(
                color: recommendedRoute.safetyColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => mapViewModel.clearRoute(),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Iniciar navegación
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navegar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
