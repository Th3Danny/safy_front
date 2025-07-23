import 'package:dio/dio.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/report/data/dtos/report_request_dto.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/exceptions/report_exceptions.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';
import 'package:safy/report/data/datasources/report_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportApiClient _apiClient;

  ReportRepositoryImpl(this._apiClient);

  @override
  Future<List<ClusterEntity>> getClusters({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? city,
    int? minSeverity,
    int? maxSeverity,
    int? maxHoursAgo,
  }) async {
    try {
      print('[ClusterRepository] 📍 Obteniendo clusters cerca de: $latitude, $longitude');

      final clusterDtos = await _apiClient.getClusters(
        latitude: latitude,
        longitude: longitude,
      );

      final clusters = clusterDtos.map((dto) => dto.toDomainEntity()).toList();
      
      print('[ClusterRepository] ✅ Procesados ${clusters.length} clusters');
      
      return clusters;
    } catch (e) {
      print('[ClusterRepository] ❌ Error: $e');
      throw Exception('Error al obtener los clusters: $e');
    }
  }

  @override
  Future<List<ReportInfoEntity>> getReports({
    required String userId,
    int? page,
    int? pageSize,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Validar que se proporcionen coordenadas para reportes cercanos
      if (latitude == null || longitude == null) {
        throw ReportExceptions('Se requieren coordenadas para obtener reportes cercanos');
      }

      print('[ReportRepository] 📍 Obteniendo reportes cercanos en: $latitude, $longitude');

      final responseDtos = await _apiClient.getReports(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        page: page,
        pageSize: pageSize,
      );

      final reports = responseDtos.map((dto) => dto.toDomainEntity()).toList();
      
      print('[ReportRepository] ✅ Procesados ${reports.length} reportes');
      
      return reports;
    } on ReportExceptions {
      rethrow;
    } catch (e) {
      print('[ReportRepository] ❌ Error: $e');
      throw ReportExceptions('Error al obtener los reportes cercanos: $e');
    }
  }

  @override
  Future<ReportInfoEntity> getReportById({required String id}) async {
    try {
      final responseDto = await _apiClient.getReportById(id);
      return responseDto.toDomainEntity();
    } catch (e) {
      throw ReportExceptions('Error al obtener el reporte: $e');
    }
  }

  @override
Future<ReportInfoEntity> createReport({
  required String title,
  required String description,
  required String incident_type,
  required double latitude,
  required double longitude,
  String? address,
  required String reporterName,
  String? reporterEmail,
  required int severity,
  required bool isAnonymous,
  //required DateTime dateTime,
}) async {
  try {
    final requestDto = ReportRequestDto(
      title: title,
      description: description,
      incident_type: incident_type,
      latitude: latitude,
      longitude: longitude,
      address: address,
      reporter_name: reporterName,
      reporter_email: reporterEmail,
      severity: severity,
      is_anonymous: isAnonymous,
      //dateTime: dateTime,
    );

    final responseDto = await _apiClient.createReport(requestDto);
    return responseDto.toDomainEntity();
  } on DioException catch (e) {
    throw __mapDioErrorToReportException(e);
  } on AuthException {
    rethrow;
  } catch (e) {
    throw AuthException(
      'Error inesperado durante el registro: ${e.toString()}',
    );
  }
}

  ReportExceptions __mapDioErrorToReportException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (statusCode) {
      case 400:
        return ReportExceptions(
          'Solicitud incorrecta (400). Verifica los datos enviados.',
        );
      case 401:
        return ReportExceptions(
          'No autorizado (401). Credenciales inválidas o sesión expirada.',
        );
      case 403:
        return ReportExceptions(
          'Prohibido (403). No tienes permiso para realizar esta acción.',
        );
      case 404:
        return ReportExceptions(
          'No encontrado (404). El recurso solicitado no existe.',
        );
      case 409:
        return ReportExceptions(
          'Conflicto (409). El recurso ya existe o hay datos duplicados.',
        );
      case 422:
        return ReportExceptions(
          'Entidad no procesable (422). Error de validación de datos.',
        );
      case 500:
        return ReportExceptions(
          'Error interno del servidor (500). Intenta más tarde.',
        );
      default:
        return ReportExceptions('Error desconocido: ${e.message}');
    }
  }
}
