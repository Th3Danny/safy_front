import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/place_search_widget.dart';
import 'package:safy/home/presentation/widgets/route_options_widget.dart';


class MapOverlayWidgets extends StatelessWidget {
  const MapOverlayWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        return SafeArea(
          child: Column(
            children: [
              // Widget de búsqueda de lugares (siempre visible)
              const PlaceSearchWidget(),
              
              
              
              const Spacer(),
              
              // Widget de opciones de rutas (cuando hay rutas calculadas)
              if (mapViewModel.routeOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: EnhancedRouteOptionsWidget(
                    routes: mapViewModel.routeOptions,
                    onRouteSelected: (route) {
                      mapViewModel.selectRoute(route);
                    },
                    onClearRoute: () {
                      mapViewModel.clearRoute();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}