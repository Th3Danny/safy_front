import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:safy/report/presentation/pages/view_report_screen.dart';
import 'package:safy/settings/presentation/pages/settings_screen.dart';

final _routerKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _routerKey,
    debugLogDiagnostics: true,

    redirect: (BuildContext context, GoRouterState state) {
      final routesNonSecure = [
        AppRoutesConstant.login,
        AppRoutesConstant.register,
        AppRoutesConstant.registerStep2,
      ];

      try {
        final sessionManager = SessionManager.instance;
        final isLoggedIn = sessionManager.isLoggedIn;
        final isNonSecure = routesNonSecure.contains(state.matchedLocation);

        print('[Router] 🔍 Ruta: ${state.matchedLocation}');
        print('[Router] 🔍 LoggedIn: $isLoggedIn');
        print('[Router] 🔍 NonSecure: $isNonSecure');

        // 🔧 CAMBIO: Permitir AuthWrapper manejar la navegación inicial
        if (state.matchedLocation == '/') {
          print('[Router] 🏠 AuthWrapper manejará la navegación');
          return null;
        }

        // 🔧 CAMBIO: Solo redirigir si realmente no hay sesión válida
        if (!isLoggedIn && !isNonSecure) {
          print('[Router] 🚫 Redirigiendo a login - no autenticado');
          return AppRoutesConstant.login;
        }

        // 🔧 CAMBIO: Solo redirigir si hay sesión válida Y está en login
        if (isLoggedIn && state.matchedLocation == AppRoutesConstant.login) {
          print('[Router] ✅ Redirigiendo a home - ya autenticado');
          return AppRoutesConstant.home;
        }

        print('[Router] ✅ No redirect necesario');
        return null;
      } catch (e) {
        print('[Router] ❌ Error en redirect: $e');
        // 🔧 CAMBIO: No redirigir en caso de error de red
        return null;
      }
    },

    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const AuthWrapper()),
      ),

      GoRoute(
        path: AppRoutesConstant.login,
        name: 'login',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),

      GoRoute(
        path: AppRoutesConstant.register,
        name: 'register',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const RegisterScreen01(),
            ),
      ),

      GoRoute(
        path: AppRoutesConstant.registerStep2,
        name: 'register-step2',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: RegisterScreen02(
                registerData: state.extra as Map<String, dynamic>?,
              ),
            ),
      ),

      GoRoute(
        path: AppRoutesConstant.home,
        name: 'home',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const HomeScreen()),
      ),

      GoRoute(
        path: AppRoutesConstant.createReport,
        name: 'create-report',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: CreateReportScreen(extraData: extra),
          );
        },
      ),

      GoRoute(
        path: AppRoutesConstant.myReports,
        name: 'my-reports',
        pageBuilder:
            (context, state) => MaterialPage(
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
                body: const Center(child: Text('ID de reporte no válido')),
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
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const HelpInstitutionsScreen(),
            ),
      ),

      GoRoute(
        path: AppRoutesConstant.guideSecurity,
        name: 'guide-security',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SafetyEducationScreen(),
            ),
      ),

      GoRoute(
        path: AppRoutesConstant.editProfile,
        name: 'edit-profile',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const EditProfileScreen(),
            ),
      ),

      GoRoute(
        path: AppRoutesConstant.settings,
        name: 'settings',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const SettingsScreen()),
      ),
    ],

    errorPageBuilder:
        (context, state) => MaterialPage(
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

// AUTHWRAPPER MEJORADO
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    print('[AuthWrapper] 🚀 Verificando navegación...');

    // Usar WidgetsBinding para asegurar que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasNavigated) return;

      final sessionManager = SessionManager.instance;
      print(
        '[AuthWrapper] 🔍 SessionManager isLoggedIn: ${sessionManager.isLoggedIn}',
      );

      if (sessionManager.isLoggedIn) {
        print('[AuthWrapper] ✅ Navegando a home - sesión válida');
        _hasNavigated = true;
        context.go(AppRoutesConstant.home);
      } else {
        print('[AuthWrapper] 🚫 Navegando a login - sin sesión');
        _hasNavigated = true;
        context.go(AppRoutesConstant.login);
      }
    });
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
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificando sesión...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
