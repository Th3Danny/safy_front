import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/login_screen.dart';
import 'package:safy/auth/presentation/pages/register/register_screen_01.dart';
import 'package:safy/auth/presentation/pages/register/register_screen_02.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';


final _routerKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutesConstant.login,
    navigatorKey: _routerKey,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) async {
      final routesNonSecure = [
        AppRoutesConstant.login,
        AppRoutesConstant.register,
        AppRoutesConstant.registerStep2,
      ];

      // Comentado temporalmente hasta implementar SessionManager
      // final sessionManager = sl<SessionManager>();
      // final token = await sessionManager.getToken();
      // final isLoggedIn = token != null;

      // final isNonSecure = routesNonSecure.contains(state.matchedLocation);

      // if (!isLoggedIn && !isNonSecure) {
      //   return AppRoutesConstant.login;
      // }

      // if (isLoggedIn && isNonSecure) {
      //   return AppRoutesConstant.home;
      // }

      return null; // Importante retornar null si no hay redirección
    },
    routes: [
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
            // Aquí puedes pasar los datos del primer paso si es necesario
            //registerData: state.extra as Map<String, dynamic>?,
          ),
        ),
      ),
      // TODO: Agregar más rutas aquí (home, profile, etc.)
      GoRoute(
        path: AppRoutesConstant.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const Placeholder(), // Reemplazar con HomeScreen cuando esté listo
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
                onPressed: () => context.go(AppRoutesConstant.login),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}