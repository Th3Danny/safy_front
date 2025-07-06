import 'package:safy/home/domain/repositories/open_route_repository.dart';

class GetOpenRouteUseCase {
  final OpenRouteRepository repository;

  GetOpenRouteUseCase(this.repository);

  Future<List<List<double>>> call({
    required List<double> start,
    required List<double> end,
  }) async {
    return await repository.fetchRoute(start: start, end: end);
  }
}