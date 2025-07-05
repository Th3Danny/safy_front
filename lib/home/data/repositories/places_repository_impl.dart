import 'package:safy/home/data/datasources/nominatim_api_client.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final NominatimApiClient _apiClient;

  PlacesRepositoryImpl(this._apiClient);

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    Location? nearLocation,
    int limit = 5,
  }) async {
    try {
      final placeDtos = await _apiClient.searchPlaces(
        query,
        latitude: nearLocation?.latitude,
        longitude: nearLocation?.longitude,
        limit: limit,
      );
      
      return placeDtos.map((dto) => dto.toDomainEntity()).toList();
    } catch (e) {
      throw Exception('Error al buscar lugares: $e');
    }
  }
}