import 'package:go_router/go_router.dart';
import 'package:cleardish/features/auth/presentation/login_screen.dart';
import 'package:cleardish/features/auth/presentation/register_screen.dart';
import 'package:cleardish/features/onboarding/presentation/onboarding_screen.dart';
import 'package:cleardish/features/home/presentation/home_shell.dart';
import 'package:cleardish/features/restaurants/presentation/restaurants_screen.dart';
import 'package:cleardish/features/restaurants/presentation/restaurant_detail_screen.dart';
import 'package:cleardish/features/menu/presentation/menu_screen.dart';
import 'package:cleardish/features/profile/presentation/profile_screen.dart';
import 'package:cleardish/features/subscription/presentation/subscription_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Application router configuration
///
/// Handles navigation and route management using go_router.
final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            redirect: (context, state) => '/home/restaurants',
          ),
          GoRoute(
            path: '/home/restaurants',
            name: 'restaurants',
            builder: (context, state) => const RestaurantsScreen(),
          ),
          GoRoute(
            path: '/home/restaurants/:id',
            name: 'restaurant-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RestaurantDetailScreen(restaurantId: id);
            },
          ),
          GoRoute(
            path: '/home/menu/:restaurantId',
            name: 'menu',
            builder: (context, state) {
              final restaurantId = state.pathParameters['restaurantId']!;
              return MenuScreen(restaurantId: restaurantId);
            },
          ),
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/home/subscription',
            name: 'subscription',
            builder: (context, state) => const SubscriptionScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = supabase.Supabase.instance.client.auth.currentUser != null;
      final isOnAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // If not logged in and not on auth screen, redirect to login
      if (!isLoggedIn && !isOnAuthScreen && !isOnOnboarding) {
        return '/login';
      }

      // If logged in and on auth screen, redirect to home
      if (isLoggedIn && isOnAuthScreen) {
        return '/home';
      }

      return null;
    },
  );
}
