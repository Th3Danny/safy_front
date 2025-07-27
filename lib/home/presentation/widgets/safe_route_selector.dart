import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/value_objects/safety_level.dart';

class SafeRouteSelector extends StatefulWidget {
  final List<RouteEntity> routes;
  final Function(RouteEntity) onRouteSelected;
  final VoidCallback? onClose;

  const SafeRouteSelector({
    Key? key,
    required this.routes,
    required this.onRouteSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<SafeRouteSelector> createState() => _SafeRouteSelectorState();
}

class _SafeRouteSelectorState extends State<SafeRouteSelector> {
  RouteEntity? _selectedRoute;

  @override
  void initState() {
    super.initState();
    // Seleccionar la ruta recomendada por defecto
    _selectedRoute = widget.routes.firstWhere(
      (route) => route.isRecommended,
      orElse: () => widget.routes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rutas Seguras Disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        '${widget.routes.length} opciones calculadas',
                        style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),

          // Lista de rutas
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: widget.routes.length,
              itemBuilder: (context, index) {
                final route = widget.routes[index];
                final isSelected = _selectedRoute?.id == route.id;

                return _buildRouteCard(route, isSelected, index);
              },
            ),
          ),

          // Botón de acción
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedRoute != null
                        ? () => widget.onRouteSelected(_selectedRoute!)
                        : null,
                icon: const Icon(Icons.navigation, size: 20),
                label: Text(
                  _selectedRoute?.isRecommended == true
                      ? 'Iniciar Ruta Recomendada'
                      : 'Iniciar Ruta Seleccionada',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getRouteColor(_selectedRoute),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteEntity route, bool isSelected, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isSelected
                ? BorderSide(color: _getRouteColor(route), width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedRoute = route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la ruta
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRouteColor(route).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRouteIcon(route),
                          size: 16,
                          color: _getRouteColor(route),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRouteColor(route),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (route.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Recomendada',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Información de la ruta
              Row(
                children: [
                  Expanded(
                    child: _buildRouteInfo(
                      icon: Icons.route,
                      label: 'Distancia',
                      value: '${route.distanceKm.toStringAsFixed(1)} km',
                    ),
                  ),
                  Expanded(
                    child: _buildRouteInfo(
                      icon: Icons.access_time,
                      label: 'Duración',
                      value: '${route.durationMinutes} min',
                    ),
                  ),
                  Expanded(
                    child: _buildRouteInfo(
                      icon: Icons.shield,
                      label: 'Seguridad',
                      value: '${route.safetyLevel.percentage.toInt()}%',
                      valueColor: _getSafetyColor(route.safetyLevel),
                    ),
                  ),
                ],
              ),

              // Advertencias si las hay
              if (route.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Advertencias:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...route.warnings.map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(left: 24, top: 2),
                          child: Text(
                            '• $warning',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Descripción de seguridad
              const SizedBox(height: 8),
              Text(
                route.safetyLevel.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Color _getRouteColor(RouteEntity? route) {
    if (route == null) return Colors.grey;

    if (route.safetyLevel.percentage >= 80) return Colors.green;
    if (route.safetyLevel.percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getSafetyColor(SafetyLevel safetyLevel) {
    if (safetyLevel.percentage >= 80) return Colors.green;
    if (safetyLevel.percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getRouteIcon(RouteEntity route) {
    if (route.name.toLowerCase().contains('segura')) {
      return Icons.shield;
    } else if (route.name.toLowerCase().contains('perimetral')) {
      return Icons.track_changes;
    } else if (route.name.toLowerCase().contains('desvío')) {
      return Icons.alt_route;
    } else {
      return Icons.route;
    }
  }
}
