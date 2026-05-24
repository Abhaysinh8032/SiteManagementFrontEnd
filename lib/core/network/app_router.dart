import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';

/// Placeholder home screens — replace with real screens in Cycle 2
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: Text('Admin Home — Coming Soon')),
      );
}

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Tasks')),
        body: const Center(child: Text('Worker Home — Coming Soon')),
      );
}

class AppRouter {
  final SecureStorageService _storage;

  AppRouter(this._storage);

  late final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeLogin,
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSignup,
        name: 'signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminHome,
        name: 'admin-home',
        builder: (_, __) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppConstants.routeWorkerHome,
        name: 'worker-home',
        builder: (_, __) => const WorkerHomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );

  /// Auto-login redirect:
  /// If a valid token exists in storage, skip the login screen entirely
  /// and redirect straight to the correct home screen based on role.
  Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    final isOnAuth = state.matchedLocation == AppConstants.routeLogin ||
        state.matchedLocation == AppConstants.routeSignup;

    // Only check token when user is on auth screens
    if (isOnAuth) {
      final token = await _storage.getValidToken();
      if (token != null) {
        final role = await _storage.getRole();
        if (role == 'ADMIN')  return AppConstants.routeAdminHome;
        if (role == 'WORKER') return AppConstants.routeWorkerHome;
      }
    }

    return null; // no redirect needed
  }
}
