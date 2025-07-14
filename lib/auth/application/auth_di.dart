import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:safy/auth/data/datasources/auth_data_source.dart';
import 'package:safy/auth/data/repositories/auth_repository_impl.dart';
import 'package:safy/auth/domain/repositories/auth_repository.dart';
import 'package:safy/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:safy/auth/domain/usecases/sign_in_use_case.dart';
import 'package:safy/auth/domain/usecases/sign_out_use_case.dart';
import 'package:safy/auth/domain/usecases/sign_up_use_case.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/core/session/token_refresh_service.dart';

final sl = GetIt.instance;

// En tu archivo auth/application/auth_di.dart
Future<void> setupAuthDependencies() async {
  // Obtener instancia ya registrada de SessionManager
  final sessionManager = sl<SessionManager>();

  sl.registerLazySingleton<AuthApiClient>(
    () => AuthApiClient(sl<Dio>(instanceName: 'authenticated')),
  );

  // Token Refresh Service
  TokenRefreshService.initialize(sl<AuthApiClient>());
  sl.registerLazySingleton<TokenRefreshService>(
    () => TokenRefreshService.instance,
  );

  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthApiClient>(), sessionManager),
  );

  // ===== USE CASES =====
  sl.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl<AuthRepository>()),
  );

  // ===== VIEW MODELS =====
  // Factory para LoginViewModel (nueva instancia cada vez)
  sl.registerFactory<LoginViewModel>(
    () => LoginViewModel(sl<SignInUseCase>()),
  );

  // Singleton para RegisterViewModel (mantener estado)
  sl.registerLazySingleton<RegisterViewModel>(
    () => RegisterViewModel(sl<SignUpUseCase>()),
  );

  // Singleton para AuthStateViewModel (estado global)
  sl.registerLazySingleton<AuthStateViewModel>(
    () => AuthStateViewModel(
      sl<GetCurrentUserUseCase>(),
      sl<SignOutUseCase>(),
      sessionManager, // Usar la instancia ya registrada
    )..initialize(), // Inicializar automáticamente
  );

  print('[AuthDI] ✅ Dependencias de autenticación registradas');
}

// 🧹 Método opcional para limpiar después del registro exitoso
void resetRegisterViewModelAfterSuccess() {
  if (sl.isRegistered<RegisterViewModel>()) {
    final registerViewModel = sl<RegisterViewModel>();
    registerViewModel.clearForm();
    print('[AuthDI] 🧹 RegisterViewModel limpiado después del registro exitoso');
  }
}