
import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/report/domain/repositories/report_repository.dart'; 
class GetClustersUseCase {
  final ReportRepository _repository; 

  GetClustersUseCase(this._repository);

  Future<List<ClusterEntity>> execute({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? city,
    int? minSeverity,
    int? maxSeverity,
    int? maxHoursAgo,
  }) async {
    try {
      print('[GetClustersUseCase] 📍 Ejecutando caso de uso para obtener clusters');
      print('[GetClustersUseCase] 🌍 Coordenadas: $latitude, $longitude');
      
      final clusters = await _repository.getClusters( // ✅ CAMBIO: usar _repository en lugar de _clusterRepository
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm ?? 10.0,
        city: city ?? 'tuxtla',
        minSeverity: minSeverity ?? 0,
        maxSeverity: maxSeverity ?? 10,
        maxHoursAgo: maxHoursAgo ?? 168,
      );

      print('[GetClustersUseCase] ✅ Clusters obtenidos: ${clusters.length}');
      return clusters;
      
    } catch (e) {
      print('[GetClustersUseCase] ❌ Error: $e');
      throw Exception('Error al obtener clusters de zonas peligrosas: $e');
    }
  }
}