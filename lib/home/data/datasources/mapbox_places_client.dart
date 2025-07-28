import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:safy/home/data/dtos/mapbox_place_dto.dart';

class MapboxPlacesClient {
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5';
  static const String _accessToken =
      'pk.eyJ1IjoiZ2Vyc29uMjIiLCJhIjoiY21kbWptYmlzMXE4bzJsb2pyaWgwOHNjayJ9.Fz4sLUzyNfo95LZa0ITtkA';

  /// Busca lugares usando Mapbox Geocoding API
  Future<List<MapboxPlaceDto>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
    int limit = 8,
    String language = 'es',
  }) async {
    try {
      print('🔍 [MapboxPlacesClient] Buscando lugares: $query');

      // Construir parámetros de búsqueda
      final Map<String, String> queryParams = {
        'q': query,
        'access_token': _accessToken,
        'limit': limit.toString(),
        'language': language,
        'types': 'poi,place,neighborhood,address', // Tipos de lugares a buscar
        'autocomplete': 'true',
        'routing': 'true', // Incluir información de rutas
      };

      // Si tenemos coordenadas, hacer búsqueda bias hacia esa ubicación
      if (latitude != null && longitude != null) {
        queryParams['proximity'] = '${longitude},${latitude}';
        print(
          '🔍 [MapboxPlacesClient] Búsqueda con proximidad: $longitude, $latitude',
        );
      }

      // Construir URL
      final uri = Uri.parse(
        '$_baseUrl/mapbox.places/$query.json',
      ).replace(queryParameters: queryParams);

      print('🔍 [MapboxPlacesClient] URL: ${uri.toString()}');

      // Realizar petición HTTP
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Timeout: La API de Mapbox no respondió en tiempo',
              );
            },
          );

      if (response.statusCode != 200) {
        print(
          '❌ [MapboxPlacesClient] Error HTTP ${response.statusCode}: ${response.body}',
        );
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body);

      print('🔍 [MapboxPlacesClient] Respuesta recibida de Mapbox');
      print('🔍 [MapboxPlacesClient] Status: ${response.statusCode}');
      print('🔍 [MapboxPlacesClient] Data type: ${data.runtimeType}');

      if (data['features'] == null) {
        print('❌ [MapboxPlacesClient] Respuesta sin features: $data');
        return [];
      }

      final List<dynamic> features = data['features'];
      print('🔍 [MapboxPlacesClient] Features encontradas: ${features.length}');

      // 🆕 LOG DETALLADO DE LA PRIMERA FEATURE PARA DEBUG
      if (features.isNotEmpty) {
        final firstFeature = features.first as Map<String, dynamic>;
        print('🔍 [MapboxPlacesClient] Primera feature:');
        print('🔍 [MapboxPlacesClient] - ID: ${firstFeature['id']}');
        print(
          '🔍 [MapboxPlacesClient] - Place name: ${firstFeature['place_name']}',
        );
        print('🔍 [MapboxPlacesClient] - Text: ${firstFeature['text']}');

        final geometry = firstFeature['geometry'] as Map<String, dynamic>?;
        if (geometry != null) {
          final coordinates = geometry['coordinates'] as List<dynamic>?;
          print('🔍 [MapboxPlacesClient] - Coordinates: $coordinates');
          if (coordinates != null && coordinates.length >= 2) {
            print(
              '🔍 [MapboxPlacesClient] - Lng type: ${coordinates[0].runtimeType}',
            );
            print(
              '🔍 [MapboxPlacesClient] - Lat type: ${coordinates[1].runtimeType}',
            );
            print('🔍 [MapboxPlacesClient] - Lng value: ${coordinates[0]}');
            print('🔍 [MapboxPlacesClient] - Lat value: ${coordinates[1]}');
          }
        }
      }

      final places =
          features
              .map(
                (feature) =>
                    MapboxPlaceDto.fromJson(feature as Map<String, dynamic>),
              )
              .toList();

      print('✅ [MapboxPlacesClient] Encontrados ${places.length} lugares');
      for (final place in places) {
        print(
          '📍 [MapboxPlacesClient] - ${place.displayName} (${place.latitude}, ${place.longitude})',
        );
      }

      return places;
    } on http.ClientException catch (e) {
      print('❌ [MapboxPlacesClient] Error de conexión: $e');
      throw Exception('Error de conexión: $e');
    } catch (e) {
      print('❌ [MapboxPlacesClient] Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Busca lugares cercanos usando coordenadas
  Future<List<MapboxPlaceDto>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 5000, // 5km por defecto
    String language = 'es',
  }) async {
    try {
      print(
        '🔍 [MapboxPlacesClient] Buscando lugares cercanos a: $latitude, $longitude',
      );

      final Map<String, String> queryParams = {
        'access_token': _accessToken,
        'proximity': '${longitude},${latitude}',
        'limit': '10',
        'language': language,
        'types': 'poi,place',
        'routing': 'true',
      };

      final uri = Uri.parse(
        '$_baseUrl/mapbox.places/restaurante.json',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final List<dynamic> features = data['features'] ?? [];

      return features
          .map(
            (feature) =>
                MapboxPlaceDto.fromJson(feature as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('❌ [MapboxPlacesClient] Error buscando lugares cercanos: $e');
      return [];
    }
  }

  /// Obtiene información detallada de un lugar por su ID
  Future<MapboxPlaceDto?> getPlaceDetails(String placeId) async {
    try {
      print('🔍 [MapboxPlacesClient] Obteniendo detalles del lugar: $placeId');

      final uri = Uri.parse('$_baseUrl/mapbox.places/$placeId.json').replace(
        queryParameters: {'access_token': _accessToken, 'language': 'es'},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return MapboxPlaceDto.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      print('❌ [MapboxPlacesClient] Error obteniendo detalles: $e');
      return null;
    }
  }
}
