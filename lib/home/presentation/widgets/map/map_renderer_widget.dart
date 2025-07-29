import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/map/map_layers/map_layers.dart';
import 'package:safy/home/presentation/widgets/map/map_controls/map_controls.dart';
import 'package:safy/home/presentation/widgets/map/map_handlers/map_handlers.dart';

class MapRendererWidget extends StatefulWidget {
  const MapRendererWidget({super.key});

  @override
  State<MapRendererWidget> createState() => _MapRendererWidgetState();
}

class _MapRendererWidgetState extends State<MapRendererWidget> {
  final MapController _mapController = MapController();
  double _currentZoom = 15.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        // Removed debug print
        // Removed debug print
        // Removed debug print

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapViewModel.currentLocation,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 18,
                onMapReady: () {},
                onTap:
                    (tapPosition, point) =>
                        MapHandlers.handleMapTap(context, point),
                onPositionChanged: (position, hasGesture) {
                  _handlePositionChanged(position, hasGesture, mapViewModel);
                },
              ),
              children: [
                // Capa base del mapa
                MapLayers.buildTileLayer(),

                // Capa de rutas
                MapLayers.buildPolylineLayer(mapViewModel),

                // 🆕 NUEVO: Capa de todos los marcadores (incluye predicciones)
                MapLayers.buildAllMarkersLayer(mapViewModel),
              ],
            ),

            // Controles del mapa
            MapControls.buildMapControls(context, mapViewModel),
          ],
        );
      },
    );
  }

  void _handlePositionChanged(
    dynamic position,
    bool hasGesture,
    MapViewModel mapViewModel,
  ) {
    // Actualizar zoom actual
    if (_currentZoom != position.zoom) {
      setState(() {
        _currentZoom = position.zoom;
      });
    }

    if (hasGesture) {
      // Removed debug print
      // Removed debug print
      // Removed debug print

      // Cargar clusters dinámicamente
      mapViewModel.loadClustersForMapViewFromWidget(
        position.center,
        position.zoom,
      );
    }
  }
}
