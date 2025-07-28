class AddressResponseDto {
  final String direccion;

  AddressResponseDto({required this.direccion});

  factory AddressResponseDto.fromJson(Map<String, dynamic> json) {
    return AddressResponseDto(direccion: json['direccion'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'direccion': direccion};
  }

  @override
  String toString() {
    return 'AddressResponseDto(direccion: $direccion)';
  }
}
