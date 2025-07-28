import 'package:safy/report/data/dtos/address_response_dto.dart';
import 'package:safy/report/data/dtos/spelling_correction_dto.dart';
import 'package:safy/report/data/dtos/title_suggestion_dto.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';
import '../entities/report.dart';



abstract class ReportRepository {
   Future<List<ClusterEntity>> getClusters({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? city,
    int? minSeverity,
    int? maxSeverity,
    int? maxHoursAgo,
  });

  Future<List<ReportInfoEntity>> getReports({
    required String userId,
    int? page,
    int? pageSize,
    double? latitude,
    double? longitude,
  });

  Future<ReportInfoEntity> getReportById({required String id});

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
  });

  // ===== Nuevos servicios de ayuda para reportes =====

  /// Convierte coordenadas (latitud, longitud) a dirección
  Future<AddressResponseDto> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });

  /// Corrige errores ortográficos en la descripción
  Future<SpellingCorrectionDto> correctSpelling({
    required String description,
  });

  /// Sugiere un título basado en el contenido del reporte
  Future<TitleSuggestionDto> suggestTitle({
    required String description,
    required String incident_type,
    required String address,
    required int severity,
    required bool is_anonymous,
  });

  // Future<ReportInfoEntity> updateReport(ReportInfoEntity report);

  // Future<void> deleteReport(String reportId);
}
