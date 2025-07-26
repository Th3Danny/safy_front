import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/register/widgets/job_selector.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/shared/widget/custom_text_field.dart';
import 'package:safy/shared/widget/profile_avatar.dart';
import 'package:provider/provider.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/auth/domain/entities/user.dart';

class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  String? _selectedJob;
  final List<String> _jobs = ['Student', 'Employees', 'Businessman', 'Tourist'];
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthStateViewModel>(context, listen: false);
      if (!authVM.isInitialized) {
        authVM.initialize();
      }
    });
  }

  void _initControllersIfNeeded(AuthStateViewModel authVM) {
    if (_controllersInitialized) return;
    final user = authVM.currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController(text: '');
    _selectedJob ??= user?.job ?? _jobs.first;
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    if (_controllersInitialized) {
      _usernameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthStateViewModel>(context);
    if (!authVM.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    _initControllersIfNeeded(authVM);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Avatar de perfil
          const ProfileAvatar(radius: 50, showEditButton: true),

          const SizedBox(height: 32),

          // Username field
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Chivemoon',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'yaz@gmail.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password field
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••••••',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Job selector
          JobSelector(
            selectedJob: _selectedJob,
            jobs: _jobs,
            onJobSelected: (job) {
              setState(() {
                _selectedJob = job;
              });
            },
          ),

          const SizedBox(height: 32),

          // Save button
          CustomButton(
            text: 'Guardar',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _handleSaveProfile();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleSaveProfile() async {
    final authVM = Provider.of<AuthStateViewModel>(context, listen: false);
    final currentUser = authVM.currentUser;
    if (currentUser == null) return;

    // Crear nuevo UserInfoEntity con los datos editados
    final updatedUser = UserInfoEntity(
      id: currentUser.id,
      name: currentUser.name, // Puedes agregar campos editables si lo deseas
      lastName: currentUser.lastName,
      secondLastName: currentUser.secondLastName,
      username: _usernameController.text,
      email: _emailController.text,
      phoneNumber: currentUser.phoneNumber,
      job: _selectedJob ?? currentUser.job,
      role: currentUser.role,
      verified: currentUser.verified,
      isActive: currentUser.isActive,
    );

    // Actualizar en AuthStateViewModel (esto también actualiza SessionManager y backend si implementas la llamada)
    authVM.updateUser(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    context.go(AppRoutesConstant.settings);
  }
}
