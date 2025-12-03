import 'package:go_router/go_router.dart';
import 'package:cleardish/features/auth/presentation/login_screen.dart';
import 'package:cleardish/features/auth/presentation/register_screen.dart';
import 'package:cleardish/features/auth/models/auth_role.dart';
import 'package:cleardish/features/auth/presentation/welcome_screen.dart';
import 'package:cleardish/features/home/presentation/home_shell.dart';
import 'package:cleardish/features/restaurants/presentation/restaurants_screen.dart';
import 'package:cleardish/features/restaurants/presentation/restaurant_detail_screen.dart';
import 'package:cleardish/features/menu/presentation/menu_screen.dart';
import 'package:cleardish/features/profile/presentation/profile_screen.dart';
import 'package:cleardish/features/subscription/presentation/subscription_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleardish/features/restaurants/presentation/nearby_restaurants_screen.dart';
import 'package:cleardish/features/restaurants/presentation/restaurant_settings_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_profile_requests_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_users_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_activity_screen.dart';
import 'package:cleardish/features/common/presentation/loading_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_restaurants_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_restaurant_form_screen.dart';
import 'package:cleardish/features/admin/presentation/admin_menu_items_screen.dart';
import 'package:cleardish/features/restaurants/presentation/restaurant_badge_form_screen.dart';
import 'package:cleardish/features/restaurants/presentation/owner_badge_rules_screen.dart';
import 'package:cleardish/features/profile/presentation/my_badges_screen.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/features/restaurants/presentation/restaurant_setup_screen.dart';

/// Application router configuration
///
/// Handles navigation and route management using go_router.
final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login/user',
        name: 'login-user',
        builder: (context, state) => const LoginScreen(role: AuthRole.user),
      ),
      GoRoute(
        path: '/login/restaurant',
        name: 'login-restaurant',
        builder: (context, state) =>
            const LoginScreen(role: AuthRole.restaurant),
      ),
      GoRoute(
        path: '/login/admin',
        name: 'login-admin',
        builder: (context, state) => const LoginScreen(role: AuthRole.admin),
      ),
      GoRoute(
        path: '/register/user',
        name: 'register-user',
        builder: (context, state) => const RegisterScreen(role: AuthRole.user),
      ),
      GoRoute(
        path: '/register/restaurant',
        name: 'register-restaurant',
        builder: (context, state) =>
            const RegisterScreen(role: AuthRole.restaurant),
      ),
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/approvals',
        name: 'admin-approvals',
        builder: (context, state) => const AdminProfileRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/activity',
        name: 'admin-activity',
        builder: (context, state) => const AdminActivityScreen(),
      ),
      GoRoute(
        path: '/admin/restaurants',
        name: 'admin-restaurants',
        builder: (context, state) => const AdminRestaurantsScreen(),
      ),
      GoRoute(
        path: '/admin/menu-items',
        name: 'admin-menu-items',
        builder: (context, state) => const AdminMenuItemsScreen(),
      ),
      GoRoute(
        path: '/admin/restaurants/new',
        name: 'admin-restaurant-new',
        builder: (context, state) => const AdminRestaurantFormScreen(),
      ),
      GoRoute(
        path: '/admin/restaurants/:id/edit',
        name: 'admin-restaurant-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // Pass minimal model; the edit screen expects the id and will submit with it
          return AdminRestaurantFormScreen(
            restaurant: Restaurant(
              id: id,
              name: '',
              visible: true,
              address: null,
              phone: null,
              lat: null,
              lng: null,
              createdAt: null,
              distanceMeters: null,
            ),
          );
        },
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
            path: '/home/nearby',
            name: 'nearby',
            builder: (context, state) => const NearbyRestaurantsScreen(),
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
            path: '/home/restaurant/settings',
            name: 'restaurant-settings',
            builder: (context, state) => const RestaurantSettingsScreen(),
          ),
          GoRoute(
            path: '/home/restaurant/setup',
            name: 'restaurant-setup',
            builder: (context, state) => const RestaurantSetupScreen(),
          ),
          GoRoute(
            path: '/home/restaurant/badges/new',
            name: 'restaurant-badge-new',
            builder: (context, state) {
              // Support navigation via pushNamed with arguments map
              final arg = state.extra;
              String? type;
              if (arg is Map && arg['type'] is String) {
                type = arg['type'] as String;
              }
              return RestaurantBadgeFormScreen(initialType: type);
            },
          ),
          GoRoute(
            path: '/home/restaurant/badges/rules',
            name: 'restaurant-badge-rules',
            builder: (context, state) => const OwnerBadgeRulesScreen(),
          ),
          GoRoute(
            path: '/home/my-badges',
            name: 'my-badges',
            builder: (context, state) => const MyBadgesScreen(),
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
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isOnAuthScreen = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      // If not logged in and not on auth screen, redirect to login
      if (!isLoggedIn && !isOnAuthScreen) {
        return '/welcome';
      }

      // If logged in and on auth screen, redirect by role
      if (isLoggedIn && isOnAuthScreen) {
        final role = Supabase
            .instance.client.auth.currentUser?.userMetadata?['role'] as String?;
        if (role == 'admin') {
          return '/admin';
        }
        return '/home';
      }

      return null;
    },
  );
}
