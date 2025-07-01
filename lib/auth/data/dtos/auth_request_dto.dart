class LoginRequestDto {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequestDto({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
    'remember_me': rememberMe,
  };

  @override
  String toString() => 'LoginRequestDto(email: $email, rememberMe: $rememberMe)';
}

class RegisterRequestDto {
  final String name;
  final String lastName;
  final String? secondLastName;
  final String username;
  final int age;
  final String gender;
  final String jobType;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterRequestDto({
    required this.name,
    required this.lastName,
    this.secondLastName,
    required this.username,
    required this.age,
    required this.gender,
    required this.jobType,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'last_name': lastName.trim(),
    if (secondLastName != null && secondLastName!.isNotEmpty) 
      'second_last_name': secondLastName!.trim(),
    'username': username.trim().toLowerCase(),
    'age': age,
    'gender': gender,
    'job_type': jobType,
    'email': email.trim().toLowerCase(),
    'password': password,
    'confirm_password': confirmPassword,
  };

  @override
  String toString() => 'RegisterRequestDto(name: $name $lastName, username: $username, email: $email)';
}