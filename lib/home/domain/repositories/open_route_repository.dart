abstract class OpenRouteRepository {
  Future<List<List<double>>> fetchRoute({
    required List<double> start,
    required List<double> end,
  });
}