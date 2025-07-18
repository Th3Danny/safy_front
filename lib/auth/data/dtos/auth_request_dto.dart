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
    //'remember_me': rememberMe,
  };

  @override
  String toString() => 'LoginRequestDto(email: $email)';
}

class RegisterRequestDto {
  final String name;
  final String lastName;
  final String? secondLastName;
  final String username;
  final int age;
  final String gender;
  final String job;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phoneNumber;
  final String role;

  const RegisterRequestDto({
    required this.name,
    required this.lastName,
    this.secondLastName,
    required this.username,
    required this.age,
    required this.gender,
    required this.job,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phoneNumber,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'lastname': lastName.trim(),
    if (secondLastName != null && secondLastName!.isNotEmpty) 
      'second_lastname': secondLastName!.trim(),
    'username': username.trim().toLowerCase(),
    'age': age,
    'gender': gender,
    'job': job,
    'email': email.trim().toLowerCase(),
    'password': password,
    'confirm_password': confirmPassword,
    if (phoneNumber != null && phoneNumber!.isNotEmpty) 
    'phone_number': null,
    'role': role,
  };

  @override
  String toString() => 'RegisterRequestDto(name: $name $lastName, username: $username, email: $email)';
}