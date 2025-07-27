import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:latlong2/latlong.dart';

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

  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
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
                    colors: [Colors.red.shade600, Colors.red.shade700],
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
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
    print('[DangerZoneOverlay] 🛡️ Buscando rutas seguras automáticamente...');

    // 🎯 Establecer automáticamente la posición actual como punto de inicio
    mapViewModel.setCurrentLocationAsStart();

    // 🎯 Generar destinos seguros cercanos
    final safeDestinations = _generateSafeDestinations(mapViewModel);

    if (safeDestinations.isNotEmpty) {
      // Mostrar selector de destinos seguros
      _showSafeDestinationSelector(context, mapViewModel, safeDestinations);
    } else {
      // Si no hay destinos seguros cercanos, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ No se encontraron destinos seguros cercanos. Considera reportar el incidente.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 🎯 NUEVO: Generar destinos seguros cercanos
  List<Map<String, dynamic>> _generateSafeDestinations(
    MapViewModel mapViewModel,
  ) {
    final currentLocation = mapViewModel.currentLocation;
    final destinations = <Map<String, dynamic>>[];

    // Generar puntos seguros en diferentes direcciones (radio de 1-3 km)
    final directions = [
      {'lat': 0.005, 'lng': 0.005, 'name': 'Noreste'},
      {'lat': 0.005, 'lng': -0.005, 'name': 'Noroeste'},
      {'lat': -0.005, 'lng': 0.005, 'name': 'Sureste'},
      {'lat': -0.005, 'lng': -0.005, 'name': 'Suroeste'},
      {'lat': 0.01, 'lng': 0.0, 'name': 'Norte'},
      {'lat': -0.01, 'lng': 0.0, 'name': 'Sur'},
      {'lat': 0.0, 'lng': 0.01, 'name': 'Este'},
      {'lat': 0.0, 'lng': -0.01, 'name': 'Oeste'},
    ];

    for (final direction in directions) {
      final safePoint = LatLng(
        currentLocation.latitude + (direction['lat'] as double),
        currentLocation.longitude + (direction['lng'] as double),
      );

      // Verificar que el punto esté fuera de zonas peligrosas
      if (!mapViewModel.isLocationDangerous(safePoint)) {
        destinations.add({
          'location': safePoint,
          'name': 'Zona Segura - ${direction['name']}',
          'distance': _calculateDistance(currentLocation, safePoint),
        });
      }
    }

    // Ordenar por distancia
    destinations.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return destinations.take(5).toList(); // Limitar a 5 opciones
  }

  // 🎯 NUEVO: Calcular distancia entre dos puntos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros
    final double lat1Rad = point1.latitude * (3.14159 / 180);
    final double lat2Rad = point2.latitude * (3.14159 / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (3.14159 / 180);

    final double a =
        (deltaLatRad / 2).abs() * (deltaLatRad / 2).abs() +
        lat1Rad.abs() *
            lat2Rad.abs() *
            (deltaLngRad / 2).abs() *
            (deltaLngRad / 2).abs();
    final double c = 2 * (a.abs().clamp(0, 1));

    return earthRadius * c;
  }

  // 🎯 NUEVO: Mostrar selector de destinos seguros
  void _showSafeDestinationSelector(
    BuildContext context,
    MapViewModel mapViewModel,
    List<Map<String, dynamic>> destinations,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.safety_divider,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Destinos Seguros Cercanos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Lista de destinos
                ...destinations.map((destination) {
                  final location = destination['location'] as LatLng;
                  final name = destination['name'] as String;
                  final distance = destination['distance'] as double;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        '${(distance / 1000).toStringAsFixed(1)} km de distancia',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);

                        // Establecer el destino seguro y calcular ruta
                        mapViewModel.setEndPoint(location);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.route, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Calculando ruta segura a: $name',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Botón para reportar incidente
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportIncident(context);
                    },
                    icon: const Icon(Icons.report_problem),
                    label: const Text('Reportar Incidente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _reportIncident(BuildContext context) {
    // Navegar a la pantalla de reporte con ubicación actual
    final mapViewModel = context.read<MapViewModel>();

    // ✅ CAMBIO: Usar context.go en lugar de Navigator.pushNamed
    context.go(AppRoutesConstant.createReport);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Abriendo formulario de reporte...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _dismissWarning() {
    setState(() {
      _isVisible = false;
    });

    void dismissWarning() {
      // Aquí podrías guardar que el usuario ya vio esta advertencia
      // para no mostrarla nuevamente en la misma sesión
    }
  }
}
