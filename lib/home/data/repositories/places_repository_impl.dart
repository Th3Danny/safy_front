import 'package:safy/home/data/datasources/mapbox_places_client.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final MapboxPlacesClient _apiClient;

  PlacesRepositoryImpl(this._apiClient);

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    Location? nearLocation,
    int limit = 8,
  }) async {
    try {
      // Removed debug print

      final placeDtos = await _apiClient.searchPlaces(
        query,
        latitude: nearLocation?.latitude,
        longitude: nearLocation?.longitude,
        limit: limit,
      );

      final places = placeDtos.map((dto) => dto.toDomainEntity()).toList();

      // Removed debug print
      for (final place in places) {
        // Removed debug print
      }

      return places;
    } catch (e) {
      // Removed debug print
      throw Exception('Error al buscar lugares: $e');
    }
  }
}
