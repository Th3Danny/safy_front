import 'package:safy/home/domain/repositories/open_route_repository.dart';
import 'package:safy/home/data/datasources/openroute_service_api_client.dart';

class OpenRouteRepositoryImpl implements OpenRouteRepository {
  final OSRMApiClient  apiClient;

  OpenRouteRepositoryImpl(this.apiClient);

  @override
  Future<List<List<double>>> fetchRoute({
    required List<double> start,
    required List<double> end,
  }) {
    return apiClient.getRouteCoordinates(start: start, end: end);
  }
}