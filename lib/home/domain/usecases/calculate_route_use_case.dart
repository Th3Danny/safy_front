import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';

class CalculateRouteUseCase {
  final RouteRepository _repository;

  CalculateRouteUseCase(this._repository);

  Future<RouteEntity> execute(
    LatLng start,
    LatLng end, {
    String transportMode = 'foot-walking',
    bool prioritizeSafety = true,
  }) async {
    // Validar que los puntos sean diferentes
    if (start.latitude == end.latitude && start.longitude == end.longitude) {
      throw Exception('Los puntos de inicio y destino no pueden ser iguales');
    }

    // Convertir LatLng a Location
    final startLocation = Location(
      latitude: start.latitude,
      longitude: start.longitude,
    );
    
    final endLocation = Location(
      latitude: end.latitude,
      longitude: end.longitude,
    );

    // Convertir String a TransportMode
    final mode = _convertToTransportMode(transportMode);

    // Usar el método getOptimalRoute de tu repositorio
    return await _repository.getOptimalRoute(
      startPoint: startLocation,
      endPoint: endLocation,
      transportMode: mode,
      prioritizeSafety: prioritizeSafety,
    );
  }

  Future<List<RouteEntity>> executeMultiple(
    LatLng start,
    LatLng end, {
    String transportMode = 'foot-walking',
  }) async {
    // Validar que los puntos sean diferentes
    if (start.latitude == end.latitude && start.longitude == end.longitude) {
      throw Exception('Los puntos de inicio y destino no pueden ser iguales');
    }

    // Convertir LatLng a Location
    final startLocation = Location(
      latitude: start.latitude,
      longitude: start.longitude,
    );
    
    final endLocation = Location(
      latitude: end.latitude,
      longitude: end.longitude,
    );

    // Convertir String a TransportMode
    final mode = _convertToTransportMode(transportMode);

    // Usar el método calculateRoutes para obtener múltiples opciones
    return await _repository.calculateRoutes(
      startPoint: startLocation,
      endPoint: endLocation,
      transportMode: mode,
    );
  }

  TransportMode _convertToTransportMode(String mode) {
    switch (mode) {
      case 'foot-walking':
      case 'walk':
        return TransportMode.walking;
      case 'driving-car':
      case 'car':
        return TransportMode.driving;
      case 'bus':
        return TransportMode.publicTransport;
      default:
        return TransportMode.walking;
    }
  }
}
