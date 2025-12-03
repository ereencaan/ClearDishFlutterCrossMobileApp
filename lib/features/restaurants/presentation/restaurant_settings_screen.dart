import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/data/sources/postcode_api.dart';
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

  Future<bool> saveAddress({
    required String address,
    String? phone,
    double? lat,
    double? lng,
  }) async {
    if (state.restaurantId == null) return false;
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
      return true;
    } else {
      state =
          state.copyWith(isLoading: false, error: (result as Failure).message);
      return false;
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
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    if (state.restaurantId == null) return;
    await _api.createPromotion(
      restaurantId: state.restaurantId!,
      title: title,
      description: description,
      percentOff: percentOff,
      startsAt: startsAt,
      endsAt: endsAt,
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
  final _postcodeCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _promoTitleCtrl = TextEditingController();
  final _promoDescCtrl = TextEditingController();
  final _promoPercentCtrl = TextEditingController(text: '10');
  final _postcodeApi = PostcodeApi();
  DateTime _promoStart = DateTime.now();
  DateTime _promoEnd = DateTime.now().add(const Duration(days: 7));

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Address & Location',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _postcodeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'UK Postcode',
                              hintText: 'e.g. E1 6AN',
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonal(
                          onPressed: () async {
                            final res =
                                await _postcodeApi.lookup(_postcodeCtrl.text);
                            if (!mounted) return;
                            if (res is Success) {
                              final data = (res as Success<PostcodeLookup>).data;
                              _addressCtrl.text = data.suggestedAddress;
                              _latCtrl.text = data.lat.toStringAsFixed(6);
                              _lngCtrl.text = data.lng.toStringAsFixed(6);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Found ${data.postcode} → ${data.suggestedAddress}'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text((res as Failure).message),
                                ),
                              );
                            }
                          },
                          child: const Text('Find address'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lat',
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lngCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lng',
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: state.restaurantId == null
                          ? null
                          : () async {
                              final lat =
                                  double.tryParse(_latCtrl.text.trim());
                              final lng =
                                  double.tryParse(_lngCtrl.text.trim());
                              final ok = await controller.saveAddress(
                                address: _addressCtrl.text.trim(),
                                phone: _phoneCtrl.text.trim().isEmpty
                                    ? null
                                    : _phoneCtrl.text.trim(),
                                lat: lat,
                                lng: lng,
                              );
                              if (!mounted) return;
                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Saved')),
                                );
                              } else {
                                final err =
                                    ref.read(_settingsProvider).error ??
                                        'Failed to save';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)),
                                );
                              }
                            },
                      child: const Text('Save Address & Location'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Badges',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (!mounted) return;
                            context.push('/home/restaurant/badges/new',
                                extra: {'type': 'weekly'});
                          },
                          child: const Text('Add Weekly Badge'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (!mounted) return;
                            context.push('/home/restaurant/badges/new',
                                extra: {'type': 'monthly'});
                          },
                          child: const Text('Add Monthly Badge'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Promotions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promoTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promoDescCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _promoStart,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 1)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _promoStart = picked);
                                if (_promoEnd.isBefore(_promoStart)) {
                                  setState(() => _promoEnd =
                                      _promoStart.add(const Duration(days: 7)));
                                }
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Starts: ${_promoStart.toLocal().toString().split(' ').first}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _promoEnd,
                                firstDate: _promoStart,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                setState(() => _promoEnd = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              'Ends: ${_promoEnd.toLocal().toString().split(' ').first}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promoPercentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Percent off (0-100)',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final percent =
                            double.tryParse(_promoPercentCtrl.text.trim()) ??
                                0;
                        await controller.createPromotion(
                          title: _promoTitleCtrl.text.trim(),
                          description: _promoDescCtrl.text.trim().isEmpty
                              ? null
                              : _promoDescCtrl.text.trim(),
                          percentOff: percent,
                          startsAt: _promoStart,
                          endsAt: _promoEnd,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Promotion created')),
                        );
                      },
                      child: const Text('Create Promotion'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (state.error != null)
              Text(state.error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
