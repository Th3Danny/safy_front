import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/viewmodel/route_mixin.dart';

class FloatingRouteControl extends StatefulWidget {
  final List<RouteOption> routes;
  final Function(RouteOption) onRouteSelected;
  final VoidCallback onClearRoute;
  final VoidCallback? onClose; // Nuevo callback para cerrar el panel

  const FloatingRouteControl({
    super.key,
    required this.routes,
    required this.onRouteSelected,
    required this.onClearRoute,
    this.onClose, // Hacer opcional para compatibilidad
  });

  @override
  State<FloatingRouteControl> createState() => _FloatingRouteControlState();
}

class _FloatingRouteControlState extends State<FloatingRouteControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  int _selectedRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Seleccionar la ruta recomendada por defecto
    _selectedRouteIndex = widget.routes.indexWhere(
      (route) => route.isRecommended,
    );
    if (_selectedRouteIndex == -1) _selectedRouteIndex = 0;

    // Seleccionar automáticamente la ruta recomendada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.routes.isNotEmpty) {
        widget.onRouteSelected(widget.routes[_selectedRouteIndex]);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _closePanel() {
    // Usar el callback si está disponible, sino no hacer nada
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      // Fallback: intentar cerrar solo si es seguro
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routes.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panel expandido con todas las rutas
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildExpandedHeader(),
                    Flexible(child: _buildRoutesList()),
                  ],
                ),
              ),
            );
          },
        ),

        // Panel compacto (siempre visible)
        _buildCompactPanel(),
      ],
    );
  }

  Widget _buildExpandedHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rutas Seguras (${widget.routes.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleExpanded,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            tooltip: 'Minimizar',
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
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final route = widget.routes[index];
        final isSelected = index == _selectedRouteIndex;

        return GestureDetector(
          onTap: () => _selectRoute(index, route),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icono de seguridad
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: route.safetyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.security,
                    color: route.safetyColor,
                    size: 16,
                  ),
                ),

                const SizedBox(width: 12),

                // Información de la ruta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              route.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? Colors.blue[700]
                                        : Colors.grey[800],
                              ),
                            ),
                          ),
                          if (route.isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'MEJOR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.distance.toStringAsFixed(1)} km • ${route.duration} min • ${route.safetyLevel.toInt()}% segura',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Indicador de selección
                if (isSelected)
                  Icon(Icons.check_circle, color: Colors.blue, size: 20)
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactPanel() {
    final selectedRoute = widget.routes[_selectedRouteIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Indicador de seguridad
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selectedRoute.safetyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.security,
              color: selectedRoute.safetyColor,
              size: 16,
            ),
          ),

          const SizedBox(width: 8),

          // Información de la ruta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedRoute.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (selectedRoute.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MEJOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${selectedRoute.distance.toStringAsFixed(1)} km • ${selectedRoute.duration} min • ${selectedRoute.safetyLevel.toInt()}% segura',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Botones de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón para expandir (solo si hay más de 1 ruta)
              if (widget.routes.length > 1)
                IconButton(
                  onPressed: _toggleExpanded,
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Colors.grey[600],
                  ),
                  tooltip: _isExpanded ? 'Minimizar' : 'Ver todas',
                ),

              // Botón de navegación
              ElevatedButton.icon(
                onPressed: () => _startNavigation(selectedRoute),
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text('Iniciar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRoute.safetyColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                ),
              ),

              const SizedBox(width: 4),

              // Botón cerrar - SOLUCIONADO
              IconButton(
                onPressed: _closePanel, // Usar el método seguro
                icon: Icon(Icons.close, color: Colors.grey[600], size: 18),
                tooltip: 'Cerrar panel',
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
    final mapViewModel = GetIt.instance<MapViewModel>();

    // 🧹 Limpiar todas las rutas previas antes de iniciar nueva navegación
    mapViewModel.clearAllRoutes();

    // Iniciar navegación con seguimiento dinámico
    mapViewModel.startNavigationWithTracking();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.navigation, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Navegación iniciada: ${route.name}')),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }
}