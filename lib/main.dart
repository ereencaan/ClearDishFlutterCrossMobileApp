import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/core/routing/app_router.dart';
import 'package:cleardish/core/theme/app_theme.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/src/screenshot_env_io.dart'
    if (dart.library.html) 'package:cleardish/src/screenshot_env_stub.dart' as screenshot_env;

/// Application entry point.
/// For screenshot workflows (e.g. CI), set INITIAL_LOCATION to open a specific route.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseClient.initialize();

  final initialLocation =
      screenshot_env.getInitialLocationFromEnv() ?? '/welcome';
  final router = AppRouter.createRouter(initialLocation: initialLocation);

  runApp(
    ProviderScope(
      child: ClearDishApp(router: router),
    ),
  );
}

/// Main application widget
class ClearDishApp extends StatelessWidget {
  const ClearDishApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClearDish',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
