import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/data/datasources/mapbox_directions_client.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class RouteService {
  final MapboxDirectionsClient _directionsClient = MapboxDirectionsClient();

  /// Calcula rutas con diferentes estrategias
  Future<Map<String, List<LatLng>>> calculateRoutes(
    LatLng startPoint,
    LatLng endPoint,
    MapViewModel mapViewModel,
  ) async {
    final routes = <String, List<LatLng>>{};

    try {
      // Ruta segura (walking)
      final safeRouteCoords = await _directionsClient.getRoute(
        start: startPoint,
        end: endPoint,
        profile: 'walking',
      );

      if (safeRouteCoords.isNotEmpty) {
        routes['safe'] = _convertToLatLngList(safeRouteCoords);
      }

      // Ruta rápida (driving)
      final fastRouteCoords = await _directionsClient.getRoute(
        start: startPoint,
        end: endPoint,
        profile: 'driving',
      );

      if (fastRouteCoords.isNotEmpty) {
        routes['fast'] = _convertToLatLngList(fastRouteCoords);
      }

      // Ruta extra segura (cycling - más lenta pero más segura)
      final extraSafeRouteCoords = await _directionsClient.getRoute(
        start: startPoint,
        end: endPoint,
        profile: 'cycling',
      );

      if (extraSafeRouteCoords.isNotEmpty) {
        routes['extraSafe'] = _convertToLatLngList(extraSafeRouteCoords);
      }

      // Si no se pudo calcular la ruta extra segura, usar walking como fallback
      if (!routes.containsKey('extraSafe') && routes.containsKey('safe')) {
        routes['extraSafe'] = List.from(routes['safe']!);
      }
    } catch (e) {
      // Silent error handling for production
    }

    return routes;
  }

  /// Convierte coordenadas de Mapbox a lista de LatLng
  List<LatLng> _convertToLatLngList(List<List<double>> coordinates) {
    return coordinates.map((coord) {
      // Ahora MapboxDirectionsClient devuelve [latitude, longitude]
      // coord[0] = latitude, coord[1] = longitude
      final latitude = coord[0];
      final longitude = coord[1];

      // Validar que las coordenadas estén en rangos válidos
      if (latitude < -90 || latitude > 90) {
        return LatLng(0, 0); // Coordenada por defecto
      }
      if (longitude < -180 || longitude > 180) {
        return LatLng(0, 0); // Coordenada por defecto
      }

      return LatLng(latitude, longitude);
    }).toList();
  }
}
