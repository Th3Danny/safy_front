import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';

class SearchPlacesUseCase {
  final PlacesRepository _repository;

  SearchPlacesUseCase(this._repository);

  Future<List<Place>> execute(
    String query, {
    Location? nearLocation,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) {
      throw Exception('La consulta no puede estar vacía');
    }

    return await _repository.searchPlaces(
      query,
      nearLocation: nearLocation,
      limit: limit,
    );
  }
}
