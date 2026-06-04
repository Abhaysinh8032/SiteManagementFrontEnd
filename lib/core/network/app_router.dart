import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/data/repositories/site_repository.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

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
        path: AppConstants.routeHome,
        name: 'home',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'WORKER';
          return BlocProvider(
            create: (_) => HomeBloc(repository: SiteRepository()),
            child: HomeScreen(role: role),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );

  FutureOr<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isOnAuth =
        state.matchedLocation == AppConstants.routeLogin ||
        state.matchedLocation == AppConstants.routeSignup;

    // Only check token when user is on auth screens
    if (isOnAuth) {
      final token = await _storage.getValidToken();
      if (token != null) {
        final role = await _storage.getRole() ?? 'WORKER';
        return '${AppConstants.routeHome}?role=$role';
      }
    }

    return null; // no redirect needed
  }
}
