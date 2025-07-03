import 'package:dio/dio.dart';
import 'package:safy/home/data/dtos/danger_zone_dto.dart';
import 'package:safy/home/data/dtos/location_dto.dart';


class DangerZoneApiClient {
  final Dio _dio;
  static const String _baseUrl = '/api/v1/danger-zones';

  DangerZoneApiClient(this._dio);

  Future<List<DangerZoneDto>> getDangerZonesInArea({
    required LocationDto center,
    required double radiusKm,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/area',
        queryParameters: {
          'latitude': center.latitude,
          'longitude': center.longitude,
          'radius_km': radiusKm,
        },
      );

      final zonesData = response.data['danger_zones'] as List;
      return zonesData.map((json) => DangerZoneDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<DangerZoneDto>> getAllActiveDangerZones() async {
    try {
      final response = await _dio.get('$_baseUrl/active');
      
      final zonesData = response.data['danger_zones'] as List;
      return zonesData.map((json) => DangerZoneDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<bool> isLocationSafe(LocationDto location) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/check-safety',
        data: location.toJson(),
      );

      return response.data['is_safe'] as bool;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<DangerZoneDto?> getDangerZoneAtLocation(LocationDto location) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/at-location',
        data: location.toJson(),
      );

      final zoneData = response.data['danger_zone'];
      return zoneData != null ? DangerZoneDto.fromJson(zoneData) : null;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> updateDangerZoneFromReport({
    required LocationDto location,
    required String incidentType,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/update-from-report',
        data: {
          'location': location.toJson(),
          'incident_type': incidentType,
        },
      );
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
