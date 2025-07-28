import 'package:safy/report/data/dtos/title_suggestion_dto.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

class SuggestTitleUseCase {
  final ReportRepository _repository;

  SuggestTitleUseCase(this._repository);

  Future<TitleSuggestionDto> call({
    required String description,
    required String incident_type,
    required String address,
    required int severity,
    required bool is_anonymous,
  }) async {
    try {
      return await _repository.suggestTitle(
        description: description,
        incident_type: incident_type,
        address: address,
        severity: severity,
        is_anonymous: is_anonymous,
      );
    } catch (e) {
      throw Exception('Error al sugerir título: $e');
    }
  }
}
