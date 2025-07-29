import 'package:flutter/material.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/place_search_widget.dart';
import 'package:safy/home/presentation/widgets/route_suggestions_widget.dart';

class MapControls {
  static Widget buildMapControls(
    BuildContext context,
    MapViewModel mapViewModel,
  ) {
    return Stack(
      children: [
        // Barra de búsqueda en la parte superior
        Positioned(top: 50, left: 16, right: 16, child: PlaceSearchWidget()),

        // Botón de ubicación actual
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              // Usar el método correcto del ViewModel
              mapViewModel.loadDangerousClustersWithCurrentLocation();
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),

        // Botón de sugerencias de ruta
        if (mapViewModel.currentRoute.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildRouteSuggestionsButton(context, mapViewModel),
          ),
      ],
    );
  }

  static Widget _buildRouteSuggestionsButton(
    BuildContext context,
    MapViewModel mapViewModel,
  ) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRouteSuggestions(context, mapViewModel),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ver Sugerencias de Ruta',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Ruta actual: ${mapViewModel.currentRouteName ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showRouteSuggestions(
    BuildContext context,
    MapViewModel mapViewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: RouteSuggestionsWidget(
                          safeRoutePoints: mapViewModel.currentRoute,
                          safeDistance: 1000.0,
                          safeDuration: 600,
                          safeSafetyLevel: 0.8,
                          fastRoutePoints: mapViewModel.currentRoute,
                          extraSafeRoutePoints: mapViewModel.currentRoute,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
