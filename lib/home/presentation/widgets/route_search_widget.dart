
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class RouteSearchWidget extends StatefulWidget {
  const RouteSearchWidget({super.key});

  @override
  State<RouteSearchWidget> createState() => _RouteSearchWidgetState();
}

class _RouteSearchWidgetState extends State<RouteSearchWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  
  bool _isExpanded = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        return Column(
          children: [
            // Botón principal de búsqueda
            _buildSearchButton(context, mapViewModel),
            
            // Panel expandible de búsqueda
            if (_isExpanded)
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildExpandedSearchPanel(context, mapViewModel),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchButton(BuildContext context, MapViewModel mapViewModel) {
    return GestureDetector(
      onTap: () => _toggleExpanded(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
            Icon(
              Icons.search,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getSearchButtonText(mapViewModel),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (mapViewModel.startPoint != null || mapViewModel.endPoint != null)
              IconButton(
                onPressed: () => _clearRoute(mapViewModel),
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSearchPanel(BuildContext context, MapViewModel mapViewModel) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Campo de origen
          _buildLocationField(
            controller: _startController,
            label: 'Desde',
            icon: Icons.play_arrow,
            iconColor: Colors.green,
            hint: 'Punto de origen',
            currentPoint: mapViewModel.startPoint,
            onUseCurrentLocation: () => _useCurrentLocation(mapViewModel, true),
            onClear: () => _clearPoint(mapViewModel, true),
          ),
          
          const SizedBox(height: 12),
          
          // Botón para intercambiar puntos
          Center(
            child: IconButton(
              onPressed: () => _swapPoints(mapViewModel),
              icon: const Icon(Icons.swap_vert),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[600],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Campo de destino
          _buildLocationField(
            controller: _endController,
            label: 'Hasta',
            icon: Icons.stop,
            iconColor: Colors.red,
            hint: 'Punto de destino',
            currentPoint: mapViewModel.endPoint,
            onUseCurrentLocation: () => _useCurrentLocation(mapViewModel, false),
            onClear: () => _clearPoint(mapViewModel, false),
          ),
          
          const SizedBox(height: 16),
          
          // Modo de transporte
          _buildTransportModeSelector(mapViewModel),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toggleExpanded(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSearchRoutes(mapViewModel) 
                      ? () => _searchRoutes(mapViewModel)
                      : null,
                  child: _isSearching 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buscar rutas'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String hint,
    required LatLng? currentPoint,
    required VoidCallback onUseCurrentLocation,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentPoint != null)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  onPressed: onUseCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          readOnly: true, // Por ahora solo soportamos selección en el mapa
        ),
        if (currentPoint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Lat: ${currentPoint.latitude.toStringAsFixed(4)}, '
              'Lng: ${currentPoint.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransportModeSelector(MapViewModel mapViewModel) {
    final modes = [
      {'id': 'walk', 'icon': Icons.directions_walk, 'label': 'Caminar'},
      {'id': 'car', 'icon': Icons.directions_car, 'label': 'Auto'},
      {'id': 'bus', 'icon': Icons.directions_bus, 'label': 'Bus'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modo de transporte',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: modes.map((mode) {
            final isSelected = mapViewModel.selectedTransportMode == mode['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => mapViewModel.setTransportMode(mode['id'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mode['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getSearchButtonText(MapViewModel mapViewModel) {
    if (mapViewModel.startPoint != null && mapViewModel.endPoint != null) {
      return 'Ruta configurada - Toca para editar';
    } else if (mapViewModel.startPoint != null) {
      return 'Selecciona destino en el mapa';
    } else if (mapViewModel.endPoint != null) {
      return 'Selecciona origen en el mapa';
    } else {
      return '¿A dónde quieres ir?';
    }
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

  void _useCurrentLocation(MapViewModel mapViewModel, bool isStart) {
    if (isStart) {
      mapViewModel.setStartPoint(mapViewModel.currentLocation);
      _startController.text = 'Mi ubicación actual';
    } else {
      mapViewModel.setEndPoint(mapViewModel.currentLocation);
      _endController.text = 'Mi ubicación actual';
    }
  }

  void _clearPoint(MapViewModel mapViewModel, bool isStart) {
  if (isStart) {
    // Limpiar solo el punto de inicio
    mapViewModel.clearStartPoint();
    _startController.clear();
  } else {
    // Limpiar solo el punto de destino
    mapViewModel.clearEndPoint();
    _endController.clear();
  }
}

  void _swapPoints(MapViewModel mapViewModel) {
    final tempStart = mapViewModel.startPoint;
    final tempEnd = mapViewModel.endPoint;
    
    if (tempStart != null) {
      mapViewModel.setEndPoint(tempStart);
    }
    if (tempEnd != null) {
      mapViewModel.setStartPoint(tempEnd);
    }
    
    // Intercambiar textos de los controladores también
    final tempText = _startController.text;
    _startController.text = _endController.text;
    _endController.text = tempText;
  }

  void _clearRoute(MapViewModel mapViewModel) {
    mapViewModel.clearRoute();
    _startController.clear();
    _endController.clear();
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
  }

  bool _canSearchRoutes(MapViewModel mapViewModel) {
    return mapViewModel.startPoint != null && 
           mapViewModel.endPoint != null && 
           !_isSearching;
  }

  Future<void> _searchRoutes(MapViewModel mapViewModel) async {
    setState(() {
      _isSearching = true;
    });

    try {
      await mapViewModel.calculateRoutes();
      _toggleExpanded(); // Cerrar panel después de buscar
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
}