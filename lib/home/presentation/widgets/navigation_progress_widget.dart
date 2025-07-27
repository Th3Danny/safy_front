import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class NavigationProgressWidget extends StatelessWidget {
  const NavigationProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        // Solo mostrar si está navegando
        if (!mapViewModel.isNavigating) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 100,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                // Header con icono y título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Navegando',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => mapViewModel.stopNavigation(),
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.grey[600],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Barra de progreso
                LinearProgressIndicator(
                  value: mapViewModel.navigationProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),

                const SizedBox(height: 8),

                // Información de progreso
                Text(
                  mapViewModel.progressInfo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Botón para detener navegación
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => mapViewModel.stopNavigation(),
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Detener Navegación'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
