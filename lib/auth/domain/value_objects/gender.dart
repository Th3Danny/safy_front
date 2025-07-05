enum Gender {
  male('male', 'Masculino'),
  female('female', 'Femenino'),
  other('other', 'Otro'),
  preferNotToSay('prefer_not_to_say', 'Prefiero no decir');

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