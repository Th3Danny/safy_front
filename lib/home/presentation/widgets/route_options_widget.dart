import 'package:flutter/material.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class RouteOptionsWidget extends StatefulWidget {
  final List<RouteOption> routes;
  final Function(RouteOption) onRouteSelected;
  final VoidCallback onClearRoute;

  const RouteOptionsWidget({
    super.key,
    required this.routes,
    required this.onRouteSelected,
    required this.onClearRoute,
  });

  @override
  State<RouteOptionsWidget> createState() => _RouteOptionsWidgetState();
}

class _RouteOptionsWidgetState extends State<RouteOptionsWidget>
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
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Encontrar la ruta recomendada como seleccionada por defecto
    _selectedRouteIndex = widget.routes.indexWhere(
      (route) => route.isRecommended,
    );
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
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con título y botón cerrar
            _buildHeader(),

            // Lista de rutas
            Flexible(child: _buildRoutesList()),

            // Botones de acción
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
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rutas disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClearRoute,
            icon: Icon(Icons.close, color: Colors.grey[600]),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
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
        // Título y badge recomendado
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
            // Distancia
            Expanded(
              child: _buildInfoItem(
                Icons.straighten,
                '${route.distance.toStringAsFixed(1)} km',
                'Distancia',
              ),
            ),

            // Tiempo
            Expanded(
              child: _buildInfoItem(
                Icons.access_time,
                '${route.duration} min',
                'Tiempo',
              ),
            ),

            // Seguridad
            Expanded(child: _buildSafetyInfo(route)),
          ],
        ),

        const SizedBox(height: 12),

        // Descripción de la ruta
        _buildRouteDescription(route),
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

  Widget _buildRouteDescription(RouteOption route) {
    String description;
    switch (route.name) {
      case 'Ruta Directa':
        description = 'Ruta real más directa por caminos existentes';
        break;
      case 'Ruta Segura':
        description = 'Evita zonas peligrosas, priorizando tu seguridad';
        break;
      case 'Ruta Alternativa':
        description = 'Ruta alternativa por diferentes caminos';
        break;
      default:
        description = 'Ruta calculada según tus preferencias';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final selectedRoute = widget.routes[_selectedRouteIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Información rápida de la ruta seleccionada
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
                  '${selectedRoute.distance.toStringAsFixed(1)} km • ${selectedRoute.duration} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Botón de iniciar navegación
          ElevatedButton.icon(
            onPressed: () => _startNavigation(selectedRoute),
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('Iniciar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
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
    // Aquí podrías agregar lógica para iniciar navegación paso a paso
    widget.onRouteSelected(route);

    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.navigation, color: Colors.white),
            const SizedBox(width: 8),
            Text('Navegación iniciada: ${route.name}'),
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'DETENER',
          textColor: Colors.white,
          onPressed: widget.onClearRoute,
        ),
      ),
    );
  }
}
