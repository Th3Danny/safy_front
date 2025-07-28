import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class MapboxDirectionsClient {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5';
  static const String _accessToken =
      'pk.eyJ1IjoiZ2Vyc29uMjIiLCJhIjoiY21kbWptYmlzMXE4bzJsb2pyaWgwOHNjayJ9.Fz4sLUzyNfo95LZa0ITtkA';

  /// Obtiene rutas usando Mapbox Directions API
  Future<List<List<double>>> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'walking',
    List<LatLng>? waypoints,
  }) async {
    try {
      print('🗺️ Mapbox: Calculando ruta...');

      // Construir coordenadas para la URL
      String coordinates =
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointCoords = waypoints
            .map((wp) => '${wp.longitude},${wp.latitude}')
            .join(';');
        coordinates =
            '${start.longitude},${start.latitude};$waypointCoords;${end.longitude},${end.latitude}';
      }

      // Construir URL con parámetros
      final uri = Uri.parse('$_baseUrl/mapbox/$profile/$coordinates').replace(
        queryParameters: {
          'access_token': _accessToken,
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'true',
          'continue_straight': 'true',
        },
      );

      // Realizar petición HTTP
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Timeout: La API de Mapbox no respondió en tiempo',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body);

      if (data['code'] != 'Ok') {
        throw Exception(
          'Error de Mapbox: ${data['message'] ?? 'Error desconocido'}',
        );
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No se encontraron rutas');
      }

      final route = routes[0];
      final geometry = route['geometry'];

      if (geometry['type'] != 'LineString') {
        throw Exception('Geometría no válida');
      }

      final routeCoordinates = geometry['coordinates'] as List;

      // Convertir coordenadas: [lon, lat] -> [lat, lon] para compatibilidad
      final routePoints =
          routeCoordinates.map<List<double>>((coord) {
            return [coord[1].toDouble(), coord[0].toDouble()]; // [lat, lon]
          }).toList();

      print('🗺️ Mapbox: Ruta calculada con ${routePoints.length} puntos');

      return routePoints;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene múltiples rutas alternativas
  Future<List<List<List<double>>>> getAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    String profile = 'walking',
    int maxAlternatives = 3,
  }) async {
    try {
      final coordinates =
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final uri = Uri.parse('$_baseUrl/mapbox/$profile/$coordinates').replace(
        queryParameters: {
          'access_token': _accessToken,
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'true',
          'annotations': 'true',
          'alternatives': 'true',
          'continue_straight': 'true',
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception(
                'Timeout: La API de Mapbox no respondió en tiempo',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body);

      if (data['code'] != 'Ok') {
        throw Exception(
          'Error de Mapbox: ${data['message'] ?? 'Error desconocido'}',
        );
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No se encontraron rutas alternativas');
      }

      final allRoutes = <List<List<double>>>[];

      for (final route in routes) {
        final geometry = route['geometry'];

        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;

          final routePoints =
              coordinates.map<List<double>>((coord) {
                return [coord[1].toDouble(), coord[0].toDouble()]; // [lat, lon]
              }).toList();

          allRoutes.add(routePoints);
        }
      }

      return allRoutes;
    } catch (e) {
      // Fallback: devolver ruta directa
      return [
        [
          [start.latitude, start.longitude],
          [end.latitude, end.longitude],
        ],
      ];
    }
  }

  /// Verifica si una ruta es válida
  bool isRouteValid(List<List<double>> route) {
    if (route.length < 2) return false;

    for (final coord in route) {
      if (coord.length != 2) return false;
      if (coord[0].isNaN || coord[1].isNaN) return false;
      if (coord[0] < -90 || coord[0] > 90) return false; // latitud
      if (coord[1] < -180 || coord[1] > 180) return false; // longitud
    }

    return true;
  }
}
