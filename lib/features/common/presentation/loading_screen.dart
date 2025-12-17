import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A soft, modern loading screen shown briefly after login for all roles.
///
/// It reads the current user's role from Supabase and forwards to the
/// appropriate destination after a short delay.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _forward();
  }

  Future<void> _forward() async {
    // Small delay for a pleasant transition and to allow any initial fetches.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String?;

    // If role is 'user', ensure profile is initialized; otherwise skip onboarding
    if (role == 'user' && user != null) {
      try {
        final profile = await client
            .from('user_profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        bool hasAnyData = false;
        if (profile != null) {
          hasAnyData = ((profile['full_name'] as String?)?.isNotEmpty == true) ||
              ((profile['allergens'] as List?)?.isNotEmpty == true) ||
              ((profile['diets'] as List?)?.isNotEmpty == true);
        }
        if (!hasAnyData) {
          // Try to provision from metadata captured at sign-up
          final meta = user.userMetadata ?? {};
          final fullName = meta['full_name'] as String?;
          final address = meta['address'] as String?;
          final allergens = (meta['allergens'] as List?)?.cast<String>() ?? const <String>[];
          final diets = (meta['diets'] as List?)?.cast<String>() ?? const <String>[];
          final hasMeta = (fullName != null && fullName.isNotEmpty) ||
              (address != null && address.isNotEmpty) ||
              allergens.isNotEmpty ||
              diets.isNotEmpty;
          if (hasMeta) {
            // Upsert profile with metadata values
            await client.from('user_profiles').upsert({
              'user_id': user.id,
              if (fullName != null) 'full_name': fullName,
              if (address != null) 'address': address,
              'allergens': allergens,
              'diets': diets,
            });
            hasAnyData = true;
          }
          if (!hasAnyData) {
            context.go('/onboarding');
            return;
          }
        }
      } catch (_) {
        // On error, still allow entry to home
      }
    }

    // Ensure restaurant owner has a restaurant mapping; create if missing
    if (role == 'restaurant' && user != null) {
      try {
        final mapping = await client
            .from('restaurant_admins')
            .select('restaurant_id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (mapping == null) {
          final meta = user.userMetadata ?? {};
          final rName =
              (meta['restaurant_name'] as String?)?.trim().isNotEmpty == true
                  ? (meta['restaurant_name'] as String).trim()
                  : 'My Restaurant';
          final rAddr =
              (meta['address'] as String?)?.trim().isNotEmpty == true
                  ? (meta['address'] as String).trim()
                  : 'E2 6AU';
          await client.rpc('create_restaurant_with_owner', params: {
            'p_name': rName,
            'p_address': rAddr,
            'p_phone': null,
          });
        }
      } catch (_) {
        // ignore and continue; UI has create dialog fallback
      }
    }

    if (role == 'admin') {
      context.go('/admin');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFe8f5e9), // very light green
              Color(0xFFf1fff3), // mint tint
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing your experience...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
