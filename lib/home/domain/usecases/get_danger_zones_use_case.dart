
import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';

class GetDangerZonesUseCase {
  final DangerZoneRepository _dangerZoneRepository;

  GetDangerZonesUseCase(this._dangerZoneRepository);

  Future<List<DangerZone>> execute({
    required Location center,
    required double radiusKm,
  }) async {
    try {
      return await _dangerZoneRepository.getDangerZonesInArea(
        center: center,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw ServerFailure('Error obteniendo zonas peligrosas: $e');
    }
  }
}