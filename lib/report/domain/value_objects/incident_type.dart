enum IncidentType {
  streetHarassment('STREET_HARASSMENT', 'Acoso Callejero'),
  robberyAssault('ROBBERY_ASSAULT', 'Asaltos / Robos'), // 👈 Cambié de 'thefts'
  kidnapping('KIDNAPPING', 'Secuestro'),
  gangViolence('GANG_VIOLENCE', 'Pandillas o peleas'), // 👈 Cambié de 'gangsterism'
  
  // 🆕 Agregué otros valores que acepta el backend
  suspiciousActivity('SUSPICIOUS_ACTIVITY', 'Actividad Sospechosa'),
  vandalism('VANDALISM', 'Vandalismo'),
  abandonedArea('ABANDONED_AREA', 'Área Abandonada'),
  poorLighting('POOR_LIGHTING', 'Iluminación Deficiente'),
  domesticViolence('DOMESTIC_VIOLENCE', 'Violencia Doméstica'),
  drugActivity('DRUG_ACTIVITY', 'Actividad de Drogas'),
  other('OTHER', 'Otro');

  const IncidentType(this.backendValue, this.displayName);

  final String backendValue; // 👈 Valor que espera el backend
  final String displayName; // 👈 Nombre para mostrar en la UI

  // 🔥 GETTER PARA EL BACKEND - MUY IMPORTANTE
  String get name => backendValue;
  
  // Método para buscar por valor del backend
  static IncidentType fromBackendValue(String value) {
    return IncidentType.values.firstWhere(
      (type) => type.backendValue == value,
      orElse: () => IncidentType.streetHarassment,
    );
  }
  
  // Método para buscar por nombre de display
  static IncidentType fromDisplayName(String displayName) {
    return IncidentType.values.firstWhere(
      (type) => type.displayName == displayName,
      orElse: () => IncidentType.streetHarassment,
    );
  }
  
  // Método legacy para compatibilidad
  static IncidentType fromString(String value) {
    return fromBackendValue(value);
  }
}
