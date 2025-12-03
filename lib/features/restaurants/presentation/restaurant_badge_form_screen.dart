import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_back_button.dart';

class RestaurantBadgeFormScreen extends ConsumerStatefulWidget {
  const RestaurantBadgeFormScreen({super.key, this.initialType});
  final String? initialType; // 'weekly' | 'monthly'

  @override
  ConsumerState<RestaurantBadgeFormScreen> createState() =>
      _RestaurantBadgeFormScreenState();
}

class _RestaurantBadgeFormScreenState
    extends ConsumerState<RestaurantBadgeFormScreen> {
  late final RestaurantSettingsApi _api;

  String _type = 'weekly';
  DateTime _start = _mondayOfCurrentWeek();
  DateTime _end = _mondayOfCurrentWeek().add(const Duration(days: 6));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _api = RestaurantSettingsApi(SupabaseClient.instance);
    if (widget.initialType == 'monthly') {
      _type = 'monthly';
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, 1);
      _end = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));
    }
  }

  static DateTime _mondayOfCurrentWeek() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday - 1)));
    return monday;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (_end.isBefore(_start)) {
          _end = _start;
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _end = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    // Resolve current restaurant id
    final me = await _api.getMyRestaurant();
    if (me is Failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text((me as Failure).message)));
      }
      setState(() => _saving = false);
      return;
    }
    final restId = (me as Success).data.id;
    final res = await _api.createBadge(
      restaurantId: restId,
      type: _type,
      periodStart: _start,
      periodEnd: _end,
    );
    setState(() => _saving = false);
    if (mounted) {
      if (res is Success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Badge created for ${_format(_start)} – ${_format(_end)}')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res as Failure).message)),
        );
      }
    }
  }

  String _format(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Badge'),
        leading: const AppBackButton(fallbackRoute: '/home/restaurant/settings'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What is a badge?',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Badges highlight your restaurant in lists and on your profile '
                      'for a selected time window. Use them to promote weekly or monthly '
                      'achievements (e.g., “Top Rated This Week”) or campaigns (e.g., '
                      '“January Vegan Specials”).',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose weekly or monthly, set the dates, and we’ll highlight your place '
                      'during that period. Badges automatically expire at the end date.',
                      style: TextStyle(color: Colors.white70),
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
                    const Text('Badge options',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'weekly', label: Text('Weekly')),
                        ButtonSegment(value: 'monthly', label: Text('Monthly')),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) {
                        setState(() {
                          _type = s.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickStart,
                            icon: const Icon(Icons.calendar_today),
                            label: Text('Start: ${_format(_start)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickEnd,
                            icon: const Icon(Icons.calendar_month),
                            label: Text('End: ${_format(_end)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Badge'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
