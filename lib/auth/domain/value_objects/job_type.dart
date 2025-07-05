enum JobType {
  student('student', 'Estudiante'),
  employee('employee', 'Empleado'),
  businessman('businessman', 'Empresario'),
  tourist('tourist', 'Turista');

  const JobType(this.value, this.displayName);

  final String value;
  final String displayName;

  static JobType fromString(String value) {
    return JobType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => JobType.student,
    );
  }
} 