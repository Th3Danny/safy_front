class SpellingCorrectionDto {
  final String descripcion_corregida;

  SpellingCorrectionDto({required this.descripcion_corregida});

  factory SpellingCorrectionDto.fromJson(Map<String, dynamic> json) {
    return SpellingCorrectionDto(
      descripcion_corregida: json['descripcion_corregida'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'descripcion_corregida': descripcion_corregida};
  }

  @override
  String toString() {
    return 'SpellingCorrectionDto(descripcion_corregida: $descripcion_corregida)';
  }
}
