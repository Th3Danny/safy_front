import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/auth/presentation/pages/login/login_screen.dart';
import 'package:safy/auth/presentation/pages/register/register_screen_01.dart';
import 'package:safy/auth/presentation/pages/register/register_screen_02.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/help/presentation/pages/help_institutions_screen.dart';
import 'package:safy/help/presentation/pages/safety_education_screen.dart';
import 'package:safy/home/presentation/pages/home_screen.dart';
import 'package:safy/profil/presentation/pages/edit_profile_screen.dart';
import 'package:safy/report/presentation/pages/create_report_screen.dart';
import 'package:safy/report/presentation/pages/report_detail_screen.dart';
import 'package:safy/report/presentation/pages/view_report_screen.dart'; // Asegúrate de tener este import si usas MyReportsScreen
import 'package:safy/settings/presentation/pages/settings_screen.dart';

final _routerKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _routerKey,
    debugLogDiagnostics: true,

    redirect: (BuildContext context, GoRouterState state) async {
      // ✅ IMPORTANTE: Esperar a que SessionManager se inicialice
      // Aunque initialize() ya se llama en main, GoRouter redirect puede ejecutarse antes.
      // Aseguramos que la instancia de SessionManager esté lista.
      await SessionManager.instance.initialize(); // Asegura que esté inicializado

      final routesNonSecure = [
        AppRoutesConstant.login,
        AppRoutesConstant.register,
        AppRoutesConstant.registerStep2,
        
      ];

      try {
        final sessionManager = SessionManager.instance;
        final isLoggedIn = sessionManager.isLoggedIn;
        final isNonSecure = routesNonSecure.contains(state.matchedLocation);

        print('[Router] Ruta: ${state.matchedLocation}, LoggedIn: $isLoggedIn, NonSecure: $isNonSecure');

        // Si la ruta actual es la raíz y aún no se ha inicializado el AuthStateViewModel
        // Permitimos que AuthWrapper maneje la navegación inicial
        if (state.matchedLocation == '/' && !GetIt.instance<AuthStateViewModel>().isLoading) {
            // No redirigimos aquí, dejamos que AuthWrapper decida.
            // La condición !GetIt.instance<AuthStateViewModel>().isLoading es para evitar un loop
            // si el redirect se dispara múltiples veces antes de que AuthWrapper termine.
            return null;
        }


        // Si no está logueado y trata de acceder a ruta protegida
        if (!isLoggedIn && !isNonSecure) {
          print('[Router] Redirigiendo a login - no autenticado');
          return AppRoutesConstant.login;
        }

        // Si está logueado y trata de acceder a login/register o la ruta raíz
        if (isLoggedIn && (state.matchedLocation == AppRoutesConstant.login ||
                            state.matchedLocation == AppRoutesConstant.register ||
                            state.matchedLocation == '/')) {
          print('[Router] Redirigiendo a home - ya autenticado');
          return AppRoutesConstant.home;
        }

        return null; // No redirigir
      } catch (e) {
        print('[Router] Error en redirect: $e');
        // En caso de error, siempre redirigir al login
        return AppRoutesConstant.login;
      }
    },

    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuthWrapper(), // Tu splash screen/wrapper de autenticación
        ),
      ),

      // Tus rutas existentes
      GoRoute(
        path: AppRoutesConstant.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.register,
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterScreen01(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.registerStep2,
        name: 'register-step2',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: RegisterScreen02(
            registerData: state.extra as Map<String, dynamic>?,
          ),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.createReport,
        name: 'create-report',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CreateReportScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.myReports,
        name: 'my-reports',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MyReportsScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.reportDetail,
        name: 'report-detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final reportId = extra?['reportId'] as String?;

          if (reportId == null) {
            return MaterialPage(
              key: state.pageKey,
              child: Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('ID de reporte no válido'),
                ),
              ),
            );
          }

          return MaterialPage(
            key: state.pageKey,
            child: ReportDetailScreen(reportId: reportId),
          );
        },
      ),

      GoRoute(
        path: AppRoutesConstant.helpInstitutions,
        name: 'help-institutions',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HelpInstitutionsScreen(),
        ),
      ),

       GoRoute(
        path: AppRoutesConstant.guideSecurity,
        name: 'guide-security',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SafetyEducationScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutesConstant.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],

    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.matchedLocation}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ✅ MANTÉN ESTA CLASE SIN CAMBIOS
// AuthWrapper para manejar el estado inicial
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthStateViewModel _authViewModel;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      _authViewModel = GetIt.instance<AuthStateViewModel>();
      _authViewModel.addListener(_onAuthChanged);
      
      // Aquí se llama a initialize, que carga la sesión del SessionManager
      await _authViewModel.initialize(); 
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _checkAuthAndNavigate();
      }
    } catch (e) {
      print('[AuthWrapper] Error inicializando: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        context.go(AppRoutesConstant.login);
      }
    }
  }

  void _onAuthChanged() {
    if (mounted) {
      _checkAuthAndNavigate();
    }
  }

  void _checkAuthAndNavigate() {
    if (!_isInitialized) return;
    
    // Usamos addPostFrameCallback para asegurar que el build del widget ha terminado
    // antes de intentar la navegación, evitando errores de navegación temprana.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_authViewModel.isLoggedIn && _authViewModel.currentUser != null) {
          context.go(AppRoutesConstant.home);
        } else {
          context.go(AppRoutesConstant.login);
        }
      }
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _authViewModel.removeListener(_onAuthChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.security,
                size: 40,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Safy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zonas Seguras',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificando sesión...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}