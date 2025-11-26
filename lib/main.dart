import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/core/routing/app_router.dart';
import 'package:cleardish/core/theme/app_theme.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

/// Application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseClient.initialize();

  runApp(
    const ProviderScope(
      child: ClearDishApp(),
    ),
  );
}

/// Main application widget
class ClearDishApp extends StatelessWidget {
  const ClearDishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClearDish',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
