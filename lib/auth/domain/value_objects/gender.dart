enum Gender {
  male('MALE', 'Masculino'),
  female('FEMALE', 'Femenino'),
  other('OTHER', 'Otro'),
  preferNotToSay('PREFER_NOT_TO_SAY', 'Prefiero no decir');

  const Gender(this.value, this.displayName);

  final String value;
  final String displayName;

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}
