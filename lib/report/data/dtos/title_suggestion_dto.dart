class TitleSuggestionDto {
  final String titulo_sugerido;

  TitleSuggestionDto({required this.titulo_sugerido});

  factory TitleSuggestionDto.fromJson(Map<String, dynamic> json) {
    return TitleSuggestionDto(titulo_sugerido: json['titulo_sugerido'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'titulo_sugerido': titulo_sugerido};
  }

  @override
  String toString() {
    return 'TitleSuggestionDto(titulo_sugerido: $titulo_sugerido)';
  }
}
