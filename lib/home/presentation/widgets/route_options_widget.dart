import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/home/presentation/widgets/viewmodel/route_mixin.dart';

class EnhancedRouteOptionsWidget extends StatefulWidget {
  final List<RouteOption> routes;
  final Function(RouteOption) onRouteSelected;
  final VoidCallback onClearRoute;

  const EnhancedRouteOptionsWidget({
    super.key,
    required this.routes,
    required this.onRouteSelected,
    required this.onClearRoute,
  });

  @override
  State<EnhancedRouteOptionsWidget> createState() => _EnhancedRouteOptionsWidgetState();
}

class _EnhancedRouteOptionsWidgetState extends State<EnhancedRouteOptionsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  int _selectedRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _selectedRouteIndex = widget.routes.indexWhere((route) => route.isRecommended);
    if (_selectedRouteIndex == -1) _selectedRouteIndex = 0;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildRoutesList()),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rutas Seguras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.routes.length} opciones con análisis de seguridad',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClearRoute,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: widget.routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final route = widget.routes[index];
        final isSelected = index == _selectedRouteIndex;

        return GestureDetector(
          onTap: () => _selectRoute(index, route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: _buildRouteCard(route, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(RouteOption route, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y badge
        Row(
          children: [
            Expanded(
              child: Text(
                route.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue[700] : Colors.grey[800],
                ),
              ),
            ),
            if (route.isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RECOMENDADA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Información principal de la ruta
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.straighten,
                '${route.distance.toStringAsFixed(1)} km',
                'Distancia',
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                Icons.access_time,
                '${route.duration} min',
                'Tiempo',
              ),
            ),
            Expanded(child: _buildSafetyInfo(route)),
          ],
        ),

        const SizedBox(height: 12),

        // 🆕 INFORMACIÓN DE SEGURIDAD MEJORADA
        _buildSafetyDetails(route),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSafetyInfo(RouteOption route) {
    return Column(
      children: [
        Icon(Icons.security, size: 20, color: route.safetyColor),
        const SizedBox(height: 4),
        Text(
          '${route.safetyLevel.toInt()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: route.safetyColor,
          ),
        ),
        Text(
          route.safetyText,
          style: TextStyle(
            fontSize: 12,
            color: route.safetyColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 🆕 DETALLES DE SEGURIDAD MEJORADOS
  Widget _buildSafetyDetails(RouteOption route) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: route.safetyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: route.safetyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: route.safetyColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getSafetyDescription(route.safetyLevel),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: route.safetyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Consejos de seguridad dinámicos
          ..._getSafetyTips(route).map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 12, color: Colors.amber[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getSafetyDescription(double safetyLevel) {
    if (safetyLevel >= 80) return 'Ruta muy segura - Sin peligros conocidos';
    if (safetyLevel >= 60) return 'Ruta segura - Pocos riesgos detectados';
    if (safetyLevel >= 40) return 'Ruta moderada - Algunos peligros en el área';
    return 'Ruta riesgosa - Múltiples peligros reportados';
  }

  List<String> _getSafetyTips(RouteOption route) {
    final tips = <String>[];
    
    if (route.safetyLevel < 60) {
      tips.add('Mantente alerta en esta ruta');
      if (route.name == 'Ruta Segura') {
        tips.add('Esta ruta evita las zonas más peligrosas');
      }
    }
    
    final hour = DateTime.now().hour;
    if (hour >= 20 || hour <= 6) {
      tips.add('Considera usar transporte público de noche');
    }
    
    if (route.safetyLevel >= 80) {
      tips.add('Excelente opción para caminar');
    }
    
    return tips.take(2).toList(); // Máximo 2 consejos
  }

  Widget _buildActionButtons() {
    final selectedRoute = widget.routes[_selectedRouteIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Información rápida de la ruta seleccionada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: selectedRoute.safetyColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedRoute.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${selectedRoute.distance.toStringAsFixed(1)} km • ${selectedRoute.duration} min • ${selectedRoute.safetyLevel.toInt()}% segura',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onRouteSelected(selectedRoute);
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Vista Previa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startNavigation(selectedRoute),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRoute.safetyColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectRoute(int index, RouteOption route) {
    setState(() {
      _selectedRouteIndex = index;
    });
    widget.onRouteSelected(route);
  }

  void _startNavigation(RouteOption route) {
    widget.onRouteSelected(route);

    final mapViewModel = GetIt.instance<MapViewModel>();
    mapViewModel.startNavigation();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.navigation, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Navegación iniciada: ${route.name}'),
                  Text(
                    'Seguridad: ${route.safetyLevel.toInt()}% - ${route.safetyText}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: route.safetyColor,
        action: SnackBarAction(
          label: 'DETENER',
          textColor: Colors.white,
          onPressed: () {
            mapViewModel.stopNavigation();
            widget.onClearRoute();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}