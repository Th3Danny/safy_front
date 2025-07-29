import 'package:safy/home/domain/entities/location.dart';

class Place {
  final String displayName;
  final Location location;
  final String? category;
  final String? type;
  final String? address;

  const Place({
    required this.displayName,
    required this.location,
    this.category,
    this.type,
    this.address,
  });

  // Helper para obtener coordenadas
  double get latitude => location.latitude;
  double get longitude => location.longitude;
}
