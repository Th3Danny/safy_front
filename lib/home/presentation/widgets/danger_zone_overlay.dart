
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class DangerZoneOverlay extends StatefulWidget {
  const DangerZoneOverlay({super.key});

  @override
  State<DangerZoneOverlay> createState() => _DangerZoneOverlayState();
}

class _DangerZoneOverlayState extends State<DangerZoneOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade600,
                      Colors.red.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono de advertencia
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Título
                    const Text(
                      '⚠️ ZONA PELIGROSA DETECTADA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Descripción
                    const Text(
                      'Estás cerca de una zona con reportes recientes de incidentes. Mantente alerta y considera usar una ruta alternativa.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _findSafeRoute(mapViewModel),
                            icon: const Icon(Icons.route, color: Colors.white),
                            label: const Text(
                              'Ruta Segura',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _reportIncident(context),
                            icon: const Icon(Icons.report_problem),
                            label: const Text('Reportar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Botón para cerrar
                    TextButton.icon(
                      onPressed: () => _dismissWarning(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      label: const Text(
                        'Entendido, continuar',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _findSafeRoute(MapViewModel mapViewModel) {
    // Buscar ruta segura automáticamente
    if (mapViewModel.startPoint == null) {
      mapViewModel.setStartPoint(mapViewModel.currentLocation);
    }
    
    // Aquí podrías implementar lógica para sugerir un destino seguro
    // o recalcular la ruta actual evitando zonas peligrosas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛡️ Calculando ruta más segura...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reportIncident(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/create-report',
      arguments: {
        'location': context.read<MapViewModel>().currentLocation,
        'preselected_type': 'danger_zone',
      },
    );
  }

  void _dismissWarning() {
    // Aquí podrías guardar que el usuario ya vio esta advertencia
    // para no mostrarla nuevamente en la misma sesión
  }
}

