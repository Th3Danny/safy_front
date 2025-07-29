import 'package:dio/dio.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/report/data/dtos/address_response_dto.dart';
import 'package:safy/report/data/dtos/cluster_response_dto.dart';
import 'package:safy/report/data/dtos/coordinates_request_dto.dart';
import 'package:safy/report/data/dtos/report_request_dto.dart';
import 'package:safy/report/data/dtos/report_response_dto.dart';
import 'package:safy/report/data/dtos/spelling_correction_dto.dart';
import 'package:safy/report/data/dtos/spelling_request_dto.dart';
import 'package:safy/report/data/dtos/title_suggestion_dto.dart';
import 'package:safy/report/data/dtos/title_suggestion_request_dto.dart';
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

      return _parseClustersResponse(response.data);
    } on DioException catch (e) {
      throw Exception('Error obteniendo clusters: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado obteniendo clusters: $e');
    }
  }

  List<ClusterResponseDto> _parseClustersResponse(dynamic data) {
    if (data == null) {
      return <ClusterResponseDto>[];
    }

    if (data is Map<String, dynamic>) {
      // Buscar estructura específica de smart-nearby
      if (data.containsKey('data')) {
        final dataSection = data['data'] as Map<String, dynamic>?;
        if (dataSection != null && dataSection.containsKey('clusters')) {
          final clusters = dataSection['clusters'] as List?;
          if (clusters != null) {
            try {
              final clusterList =
                  clusters
                      .map(
                        (clusterJson) => ClusterResponseDto.fromJson(
                          clusterJson as Map<String, dynamic>,
                        ),
                      )
                      .toList();

              return clusterList;
            } catch (e) {
              return <ClusterResponseDto>[];
            }
          }
        }
      }

      return <ClusterResponseDto>[];
    }

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
  //     // Removed debug print

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

  //     // Removed debug print

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
  //     // Removed debug print
  //     _handleDioError(e);
  //     rethrow;
  //   } catch (e) {
  //     // Removed debug print
  //     throw ReportExceptions('Error al obtener reportes cercanos: $e');
  //   }
  // }

  Future<ReportResponseDto> getReportById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.reports}/$id');

      if (response.data == null) {
        throw FormatException(
          'La respuesta del servidor para el reporte con ID $id es nula.',
        );
      }

      // Asegurarse de que el nivel superior de response.data es un Map
      if (response.data is! Map<String, dynamic>) {
        throw FormatException(
          'La respuesta del servidor para el reporte con ID $id no es un mapa JSON válido.',
        );
      }

      final Map<String, dynamic> responseMap =
          response.data as Map<String, dynamic>;

      // CORRECCIÓN CLAVE AQUÍ: Extraer el objeto del reporte del campo 'data'
      if (!responseMap.containsKey('data') ||
          responseMap['data'] is! Map<String, dynamic>) {
        throw FormatException(
          'La respuesta del servidor para el reporte con ID $id no contiene la clave "data" o está malformada.',
        );
      }

      final Map<String, dynamic> reportData =
          responseMap['data'] as Map<String, dynamic>;
      return ReportResponseDto.fromJson(reportData);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw ReportExceptions('Error al obtener reporte por ID $id: $e');
    }
  }

  Future<List<ReportResponseDto>> getMyReports({
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '/reports/my-reports',
        queryParameters: {'page': page ?? 0, 'size': pageSize ?? 10},
      );

      // **CORRECCIÓN INICIA AQUÍ**
      if (response.data == null) {
        throw FormatException('La respuesta del servidor es nula.');
      }

      if (response.data is! Map<String, dynamic>) {
        throw FormatException(
          'La respuesta del servidor no es un mapa JSON válido.',
        );
      }

      final Map<String, dynamic> responseMap =
          response.data as Map<String, dynamic>; // Explicit cast

      if (!responseMap.containsKey('data') ||
          responseMap['data'] is! Map<String, dynamic>) {
        throw FormatException(
          'La respuesta del servidor no contiene la clave "data" o está malformada.',
        ); //
      }

      final Map<String, dynamic> data =
          responseMap['data'] as Map<String, dynamic>; // Explicit cast

      if (!data.containsKey('reports') || data['reports'] is! List) {
        throw FormatException(
          'La clave "reports" no se encontró o no es una lista dentro de "data".',
        ); //
      }

      final List<dynamic> reportsJson =
          data['reports'] as List<dynamic>; // Explicit cast

      return reportsJson
          .map(
            (jsonItem) =>
                ReportResponseDto.fromJson(jsonItem as Map<String, dynamic>),
          ) // Cast each item
          .toList();
      // **CORRECCIÓN TERMINA AQUÍ**
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw ReportExceptions('Error al obtener mis reportes: $e');
    }
  }

  Future<ReportResponseDto> createReport(ReportRequestDto requestDto) async {
    try {
      final response = await _dio.post(
        ApiConstants.createReport,
        data: requestDto.toJson(),
      );

      // Verificar que la respuesta tenga la estructura esperada
      if (response.data == null) {
        throw FormatException('La respuesta del servidor es nula.');
      }

      if (response.data is! Map<String, dynamic>) {
        throw FormatException(
          'La respuesta del servidor no es un mapa JSON válido.',
        );
      }

      final Map<String, dynamic> responseMap =
          response.data as Map<String, dynamic>;

      // Extraer el objeto del reporte del campo 'data'
      if (!responseMap.containsKey('data') ||
          responseMap['data'] is! Map<String, dynamic>) {
        throw FormatException(
          'La respuesta del servidor no contiene la clave "data" o está malformada.',
        );
      }

      final Map<String, dynamic> reportData =
          responseMap['data'] as Map<String, dynamic>;

      return ReportResponseDto.fromJson(reportData);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw ReportExceptions('Error al crear reporte: $e');
    }
  }

  // ===== Nuevos servicios de ayuda para reportes =====

  /// Convierte coordenadas (latitud, longitud) a dirección
  Future<AddressResponseDto> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final request = CoordinatesRequestDto(
        latitude: latitude,
        longitude: longitude,
      );

      final response = await _dio.post(
        'https://datamining.devquailityup.xyz/coordenadas-a-direccion',
        data: request.toJson(),
      );

      return AddressResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw ReportExceptions('Error al obtener dirección: $e');
    }
  }

  /// Corrige errores ortográficos en la descripción
  Future<SpellingCorrectionDto> correctSpelling({
    required String description,
  }) async {
    try {
      final request = SpellingRequestDto(description: description);

      final response = await _dio.post(
        'https://datamining.devquailityup.xyz/corregir-ortografia',
        data: request.toJson(),
      );

      return SpellingCorrectionDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw ReportExceptions('Error al corregir ortografía: $e');
    }
  }

  /// Sugiere un título basado en el contenido del reporte
  Future<TitleSuggestionDto> suggestTitle({
    required String description,
    required String incident_type,
    required String address,
    required int severity,
    required bool is_anonymous,
  }) async {
    try {
      final request = TitleSuggestionRequestDto(
        description: description,
        incident_type: incident_type,
        address: address,
        severity: severity,
        is_anonymous: is_anonymous,
      );

      final response = await _dio.post(
        'https://datamining.devquailityup.xyz/suggest-title',
        data: request.toJson(),
      );

      return TitleSuggestionDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      throw ReportExceptions('Error al sugerir título: $e');
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
