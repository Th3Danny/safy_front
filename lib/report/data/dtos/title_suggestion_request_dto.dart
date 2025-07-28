class TitleSuggestionRequestDto {
  final String description;
  final String incident_type;
  final String address;
  final int severity;
  final bool is_anonymous;

  TitleSuggestionRequestDto({
    required this.description,
    required this.incident_type,
    required this.address,
    required this.severity,
    required this.is_anonymous,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'incident_type': incident_type,
      'address': address,
      'severity': severity,
      'is_anonymous': is_anonymous,
    };
  }

  @override
  String toString() {
    return 'TitleSuggestionRequestDto(description: $description, incident_type: $incident_type, address: $address, severity: $severity, is_anonymous: $is_anonymous)';
  }
}
