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
    print('🛣️ [RouteService] Calculando rutas...');
    print('🛣️ [RouteService] Desde: $startPoint');
    print('🛣️ [RouteService] Hasta: $endPoint');

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
        print(
          '🛣️ [RouteService] Ruta segura calculada: ${routes['safe']!.length} puntos',
        );
      }

      // Ruta rápida (driving)
      final fastRouteCoords = await _directionsClient.getRoute(
        start: startPoint,
        end: endPoint,
        profile: 'driving',
      );

      if (fastRouteCoords.isNotEmpty) {
        routes['fast'] = _convertToLatLngList(fastRouteCoords);
        print(
          '🛣️ [RouteService] Ruta rápida calculada: ${routes['fast']!.length} puntos',
        );
      }

      // Ruta extra segura (cycling - más lenta pero más segura)
      final extraSafeRouteCoords = await _directionsClient.getRoute(
        start: startPoint,
        end: endPoint,
        profile: 'cycling',
      );

      if (extraSafeRouteCoords.isNotEmpty) {
        routes['extraSafe'] = _convertToLatLngList(extraSafeRouteCoords);
        print(
          '🛣️ [RouteService] Ruta extra segura calculada: ${routes['extraSafe']!.length} puntos',
        );
      }

      // Si no se pudo calcular la ruta extra segura, usar walking como fallback
      if (!routes.containsKey('extraSafe') && routes.containsKey('safe')) {
        routes['extraSafe'] = List.from(routes['safe']!);
        print(
          '🛣️ [RouteService] Usando ruta segura como fallback para extra segura',
        );
      }
    } catch (e) {
      print('❌ [RouteService] Error calculando rutas: $e');
    }

    return routes;
  }

  /// Convierte coordenadas de Mapbox a lista de LatLng
  List<LatLng> _convertToLatLngList(List<List<double>> coordinates) {
    print('🔄 [RouteService] Convirtiendo ${coordinates.length} coordenadas');

    return coordinates.map((coord) {
      // Ahora MapboxDirectionsClient devuelve [latitude, longitude]
      // coord[0] = latitude, coord[1] = longitude
      final latitude = coord[0];
      final longitude = coord[1];

      print('🔄 [RouteService] Coordenada original: [$latitude, $longitude]');

      // Validar que las coordenadas estén en rangos válidos
      if (latitude < -90 || latitude > 90) {
        print('❌ [RouteService] Latitud inválida: $latitude');
        return LatLng(0, 0); // Coordenada por defecto
      }
      if (longitude < -180 || longitude > 180) {
        print('❌ [RouteService] Longitud inválida: $longitude');
        return LatLng(0, 0); // Coordenada por defecto
      }

      print(
        '✅ [RouteService] Coordenada válida: Lat($latitude), Lng($longitude)',
      );
      return LatLng(latitude, longitude);
    }).toList();
  }
}
