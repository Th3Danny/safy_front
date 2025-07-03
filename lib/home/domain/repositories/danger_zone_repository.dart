

import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';

abstract class DangerZoneRepository {
  Future<List<DangerZone>> getDangerZonesInArea({
    required Location center,
    required double radiusKm,
  });

  Future<List<DangerZone>> getAllActiveDangerZones();

  Future<bool> isLocationSafe(Location location);

  Future<DangerZone?> getDangerZoneAtLocation(Location location);

  Future<void> updateDangerZoneFromReport({
    required Location location,
    required String incidentType,
  });
}