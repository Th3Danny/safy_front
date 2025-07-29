enum Job {
  student('STUDENT', 'Estudiante'),
  employee('EMPLOYEE', 'Empleado'),
  businessman('BUSINESSMAN', 'Empresario'),
  tourist('TOURIST', 'Turista');

  const Job(this.value, this.displayName);

  final String value;
  final String displayName;

  static Job fromString(String value) {
    return Job.values.firstWhere(
      (type) => type.value == value,
      orElse: () => Job.student,
    );
  }
} 
