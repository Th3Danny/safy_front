class SpellingRequestDto {
  final String description;

  SpellingRequestDto({required this.description});

  Map<String, dynamic> toJson() {
    return {'description': description};
  }

  @override
  String toString() {
    return 'SpellingRequestDto(description: $description)';
  }
}
