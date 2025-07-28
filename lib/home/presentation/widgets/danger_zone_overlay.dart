import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/home/data/repositories/places_repository_impl.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/entities/location.dart';

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

  void _findSafeRoute(MapViewModel mapViewModel) async {
    print('[DangerZoneOverlay] 🛡️ Buscando rutas seguras automáticamente...');

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Buscando lugares seguros cercanos...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 5),
      ),
    );

    // 🎯 Establecer automáticamente la posición actual como punto de inicio
    mapViewModel.setCurrentLocationAsStart();

    try {
      // 🎯 Generar destinos seguros cercanos
      final safeDestinations = await _generateSafeDestinations(mapViewModel);

      if (safeDestinations.isNotEmpty) {
        // Mostrar selector de destinos seguros
        _showSafeDestinationSelector(context, mapViewModel, safeDestinations);
      } else {
        // 🚨 NO HAY LUGARES DE EMERGENCIA CERCANOS
        _showNoEmergencyPlacesDialog(context, mapViewModel);
      }
    } catch (e) {
      print('[DangerZoneOverlay] ❌ Error buscando destinos seguros: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error buscando lugares seguros. Intenta de nuevo.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 🎯 NUEVO: Generar destinos seguros cercanos SOLO con lugares reales
  Future<List<Map<String, dynamic>>> _generateSafeDestinations(
    MapViewModel mapViewModel,
  ) async {
    final currentLocation = mapViewModel.currentLocation;
    final destinations = <Map<String, dynamic>>[];

    try {
      print('[DangerZoneOverlay] 🔍 Buscando lugares reales cercanos...');

      // Obtener el repositorio de lugares
      final placesRepository = GetIt.instance<PlacesRepositoryImpl>();

      // 🚨 SOLO lugares de emergencia y seguridad (sin datos ficticios)
      final emergencyCategories = [
        'hospital',
        'police',
        'pharmacy',
        'fire_station',
      ];

      // Buscar lugares de emergencia
      for (final category in emergencyCategories) {
        try {
          print('[DangerZoneOverlay] 🚨 Buscando $category...');

          final places = await placesRepository.searchPlaces(
            category,
            nearLocation: Location(
              latitude: currentLocation.latitude,
              longitude: currentLocation.longitude,
            ),
            limit: 5,
          );

          for (final place in places) {
            final distance = _calculateDistance(
              currentLocation,
              place.location.toLatLng(),
            );

            // Incluir TODOS los lugares de emergencia (hasta 10km)
            if (distance <= 10000) {
              destinations.add({
                'location': place.location.toLatLng(),
                'name': place.displayName,
                'description': _getEmergencyPlaceDescription(place),
                'distance': distance,
                'timeToWalk': _estimateWalkingTime(distance),
                'category': category,
                'isEmergency': true,
              });
            }
          }
        } catch (e) {
          print('[DangerZoneOverlay] ⚠️ Error buscando $category: $e');
        }
      }

      // Ordenar por distancia
      destinations.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      // Eliminar duplicados (lugares muy cercanos)
      final uniqueDestinations = <Map<String, dynamic>>[];
      for (final destination in destinations) {
        bool isDuplicate = false;
        for (final existing in uniqueDestinations) {
          final distance = _calculateDistance(
            destination['location'] as LatLng,
            existing['location'] as LatLng,
          );
          if (distance < 200) {
            // Aumentar a 200m para evitar duplicados
            isDuplicate = true;
            break;
          }
        }
        if (!isDuplicate) {
          uniqueDestinations.add(destination);
        }
      }

      print(
        '[DangerZoneOverlay] ✅ Encontrados ${uniqueDestinations.length} lugares de emergencia reales',
      );
      return uniqueDestinations.take(5).toList(); // Limitar a 5 opciones
    } catch (e) {
      print('[DangerZoneOverlay] ❌ Error buscando lugares reales: $e');
      return []; // Retornar lista vacía en lugar de fallback ficticio
    }
  }

  // 🎯 NUEVO: Generar descripción del lugar de emergencia
  String _getEmergencyPlaceDescription(Place place) {
    final category = place.category?.toLowerCase() ?? '';

    switch (category) {
      case 'hospital':
        return '🚨 HOSPITAL - Zona médica de emergencia';
      case 'police':
        return '🚔 POLICÍA - Estación de seguridad';
      case 'fire_station':
        return '🚒 BOMBEROS - Estación de emergencia';
      case 'pharmacy':
        return '💊 FARMACIA - Servicios médicos';
      default:
        return '📍 Lugar de emergencia';
    }
  }

  // 🎯 NUEVO: Generar descripción del lugar (mantener para compatibilidad)
  String _getPlaceDescription(Place place) {
    final category = place.category?.toLowerCase() ?? '';

    switch (category) {
      case 'hospital':
        return 'Zona médica bien iluminada y segura';
      case 'police':
        return 'Cerca de autoridades y seguridad';
      case 'bank':
        return 'Zona bancaria con cámaras de seguridad';
      case 'school':
      case 'university':
        return 'Campus educativo con vigilancia';
      case 'shopping_centre':
      case 'supermarket':
        return 'Zona comercial con mucha gente';
      case 'gas_station':
        return 'Estación de servicio con cámaras';
      case 'park':
        return 'Área verde pública y segura';
      case 'library':
        return 'Biblioteca pública tranquila';
      case 'post_office':
        return 'Oficina postal con seguridad';
      case 'fire_station':
        return 'Estación de bomberos con personal';
      case 'pharmacy':
        return 'Farmacia con personal médico';
      case 'restaurant':
      case 'cafe':
        return 'Establecimiento con gente y seguridad';
      default:
        return 'Lugar público seguro';
    }
  }

  // 🎯 NUEVO: Mostrar diálogo cuando no hay lugares de emergencia
  void _showNoEmergencyPlacesDialog(
    BuildContext context,
    MapViewModel mapViewModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🚨 SIN LUGARES DE EMERGENCIA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se encontraron hospitales, farmacias, estaciones de policía o bomberos en un radio de 10km.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  'Recomendaciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Mantén la calma y busca ayuda'),
                Text('• Llama al 911 o servicios de emergencia'),
                Text('• Busca un lugar público con gente'),
                Text('• Reporta el incidente para alertar a otros'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _reportIncident(context);
                },
                child: const Text(
                  'REPORTAR INCIDENTE',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                child: const Text('ENTENDIDO'),
              ),
            ],
          ),
    );
  }

  // 🎯 NUEVO: Fallback con lugares predefinidos (ya no se usa)
  List<Map<String, dynamic>> _generateFallbackDestinations(
    MapViewModel mapViewModel,
  ) {
    // Este método ya no se usa, pero lo mantengo por compatibilidad
    return [];
  }

  // 🎯 NUEVO: Estimar tiempo de caminata
  String _estimateWalkingTime(double distanceInMeters) {
    const walkingSpeed = 1.4; // metros por segundo (5 km/h)
    final timeInSeconds = distanceInMeters / walkingSpeed;
    final timeInMinutes = (timeInSeconds / 60).round();

    if (timeInMinutes < 1) {
      return 'Menos de 1 min';
    } else if (timeInMinutes < 60) {
      return '$timeInMinutes min';
    } else {
      final hours = (timeInMinutes / 60).floor();
      final minutes = timeInMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  // 🎯 NUEVO: Obtener icono según el tipo de destino
  IconData _getDestinationIcon(String destinationName) {
    switch (destinationName) {
      case 'Zona Residencial':
        return Icons.home;
      case 'Centro Comercial':
        return Icons.shopping_cart;
      case 'Parque Público':
        return Icons.park;
      case 'Estación de Policía':
        return Icons.local_police;
      case 'Hospital':
        return Icons.local_hospital;
      case 'Universidad':
        return Icons.school;
      case 'Gasolinera':
        return Icons.local_gas_station;
      case 'Banco':
        return Icons.account_balance;
      default:
        return Icons.location_on;
    }
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
                  final description = destination['description'] as String;
                  final distance = destination['distance'] as double;
                  final timeToWalk = destination['timeToWalk'] as String;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: InkWell(
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icono según el tipo de destino
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getDestinationIcon(name),
                                color: Colors.green,
                                size: 20,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Información del destino
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(distance / 1000).toStringAsFixed(1)} km • $timeToWalk',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Botón de acción
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'IR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
