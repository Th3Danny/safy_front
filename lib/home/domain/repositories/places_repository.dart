import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/place.dart';

abstract class PlacesRepository {
  Future<List<Place>> searchPlaces(
    String query, {
    Location? nearLocation,
    int limit = 5,
  });
}
