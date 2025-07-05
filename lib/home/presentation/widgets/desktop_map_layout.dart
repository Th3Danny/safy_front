
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/layout/mobile_map_layout.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/widgets/desktop_control_panel.dart';


class DesktopMapLayout extends StatelessWidget {
  const DesktopMapLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Navegación lateral izquierda
       
        
        // Área principal del mapa
        const Expanded(
          child: MobileMapLayout(),
        ),
        
        // Panel de control derecho
        Consumer<MapViewModel>(
          builder: (context, mapViewModel, child) {
            return SizedBox(
              width: 300,
              child: DesktopControlPanel(mapViewModel: mapViewModel),
            );
          },
        ),
      ],
    );
  }
}
