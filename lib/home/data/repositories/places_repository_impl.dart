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
      print('🔍 [PlacesRepositoryImpl] Buscando lugares: $query');

      final placeDtos = await _apiClient.searchPlaces(
        query,
        latitude: nearLocation?.latitude,
        longitude: nearLocation?.longitude,
        limit: limit,
      );

      final places = placeDtos.map((dto) => dto.toDomainEntity()).toList();

      print('✅ [PlacesRepositoryImpl] Encontrados ${places.length} lugares');
      for (final place in places) {
        print('📍 [PlacesRepositoryImpl] - ${place.displayName}');
      }

      return places;
    } catch (e) {
      print('❌ [PlacesRepositoryImpl] Error al buscar lugares: $e');
      throw Exception('Error al buscar lugares: $e');
    }
  }
}
