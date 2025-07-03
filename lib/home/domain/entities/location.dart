import 'package:latlong2/latlong.dart';

class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'Location(lat: $latitude, lng: $longitude)';
}