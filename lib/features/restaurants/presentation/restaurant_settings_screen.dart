import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _settingsProvider =
    StateNotifierProvider<_SettingsController, _SettingsState>((ref) {
  return _SettingsController(RestaurantSettingsApi(SupabaseClient.instance));
});

class _SettingsState {
  const _SettingsState({
    this.isLoading = false,
    this.error,
    this.restaurantId,
    this.address,
    this.phone,
    this.lat,
    this.lng,
  });
  final bool isLoading;
  final String? error;
  final String? restaurantId;
  final String? address;
  final String? phone;
  final double? lat;
  final double? lng;

  _SettingsState copyWith({
    bool? isLoading,
    String? error,
    String? restaurantId,
    String? address,
    String? phone,
    double? lat,
    double? lng,
  }) {
    return _SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      restaurantId: restaurantId ?? this.restaurantId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class _SettingsController extends StateNotifier<_SettingsState> {
  _SettingsController(this._api) : super(const _SettingsState()) {
    _load();
  }
  final RestaurantSettingsApi _api;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _api.getMyRestaurant();
    if (result is Success) {
      final r = (result as Success).data;
      state = state.copyWith(
        isLoading: false,
        restaurantId: r.id,
        address: r.address,
        phone: r.phone,
        lat: r.lat,
        lng: r.lng,
      );
    } else {
      state =
          state.copyWith(isLoading: false, error: (result as Failure).message);
    }
  }

  Future<void> saveAddress({
    required String address,
    String? phone,
    double? lat,
    double? lng,
  }) async {
    if (state.restaurantId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    final result = await _api.saveAddress(
      restaurantId: state.restaurantId!,
      address: address,
      phone: phone,
      lat: lat,
      lng: lng,
    );
    if (result is Success) {
      final r = (result as Success).data;
      state = state.copyWith(
        isLoading: false,
        address: r.address,
        phone: r.phone,
        lat: r.lat,
        lng: r.lng,
      );
    } else {
      state =
          state.copyWith(isLoading: false, error: (result as Failure).message);
    }
  }

  Future<void> createWeeklyBadge() async {
    if (state.restaurantId == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    await _api.createBadge(
      restaurantId: state.restaurantId!,
      type: 'weekly',
      periodStart: start,
      periodEnd: end,
    );
  }

  Future<void> createMonthlyBadge() async {
    if (state.restaurantId == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end =
        DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    await _api.createBadge(
      restaurantId: state.restaurantId!,
      type: 'monthly',
      periodStart: start,
      periodEnd: end,
    );
  }

  Future<void> createPromotion({
    required String title,
    String? description,
    required double percentOff,
  }) async {
    if (state.restaurantId == null) return;
    await _api.createPromotion(
      restaurantId: state.restaurantId!,
      title: title,
      description: description,
      percentOff: percentOff,
    );
  }
}

class RestaurantSettingsScreen extends ConsumerStatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  ConsumerState<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState
    extends ConsumerState<RestaurantSettingsScreen> {
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _promoTitleCtrl = TextEditingController();
  final _promoDescCtrl = TextEditingController();
  final _promoPercentCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _promoTitleCtrl.dispose();
    _promoDescCtrl.dispose();
    _promoPercentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_settingsProvider);
    final controller = ref.read(_settingsProvider.notifier);

    if (state.isLoading && state.restaurantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Prefill once
    if (_addressCtrl.text.isEmpty && state.address != null)
      _addressCtrl.text = state.address!;
    if (_phoneCtrl.text.isEmpty && state.phone != null)
      _phoneCtrl.text = state.phone!;
    if (_latCtrl.text.isEmpty && state.lat != null)
      _latCtrl.text = state.lat!.toStringAsFixed(6);
    if (_lngCtrl.text.isEmpty && state.lng != null)
      _lngCtrl.text = state.lng!.toStringAsFixed(6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Settings'),
        leading: const AppBackButton(
          fallbackRoute: '/home/restaurants',
        ),
      ),
      body: state.restaurantId == null && state.error != null
          ? _NoRestaurantPanel(onCreate: () async {
              // quick create dialog
              final nameCtrl = TextEditingController();
              final addrCtrl = TextEditingController();
              final phoneCtrl = TextEditingController();
              await showDialog(
                context: context,
                builder: (context) {
                  bool saving = false;
                  return StatefulBuilder(builder: (context, setSt) {
                    Future<void> _save() async {
                      if (saving) return;
                      setSt(() => saving = true);
                      final api = RestaurantSettingsApi(SupabaseClient.instance);
                      final res = await api.createRestaurantWithOwner(
                        name: nameCtrl.text.trim().isEmpty
                            ? 'My Restaurant'
                            : nameCtrl.text.trim(),
                        address: addrCtrl.text.trim().isEmpty
                            ? 'Address not set'
                            : addrCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                      );
                      setSt(() => saving = false);
                      if (!context.mounted) return;
                      if (res.isFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                res.errorOrNull ?? 'Failed to create restaurant'),
                            backgroundColor: Colors.red));
                        return;
                      }
                      Navigator.of(context).pop();
                      // reload
                      controller._load();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restaurant created')));
                    }

                    return AlertDialog(
                      title: const Text('Create your restaurant'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                          ),
                          TextField(
                            controller: addrCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Address'),
                          ),
                          TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Phone (optional)'),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: saving ? null : _save,
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Create'),
                        ),
                      ],
                    );
                  });
                },
              );
            })
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Address & Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
            ),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(labelText: 'Lat'))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(labelText: 'Lng'))),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: state.restaurantId == null
                  ? null
                  : () async {
                      final lat = double.tryParse(_latCtrl.text.trim());
                      final lng = double.tryParse(_lngCtrl.text.trim());
                      await controller.saveAddress(
                        address: _addressCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim().isEmpty
                            ? null
                            : _phoneCtrl.text.trim(),
                        lat: lat,
                        lng: lng,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Saved')));
                    },
              child: const Text('Save Address & Location'),
            ),
            const Divider(height: 32),
            const Text('Badges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                    onPressed: controller.createWeeklyBadge,
                    child: const Text('Add Weekly Badge')),
                ElevatedButton(
                    onPressed: controller.createMonthlyBadge,
                    child: const Text('Add Monthly Badge')),
              ],
            ),
            const Divider(height: 32),
            const Text('Promotions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: _promoTitleCtrl,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: _promoDescCtrl,
                decoration: const InputDecoration(labelText: 'Description')),
            TextField(
                controller: _promoPercentCtrl,
                decoration:
                    const InputDecoration(labelText: 'Percent off (0-100)')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final percent =
                    double.tryParse(_promoPercentCtrl.text.trim()) ?? 0;
                await controller.createPromotion(
                  title: _promoTitleCtrl.text.trim(),
                  description: _promoDescCtrl.text.trim().isEmpty
                      ? null
                      : _promoDescCtrl.text.trim(),
                  percentOff: percent,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion created')));
              },
              child: const Text('Create Promotion'),
            ),
            const SizedBox(height: 32),
            if (state.error != null)
              Text(state.error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _NoRestaurantPanel extends StatelessWidget {
  const _NoRestaurantPanel({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 56),
            const SizedBox(height: 12),
            const Text(
              'No restaurant assigned to this account',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_business),
              label: const Text('Create my restaurant'),
            )
          ],
        ),
      ),
    );
  }
}
