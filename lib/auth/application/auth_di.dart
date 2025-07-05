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

Future<void> setupAuthDependencies() async {

  sl.registerLazySingleton<SessionManager>(() => SessionManager.instance);

 
  sl.registerLazySingleton<AuthApiClient>(
    () => AuthApiClient(sl<Dio>(instanceName: 'authenticated')),
  );

  // Initialize Token Refresh Service
  TokenRefreshService.initialize(sl<AuthApiClient>());
  sl.registerLazySingleton<TokenRefreshService>(
    () => TokenRefreshService.instance,
  );

  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthApiClient>(), sl<SessionManager>()),
  );

  // ===== DOMAIN LAYER (USE CASES) =====

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

  // ===== PRESENTATION LAYER (VIEW MODELS) =====

  sl.registerFactory<LoginViewModel>(() => LoginViewModel(sl<SignInUseCase>()));

  sl.registerFactory<RegisterViewModel>(
    () => RegisterViewModel(sl<SignUpUseCase>()),
  );

  sl.registerLazySingleton<AuthStateViewModel>(
    () => AuthStateViewModel(
      sl<GetCurrentUserUseCase>(),
      sl<SignOutUseCase>(),
      sl<SessionManager>(),
    ),
  );

  print('[AuthDI]  Dependencias de autenticación registradas');
}
