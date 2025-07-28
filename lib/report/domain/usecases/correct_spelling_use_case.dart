import 'package:safy/report/data/dtos/spelling_correction_dto.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

class CorrectSpellingUseCase {
  final ReportRepository _repository;

  CorrectSpellingUseCase(this._repository);

  Future<SpellingCorrectionDto> call({required String description}) async {
    try {
      return await _repository.correctSpelling(description: description);
    } catch (e) {
      throw Exception('Error al corregir ortografía: $e');
    }
  }
}
