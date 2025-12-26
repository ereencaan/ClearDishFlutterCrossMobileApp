import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_back_button.dart';

class AdminRestaurantFormScreen extends ConsumerStatefulWidget {
  const AdminRestaurantFormScreen({super.key, this.restaurant});
  final Restaurant? restaurant;

  @override
  ConsumerState<AdminRestaurantFormScreen> createState() =>
      _AdminRestaurantFormScreenState();
}

class _AdminRestaurantFormScreenState
    extends ConsumerState<AdminRestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _visible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    if (r != null) {
      _nameCtrl.text = r.name;
      _addrCtrl.text = r.address ?? '';
      _phoneCtrl.text = r.phone ?? '';
      _latCtrl.text = r.lat?.toString() ?? '';
      _lngCtrl.text = r.lng?.toString() ?? '';
      _visible = r.visible;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(restaurantRepoProvider);
    final model = Restaurant(
      id: widget.restaurant?.id ?? '',
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      lat: _latCtrl.text.trim().isEmpty ? null : double.tryParse(_latCtrl.text),
      lng: _lngCtrl.text.trim().isEmpty ? null : double.tryParse(_lngCtrl.text),
      visible: _visible,
      createdAt: widget.restaurant?.createdAt,
      distanceMeters: null,
    );
    Result res;
    if (widget.restaurant == null) {
      res = await repo.createRestaurant(model);
    } else {
      res = await repo.updateRestaurant(model);
    }
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.isFailure
            ? (res.errorOrNull ?? 'Failed')
            : 'Saved successfully'),
      ),
    );
    if (res.isSuccess) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.restaurant != null;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin/restaurants'),
        title: Text(isEdit ? 'Edit Restaurant' : 'Add Restaurant'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _visible,
                  onChanged: (v) => setState(() => _visible = v),
                  title: const Text('Visible'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
