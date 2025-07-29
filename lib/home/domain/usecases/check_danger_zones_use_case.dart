

import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/danger_zone.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';

class CheckDangerZonesUseCase {
  final DangerZoneRepository _dangerZoneRepository;

  CheckDangerZonesUseCase(this._dangerZoneRepository);

  Future<DangerZoneCheckResult> execute(Location location) async {
    try {
      final dangerZone = await _dangerZoneRepository.getDangerZoneAtLocation(location);
      
      if (dangerZone == null) {
        return DangerZoneCheckResult(
          isSafe: true,
          dangerZone: null,
          message: 'Área segura',
        );
      }

      return DangerZoneCheckResult(
        isSafe: false,
        dangerZone: dangerZone,
        message: _buildWarningMessage(dangerZone),
      );
    } catch (e) {
      throw ServerFailure('Error verificando zonas peligrosas: $e');
    }
  }

  String _buildWarningMessage(DangerZone dangerZone) {
    final incidentText = dangerZone.incidentTypes.join(', ');
    return 'Zona de riesgo ${dangerZone.dangerLevel.displayName.toLowerCase()} detectada. '
           'Tipos de incidentes: $incidentText. '
           '${dangerZone.reportCount} reportes en total.';
  }
}

class DangerZoneCheckResult {
  final bool isSafe;
  final DangerZone? dangerZone;
  final String message;

  DangerZoneCheckResult({
    required this.isSafe,
    required this.dangerZone,
    required this.message,
  });
}
