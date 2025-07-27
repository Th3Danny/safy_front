import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/layout/mobile_map_layout.dart';
import 'package:safy/home/presentation/layout/responsive_layout.dart';
import 'package:safy/home/presentation/layout/tablet_map_layout.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/desktop_map_layout.dart';
import 'package:safy/home/presentation/widgets/safe_route_selector.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/value_objects/safety_level.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';
import 'package:safy/home/presentation/widgets/gps_security_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapViewModel _mapViewModel;

  @override
  void initState() {
    super.initState();
    _mapViewModel = context.read<MapViewModel>();
    _mapViewModel.initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapViewModel>(
        builder: (context, mapViewModel, child) {
          if (mapViewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando mapa...'),
                ],
              ),
            );
          }

          return ResponsiveLayout(
            mobile: const MobileMapLayout(),
            tablet: const TabletMapLayout(),
            desktop: const DesktopMapLayout(),
          );
        },
      ),
    );
  }

  // Ejemplo de uso del nuevo sistema de rutas seguras
  void _showSafeRouteExample(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: SafeRouteSelector(
              routes: [
                // Ejemplo de rutas seguras
                RouteEntity(
                  id: 'safe_route_1',
                  name: 'Ruta Segura',
                  waypoints: [],
                  startPoint: Location(latitude: 16.7580, longitude: -93.1300),
                  endPoint: Location(latitude: 16.7520, longitude: -93.1280),
                  distanceKm: 2.5,
                  durationMinutes: 30,
                  safetyLevel: SafetyLevel(
                    percentage: 85,
                    description: 'Muy segura',
                  ),
                  transportMode: TransportMode.walking,
                  isRecommended: true,
                  warnings: [],
                ),
                RouteEntity(
                  id: 'perimeter_route_1',
                  name: 'Ruta Perimetral',
                  waypoints: [],
                  startPoint: Location(latitude: 16.7580, longitude: -93.1300),
                  endPoint: Location(latitude: 16.7520, longitude: -93.1280),
                  distanceKm: 3.2,
                  durationMinutes: 38,
                  safetyLevel: SafetyLevel(
                    percentage: 75,
                    description: 'Segura',
                  ),
                  transportMode: TransportMode.walking,
                  isRecommended: false,
                  warnings: ['Evita 2 zonas de riesgo'],
                ),
                RouteEntity(
                  id: 'detour_route_1',
                  name: 'Ruta con Desvío',
                  waypoints: [],
                  startPoint: Location(latitude: 16.7580, longitude: -93.1300),
                  endPoint: Location(latitude: 16.7520, longitude: -93.1280),
                  distanceKm: 4.1,
                  durationMinutes: 45,
                  safetyLevel: SafetyLevel(
                    percentage: 90,
                    description: 'Muy segura',
                  ),
                  transportMode: TransportMode.walking,
                  isRecommended: false,
                  warnings: ['Desvío amplio para máxima seguridad'],
                ),
              ],
              onRouteSelected: (route) {
                print('Ruta seleccionada: ${route.name}');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🛡️ Iniciando ${route.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onClose: () => Navigator.pop(context),
            ),
          ),
    );
  }
}
