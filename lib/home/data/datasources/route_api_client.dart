import 'package:dio/dio.dart';
import 'package:safy/home/data/dtos/location_dto.dart';
import 'package:safy/home/data/dtos/route_dto.dart';


class RouteApiClient {
  final Dio _dio;
  static const String _baseUrl = '/api/v1/routes';

  RouteApiClient(this._dio);

  Future<List<RouteDto>> calculateRoutes({
    required LocationDto startPoint,
    required LocationDto endPoint,
    required String transportMode,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/calculate',
        data: {
          'start_point': startPoint.toJson(),
          'end_point': endPoint.toJson(),
          'transport_mode': transportMode,
        },
      );

      final routesData = response.data['routes'] as List;
      return routesData.map((json) => RouteDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<RouteDto> getOptimalRoute({
    required LocationDto startPoint,
    required LocationDto endPoint,
    required String transportMode,
    bool prioritizeSafety = true,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/optimal',
        data: {
          'start_point': startPoint.toJson(),
          'end_point': endPoint.toJson(),
          'transport_mode': transportMode,
          'prioritize_safety': prioritizeSafety,
        },
      );

      return RouteDto.fromJson(response.data['route']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> saveRouteHistory(RouteDto route) async {
    try {
      await _dio.post(
        '$_baseUrl/history',
        data: route.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<RouteDto>> getRouteHistory({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/history',
        queryParameters: {'limit': limit},
      );

      final routesData = response.data['routes'] as List;
      return routesData.map((json) => RouteDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Tiempo de conexión agotado');
      case DioExceptionType.connectionError:
        return Exception('Error de conexión');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return Exception('Error $statusCode: $message');
      default:
        return Exception('Error desconocido: ${e.message}');
    }
  }
}