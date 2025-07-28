import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/viewmodel/route_mixin.dart';

class RouteSuggestionsWidget extends StatefulWidget {
  final List<LatLng> safeRoutePoints;
  final List<LatLng> fastRoutePoints;
  final List<LatLng> extraSafeRoutePoints;
  final double safeDistance;
  final int safeDuration;
  final double safeSafetyLevel;

  const RouteSuggestionsWidget({
    super.key,
    required this.safeRoutePoints,
    required this.fastRoutePoints,
    required this.extraSafeRoutePoints,
    required this.safeDistance,
    required this.safeDuration,
    required this.safeSafetyLevel,
  });

  @override
  State<RouteSuggestionsWidget> createState() => _RouteSuggestionsWidgetState();
}

class _RouteSuggestionsWidgetState extends State<RouteSuggestionsWidget> {
  int _selectedRouteIndex = 0; // 0 = Segura, 1 = Rápida, 2 = Extra Segura

  @override
  void initState() {
    super.initState();
    // Mantener la selección anterior si existe
    final mapViewModel = context.read<MapViewModel>();
    if (mapViewModel.currentRoute.isNotEmpty) {
      // Intentar determinar qué ruta está seleccionada basándose en el nombre
      final routeName = mapViewModel.currentRouteName ?? '';
      if (routeName.contains('Rápida')) {
        _selectedRouteIndex = 1;
      } else if (routeName.contains('Extra Segura')) {
        _selectedRouteIndex = 2;
      } else {
        _selectedRouteIndex = 0; // Segura por defecto
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Título
          Row(
            children: [
              Icon(Icons.route, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sugerencias de Ruta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ruta Segura
          _buildRouteOption(
            context,
            'Ruta Segura (Recomendada)',
            'Evita zonas peligrosas',
            Icons.shield,
            Colors.green,
            widget.safeDistance,
            widget.safeDuration,
            widget.safeSafetyLevel,
            isSelected: _selectedRouteIndex == 0,
            onTap: () => _selectRoute(0),
          ),

          const SizedBox(height: 12),

          // Ruta Rápida
          _buildRouteOption(
            context,
            'Ruta Rápida',
            'Tiempo mínimo',
            Icons.speed,
            Colors.orange,
            widget.safeDistance * 0.8,
            (widget.safeDuration * 0.7).round(),
            widget.safeSafetyLevel * 0.8,
            isSelected: _selectedRouteIndex == 1,
            onTap: () => _selectRoute(1),
          ),

          const SizedBox(height: 12),

          // Ruta Extra Segura
          _buildRouteOption(
            context,
            'Ruta Extra Segura',
            'Máxima seguridad',
            Icons.security,
            Colors.blue,
            widget.safeDistance * 1.3,
            (widget.safeDuration * 1.4).round(),
            (widget.safeSafetyLevel * 1.2).clamp(0.0, 1.0),
            isSelected: _selectedRouteIndex == 2,
            onTap: () => _selectRoute(2),
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              // Botón para cambiar ruta
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Cambiar a la siguiente ruta
                    _selectRoute((_selectedRouteIndex + 1) % 3);
                  },
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Cambiar Ruta'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de iniciar navegación
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final mapViewModel = context.read<MapViewModel>();
                    mapViewModel.startNavigationWithTracking();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text('Iniciar Navegación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

  // 🆕 MÉTODO PARA SELECCIONAR RUTA Y ACTUALIZAR INMEDIATAMENTE
  void _selectRoute(int routeIndex) {
    print('🛣️ [RouteSuggestionsWidget] Seleccionando ruta: $routeIndex');

    setState(() {
      _selectedRouteIndex = routeIndex;
    });

    final mapViewModel = context.read<MapViewModel>();

    // Obtener la ruta seleccionada
    List<LatLng> selectedRoute;
    String routeName;
    double distance;
    int duration;
    double safetyLevel;

    switch (routeIndex) {
      case 0:
        selectedRoute = widget.safeRoutePoints;
        routeName = 'Ruta Segura';
        distance = widget.safeDistance;
        duration = widget.safeDuration;
        safetyLevel = widget.safeSafetyLevel;
        break;
      case 1:
        selectedRoute = widget.fastRoutePoints;
        routeName = 'Ruta Rápida';
        distance = widget.safeDistance * 0.8;
        duration = (widget.safeDuration * 0.7).round();
        safetyLevel = widget.safeSafetyLevel * 0.8;
        break;
      case 2:
        selectedRoute = widget.extraSafeRoutePoints;
        routeName = 'Ruta Extra Segura';
        distance = widget.safeDistance * 1.3;
        duration = (widget.safeDuration * 1.4).round();
        safetyLevel = (widget.safeSafetyLevel * 1.2).clamp(0.0, 1.0);
        break;
      default:
        selectedRoute = widget.safeRoutePoints;
        routeName = 'Ruta Segura';
        distance = widget.safeDistance;
        duration = widget.safeDuration;
        safetyLevel = widget.safeSafetyLevel;
    }

    print('🛣️ [RouteSuggestionsWidget] Ruta seleccionada: $routeName');
    print(
      '🛣️ [RouteSuggestionsWidget] Puntos de ruta: ${selectedRoute.length}',
    );
    print(
      '🛣️ [RouteSuggestionsWidget] Primer punto: ${selectedRoute.isNotEmpty ? selectedRoute.first : 'N/A'}',
    );
    print(
      '🛣️ [RouteSuggestionsWidget] Último punto: ${selectedRoute.isNotEmpty ? selectedRoute.last : 'N/A'}',
    );

    // 🆕 ACTUALIZAR LA RUTA INMEDIATAMENTE EN EL MAPA
    mapViewModel.setCurrentRouteWithName(selectedRoute, routeName);

    print('🛣️ [RouteSuggestionsWidget] Ruta actualizada en ViewModel');
    print(
      '🛣️ [RouteSuggestionsWidget] Ruta actual en ViewModel: ${mapViewModel.currentRoute.length} puntos',
    );

    // 🆕 MOSTRAR CONFIRMACIÓN VISUAL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.route, color: Colors.white),
            const SizedBox(width: 8),
            Text('Ruta cambiada a: $routeName'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    print('🛣️ Ruta cambiada a: $routeName (${selectedRoute.length} puntos)');
  }

  Widget _buildRouteOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double distance,
    int duration,
    double safety, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${(duration / 60).round()} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSafetyColor(safety),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(safety * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Color _getSafetyColor(double safety) {
    if (safety >= 0.8) return Colors.green;
    if (safety >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
