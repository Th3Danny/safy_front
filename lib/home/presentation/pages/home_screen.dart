import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/layout/mobile_map_layout.dart';
import 'package:safy/home/presentation/layout/responsive_layout.dart';
import 'package:safy/home/presentation/layout/tablet_map_layout.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/desktop_map_layout.dart';
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
}
