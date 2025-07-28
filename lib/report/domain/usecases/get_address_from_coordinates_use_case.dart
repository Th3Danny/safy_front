import 'package:safy/report/data/dtos/address_response_dto.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

class GetAddressFromCoordinatesUseCase {
  final ReportRepository _repository;

  GetAddressFromCoordinatesUseCase(this._repository);

  Future<AddressResponseDto> call({
    required double latitude,
    required double longitude,
  }) async {
    try {
      return await _repository.getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw Exception('Error al obtener dirección desde coordenadas: $e');
    }
  }
}
