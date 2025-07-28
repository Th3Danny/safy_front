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
      print('[ReportApiClient] 🔍 Obteniendo reporte por ID: $id');
      final response = await _dio.get('${ApiConstants.reports}/$id');

      print(
        '[ReportApiClient] ✅ Respuesta recibida para ID $id: ${response.statusCode}',
      );
      print('[ReportApiClient] 📋 Tipo de data: ${response.data.runtimeType}');

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
      print('[ReportApiClient] ✅ Reporte individual extraído de "data".');

      // Ahora, pasa el `reportData` (que es el JSON del reporte individual)
      // a ReportResponseDto.fromJson
      return ReportResponseDto.fromJson(reportData);
    } on DioException catch (e) {
      print('[ReportApiClient] ❌ Error en getReportById: ${e.message}');
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('[ReportApiClient] ❌ Error inesperado en getReportById: $e');
      throw ReportExceptions('Error al obtener reporte por ID $id: $e');
    }
  }

  Future<List<ReportResponseDto>> getMyReports({
    int? page,
    int? pageSize,
  }) async {
    try {
      print('[ReportApiClient] 📋 Obteniendo MIS reportes');

      final response = await _dio.get(
        '/reports/my-reports',
        queryParameters: {'page': page ?? 0, 'size': pageSize ?? 10},
      );

      print(
        '[ReportApiClient] ✅ Respuesta MIS reportes: ${response.statusCode}',
      );
      print('[ReportApiClient] 📋 Respuesta completa: ${response.data}'); //

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
      print(
        '[ReportApiClient] ✅ Encontrados ${reportsJson.length} reportes',
      ); //

      return reportsJson
          .map(
            (jsonItem) =>
                ReportResponseDto.fromJson(jsonItem as Map<String, dynamic>),
          ) // Cast each item
          .toList();
      // **CORRECCIÓN TERMINA AQUÍ**
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

      print(
        '[ReportApiClient] ✅ Respuesta de creación: ${response.statusCode}',
      );
      print('[ReportApiClient] 📋 Respuesta completa: ${response.data}');

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
      print('[ReportApiClient] ✅ Reporte extraído de "data".');

      return ReportResponseDto.fromJson(reportData);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('[ReportApiClient] ❌ Error inesperado en createReport: $e');
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
      print(
        '[ReportApiClient] 📍 Obteniendo dirección para coordenadas: $latitude, $longitude',
      );

      final request = CoordinatesRequestDto(
        latitude: latitude,
        longitude: longitude,
      );

      final response = await _dio.post(
        'https://datamining.devquailityup.xyz/coordenadas-a-direccion',
        data: request.toJson(),
      );

      print('[ReportApiClient] ✅ Dirección obtenida: ${response.statusCode}');
      return AddressResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      print('[ReportApiClient] ❌ Error obteniendo dirección: ${e.message}');
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('[ReportApiClient] ❌ Error inesperado obteniendo dirección: $e');
      throw ReportExceptions('Error al obtener dirección: $e');
    }
  }

  /// Corrige errores ortográficos en la descripción
  Future<SpellingCorrectionDto> correctSpelling({
    required String description,
  }) async {
    try {
      print('[ReportApiClient] ✏️ Corrigiendo ortografía de descripción');

      final request = SpellingRequestDto(description: description);

      final response = await _dio.post(
        'https://datamining.devquailityup.xyz/corregir-ortografia',
        data: request.toJson(),
      );

      print('[ReportApiClient] ✅ Ortografía corregida: ${response.statusCode}');
      return SpellingCorrectionDto.fromJson(response.data);
    } on DioException catch (e) {
      print('[ReportApiClient] ❌ Error corrigiendo ortografía: ${e.message}');
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('[ReportApiClient] ❌ Error inesperado corrigiendo ortografía: $e');
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
      print('[ReportApiClient] 💡 Sugiriendo título para reporte');

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

      print('[ReportApiClient] ✅ Título sugerido: ${response.statusCode}');
      return TitleSuggestionDto.fromJson(response.data);
    } on DioException catch (e) {
      print('[ReportApiClient] ❌ Error sugiriendo título: ${e.message}');
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('[ReportApiClient] ❌ Error inesperado sugiriendo título: $e');
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
