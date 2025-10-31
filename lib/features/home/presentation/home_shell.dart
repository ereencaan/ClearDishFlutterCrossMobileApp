import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home shell with bottom navigation
/// 
/// Provides navigation structure for the main app screens.
class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.child,
    super.key,
  });

  final Widget child;

  void _onTap(BuildContext context, String route) {
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(currentLocation),
        onTap: (index) {
          switch (index) {
            case 0:
              _onTap(context, '/home/restaurants');
              break;
            case 1:
              _onTap(context, '/home/profile');
              break;
            case 2:
              _onTap(context, '/home/subscription');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Subscription',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith('/home/restaurants')) {
      return 0;
    } else if (location.startsWith('/home/profile')) {
      return 1;
    } else if (location.startsWith('/home/subscription')) {
      return 2;
    }
    return 0;
  }
}

