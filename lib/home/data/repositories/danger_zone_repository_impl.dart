import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/data/datasources/danger_zone_api_client.dart';
import 'package:safy/home/data/dtos/location_dto.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';


class DangerZoneRepositoryImpl implements DangerZoneRepository {
  final DangerZoneApiClient _apiClient;

  DangerZoneRepositoryImpl(this._apiClient);

  @override
  Future<List<DangerZone>> getDangerZonesInArea({
    required Location center,
    required double radiusKm,
  }) async {
    try {
      final centerDto = LocationDto.fromDomainEntity(center);
      final zoneDtos = await _apiClient.getDangerZonesInArea(
        center: centerDto,
        radiusKm: radiusKm,
      );

      return zoneDtos.map((dto) => dto.toDomainEntity()).toList();
    } catch (e) {
      throw ServerFailure('Error obteniendo zonas peligrosas: $e');
    }
  }

  @override
  Future<List<DangerZone>> getAllActiveDangerZones() async {
    try {
      final zoneDtos = await _apiClient.getAllActiveDangerZones();
      return zoneDtos.map((dto) => dto.toDomainEntity()).toList();
    } catch (e) {
      throw ServerFailure('Error obteniendo zonas peligrosas activas: $e');
    }
  }

  @override
  Future<bool> isLocationSafe(Location location) async {
    try {
      final locationDto = LocationDto.fromDomainEntity(location);
      return await _apiClient.isLocationSafe(locationDto);
    } catch (e) {
      throw ServerFailure('Error verificando seguridad de ubicación: $e');
    }
  }

  @override
  Future<DangerZone?> getDangerZoneAtLocation(Location location) async {
    try {
      final locationDto = LocationDto.fromDomainEntity(location);
      final zoneDto = await _apiClient.getDangerZoneAtLocation(locationDto);
      return zoneDto?.toDomainEntity();
    } catch (e) {
      throw ServerFailure('Error obteniendo zona peligrosa en ubicación: $e');
    }
  }

  @override
  Future<void> updateDangerZoneFromReport({
    required Location location,
    required String incidentType,
  }) async {
    try {
      final locationDto = LocationDto.fromDomainEntity(location);
      await _apiClient.updateDangerZoneFromReport(
        location: locationDto,
        incidentType: incidentType,
      );
    } catch (e) {
      throw ServerFailure('Error actualizando zona peligrosa: $e');
    }
  }
}
