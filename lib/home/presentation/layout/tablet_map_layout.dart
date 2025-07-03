// lib/features/home/presentation/widgets/tablet_map_layout.dart
import 'package:flutter/material.dart';
import 'package:safy/home/presentation/layout/mobile_map_layout.dart';
import 'package:safy/home/presentation/widgets/app_drawer.dart';


class TabletMapLayout extends StatelessWidget {
  const TabletMapLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Drawer lateral fijo para tablet
        const SizedBox(
          width: 300,
          child: AppDrawer(),
        ),
        
        // Área principal del mapa
        const Expanded(
          child: MobileMapLayout(),
        ),
      ],
    );
  }
}






// Pantallas placeholder (debes crearlas según tu estructura)
class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Crear Reporte')));
}

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Contactos de Emergencia')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Configuración')));
}

class RouteHistoryScreen extends StatelessWidget {
  const RouteHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Historial de Rutas')));
}