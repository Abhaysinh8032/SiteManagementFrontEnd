import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/network/app_router.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Wire up dependencies ────────────────────────────────────────────────
  final storage        = SecureStorageService();
  ApiClient.instance.init(storage);                        // init Dio with storage
  final authRepository = AuthRepository(storage: storage);
  final appRouter      = AppRouter(storage);

  runApp(SiteTrackerApp(
    authRepository: authRepository,
    appRouter:      appRouter,
  ));
}

class SiteTrackerApp extends StatelessWidget {
  final AuthRepository authRepository;
  final AppRouter      appRouter;

  const SiteTrackerApp({
    super.key,
    required this.authRepository,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(repository: authRepository)
            // Immediately check for a saved token on launch
            ..add(const AuthCheckSessionRequested()),
        ),
        // Add more BlocProviders here as you build Cycle 2 features:
        // BlocProvider<SiteBloc>(create: (_) => SiteBloc(...)),
        // BlocProvider<TaskBloc>(create: (_) => TaskBloc(...)),
      ],
      child: MaterialApp.router(
        title:              'SiteTracker',
        debugShowCheckedModeBanner: false,
        theme:              AppTheme.light,
        routerConfig:       appRouter.router,
      ),
    );
  }
}
