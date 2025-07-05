
import 'package:dio/dio.dart';
import 'package:safy/home/data/dtos/nominatim_place_dto.dart';

class NominatimApiClient {
  final Dio _dio;
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  NominatimApiClient(this._dio);

  Future<List<NominatimPlaceDto>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
    int limit = 5,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'accept-language': 'es',
      };

      // Si tenemos coordenadas, hacer búsqueda bias hacia esa ubicación
      if (latitude != null && longitude != null) {
        queryParams['viewbox'] = 
            '${longitude - 0.1},${latitude - 0.1},${longitude + 0.1},${latitude + 0.1}';
        queryParams['bounded'] = '1';
      }

      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'User-Agent': 'SafyApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((place) => NominatimPlaceDto.fromJson(place as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tiempo de respuesta agotado');
      } else {
        throw Exception('Error de red: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}