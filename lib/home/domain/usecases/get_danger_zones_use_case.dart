import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/core/errors/failures.dart';

class GetDangerZonesUseCase {
  final DangerZoneRepository _dangerZoneRepository;

  GetDangerZonesUseCase(this._dangerZoneRepository);

  // Obtener zonas de peligro en un área específica
  Future<List<DangerZone>> execute(
    Location center, {
    double radiusKm = 5.0,
  }) async {
    try {
      return await _dangerZoneRepository.getDangerZonesInArea(
        center: center,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw ServerFailure('Error obteniendo zonas de peligro: $e');
    }
  }

  // Obtener todas las zonas de peligro activas
  Future<List<DangerZone>> getAllActive() async {
    try {
      return await _dangerZoneRepository.getAllActiveDangerZones();
    } catch (e) {
      throw ServerFailure('Error obteniendo zonas de peligro activas: $e');
    }
  }

  // Actualizar zona de peligro basado en un reporte
  Future<void> updateFromReport({
    required Location location,
    required String incidentType,
  }) async {
    try {
      await _dangerZoneRepository.updateDangerZoneFromReport(
        location: location,
        incidentType: incidentType,
      );
    } catch (e) {
      throw ServerFailure('Error actualizando zona de peligro: $e');
    }
  }
}
