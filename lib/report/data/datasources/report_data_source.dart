import 'package:dio/dio.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/report/data/dtos/cluster_response_dto.dart';
import 'package:safy/report/data/dtos/report_request_dto.dart';
import 'package:safy/report/data/dtos/report_response_dto.dart';
import 'package:safy/report/domain/exceptions/report_exceptions.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';

class ReportApiClient {
  final Dio _dio;

  ReportApiClient(this._dio);

  Future<List<ClusterResponseDto>> getClusters({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print(
        '[ClusterApiClient] 📍 Obteniendo clusters cerca de: $latitude, $longitude',
      );
      print(
        '[ClusterApiClient] 🌐 URL: ${ApiConstants.baseUrl}${ApiConstants.nearbyReports}',
      );

      final response = await _dio.get(
        ApiConstants.nearbyReports,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': 10.0,
          'city': 'tuxtla',
          'minSeverity': 0,
          'maxSeverity': 10,
          'maxHoursAgo': 168,
        },
      );

      print('[ClusterApiClient] ✅ Respuesta recibida: ${response.statusCode}');
      print('[ClusterApiClient] 📋 Tipo de data: ${response.data.runtimeType}');

      return _parseClustersResponse(response.data);
    } on DioException catch (e) {
      print('[ClusterApiClient] ❌ Error DioException: ${e.message}');
      print('[ClusterApiClient] ❌ Status code: ${e.response?.statusCode}');
      print('[ClusterApiClient] ❌ Response data: ${e.response?.data}');
      throw Exception('Error obteniendo clusters: ${e.message}');
    } catch (e) {
      print('[ClusterApiClient] ❌ Error inesperado: $e');
      throw Exception('Error inesperado obteniendo clusters: $e');
    }
  }

  List<ClusterResponseDto> _parseClustersResponse(dynamic data) {
    print('[ClusterApiClient] 🔍 Analizando respuesta de clusters...');

    if (data == null) {
      print('[ClusterApiClient] ⚠️ Respuesta nula');
      return <ClusterResponseDto>[];
    }

    if (data is Map<String, dynamic>) {
      print('[ClusterApiClient] 🗂️ Respuesta es un objeto');
      print('[ClusterApiClient] 🔑 Keys disponibles: ${data.keys.toList()}');

      // Buscar estructura específica de smart-nearby
      if (data.containsKey('data')) {
        final dataSection = data['data'] as Map<String, dynamic>?;
        if (dataSection != null && dataSection.containsKey('clusters')) {
          final clusters = dataSection['clusters'] as List?;
          if (clusters != null) {
            print(
              '[ClusterApiClient] 🎯 Encontrados ${clusters.length} clusters en data.clusters',
            );

            try {
              final clusterList =
                  clusters
                      .map(
                        (clusterJson) => ClusterResponseDto.fromJson(
                          clusterJson as Map<String, dynamic>,
                        ),
                      )
                      .toList();

              print('[ClusterApiClient] ✅ Clusters parseados correctamente');
              for (final cluster in clusterList) {
                print(
                  '[ClusterApiClient] 📍 Cluster: ${cluster.dominantIncidentName} (${cluster.reportCount} reportes) - ${cluster.severity}',
                );
              }

              return clusterList;
            } catch (e) {
              print('[ClusterApiClient] ❌ Error parseando clusters: $e');
              return <ClusterResponseDto>[];
            }
          }
        }
      }

      print(
        '[ClusterApiClient] ⚠️ No se encontraron clusters en la estructura esperada',
      );
      return <ClusterResponseDto>[];
    }

    print(
      '[ClusterApiClient] ⚠️ Tipo de respuesta no soportado: ${data.runtimeType}',
    );
    return <ClusterResponseDto>[];
  }

  // Future<List<ReportResponseDto>> getReports({
  //   required String userId,
  //   required double latitude,
  //   required double longitude,
  //   int? page,
  //   int? pageSize,
  // }) async {
  //   try {
  //     print(
  //       '[ReportApiClient] 📍 Buscando reportes cercanos en: $latitude, $longitude',
  //     );

  //     final response = await _dio.get(
  //       ApiConstants.nearbyReports,
  //       queryParameters: {
  //         'latitude': latitude,
  //         'longitude': longitude,
  //         'radiusKm': 10.0,
  //         'city': 'tuxtla',
  //         'minSeverity': 0,
  //         'maxSeverity': 10,
  //         'maxHoursAgo': 168,
  //         'page': page ?? 0,
  //         'pageSize': pageSize ?? 50,
  //       },
  //     );

  //     print('[ReportApiClient] ✅ Respuesta recibida: ${response.statusCode}');

  //     // Si la respuesta es una lista directa de reportes
  //     if (response.data is List) {
  //       return (response.data as List)
  //           .map((json) => ReportResponseDto.fromJson(json))
  //           .toList();
  //     }

  //     // Si la respuesta viene en formato paginado
  //     final pageResponse = ReportsPageResponseDto.fromJson(response.data);
  //     return pageResponse.reports;
  //   } on DioException catch (e) {
  //     print('[ReportApiClient] ❌ Error en solicitud: ${e.message}');
  //     _handleDioError(e);
  //     rethrow;
  //   } catch (e) {
  //     print('[ReportApiClient] ❌ Error inesperado: $e');
  //     throw ReportExceptions('Error al obtener reportes cercanos: $e');
  //   }
  // }

  Future<ReportResponseDto> getReportById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.reports}/$id');
      return ReportResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<List<ReportResponseDto>> getMyReports({
    int? page,
    int? pageSize,
  }) async {
    try {
      print('[ReportApiClient] 📋 Obteniendo MIS reportes');

      final response = await _dio.get(
        '/reports/my-reports', // ✅ Usar la ruta correcta
        queryParameters: {'page': page ?? 0, 'size': pageSize ?? 10},
      );

      print(
        '[ReportApiClient] ✅ Respuesta MIS reportes: ${response.statusCode}',
      );
      print('[ReportApiClient] 📋 Respuesta completa: ${response.data}');

      // ✅ Parsear según la estructura de tu respuesta
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['reports'] != null) {
          final reports = data['reports'] as List;
          print('[ReportApiClient] ✅ Encontrados ${reports.length} reportes');

          return reports
              .map((json) => ReportResponseDto.fromJson(json))
              .toList();
        }
      }

      print('[ReportApiClient] ⚠️ No se encontraron reportes en la respuesta');
      return <ReportResponseDto>[];
    } on DioException catch (e) {
      print('[ReportApiClient] ❌ Error en MIS reportes: ${e.message}');
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('[ReportApiClient] ❌ Error inesperado MIS reportes: $e');
      throw ReportExceptions('Error al obtener mis reportes: $e');
    }
  }

  Future<ReportResponseDto> createReport(ReportRequestDto requestDto) async {
    try {
      final response = await _dio.post(
        ApiConstants.createReport,
        data: requestDto.toJson(),
      );

      return ReportResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ===== Manejo de errores centralizado =====
  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      throw const InvalidCredentialsException('Credenciales inválidas');
    } else if (e.response?.statusCode == 409) {
      throw const AuthException('Conflicto: posible duplicado');
    } else if (e.response?.statusCode == 422) {
      throw ReportValidationException(
        'Datos inválidos',
        e.response?.data['errors'] ?? {},
      );
    } else if (e.response?.statusCode == 500) {
      throw const AuthException('Error del servidor');
    } else {
      throw AuthException('Error inesperado: ${e.message}');
    }
  }
}
