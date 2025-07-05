import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/data/dtos/openroute_service_dto.dart';

class OpenRouteServiceApiClient {
  final Dio _dio;
  static const String _baseUrl = 'https://api.openrouteservice.org/v2';
  
  // Nota: Necesitarás registrarte en OpenRouteService para obtener una API key
  static const String _apiKey = 'TU_API_KEY_AQUI'; // Reemplaza con tu API key

  OpenRouteServiceApiClient(this._dio);

  Future<OpenRouteServiceDto> calculateRoute(
    LatLng start,
    LatLng end, {
    String profile = 'foot-walking', // foot-walking, driving-car, cycling-regular
  }) async {
    try {
      final body = {
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ],
        'format': 'json',
        'instructions': true,
        'language': 'es',
      };

      final response = await _dio.post(
        '$_baseUrl/directions/$profile/json',
        data: body,
        options: Options(
          headers: {
            'Authorization': _apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return OpenRouteServiceDto.fromJson(response.data);
      } else {
        throw Exception('Error calculando ruta: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('API key inválida o límite excedido');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else {
        throw Exception('Error de red: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}