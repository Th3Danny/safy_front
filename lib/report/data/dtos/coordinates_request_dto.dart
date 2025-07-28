class CoordinatesRequestDto {
  final double latitude;
  final double longitude;

  CoordinatesRequestDto({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  @override
  String toString() {
    return 'CoordinatesRequestDto(latitude: $latitude, longitude: $longitude)';
  }
}
