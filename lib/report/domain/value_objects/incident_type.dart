enum IncidentType {
  
  streetHarassment('Street Harassment', 'Acoso Callejero'),
  thefts('Thefts', 'Robos'),
  kidnapping('Kidnapping', 'Secuestro'),
  gangsterism('Gangsterism', 'Pandillerismo');

  const IncidentType(this.value, this.displayName);

  final String value;
  final String displayName;
  static IncidentType fromString(String value) {
    return IncidentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => IncidentType.streetHarassment,
    );
  }
}
