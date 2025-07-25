import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

class GetReportsUseCase {
  final ReportRepository _repository;

  GetReportsUseCase(this._repository);

  // ✅ CORREGIDO: coordenadas opcionales
  Future<List<ReportInfoEntity>> execute({
    required String userId,
    int? page,
    int? pageSize,
    double? latitude,  // ✅ OPCIONAL
    double? longitude, // ✅ OPCIONAL
  }) async {
    return await _repository.getReports(
      userId: userId,
      page: page,
      pageSize: pageSize,
      latitude: latitude,
      longitude: longitude,
    );
  }
}