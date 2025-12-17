import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cleardish/data/sources/analytics_api.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(SupabaseClient.instance);
});

final _loginSeriesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(_analyticsApiProvider).loginsByDay(days: 30);
});

final _searchSeriesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(_analyticsApiProvider).searchesByDay(days: 30);
});

final _topRestaurantsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(_analyticsApiProvider).topRestaurants(limit: 10);
});

final _topUsersProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(_analyticsApiProvider).topUsers(limit: 10);
});

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginSeries = ref.watch(_loginSeriesProvider);
    final searchSeries = ref.watch(_searchSeriesProvider);
    final topRestaurants = ref.watch(_topRestaurantsProvider);
    final topUsers = ref.watch(_topUsersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin'),
        title: const Text('Activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Logins (last 30 days)'),
          _SeriesCard(seriesAsync: loginSeries),
          const SizedBox(height: 16),
          const _SectionTitle('Searches (last 30 days)'),
          _SeriesCard(seriesAsync: searchSeries, color: Colors.orange),
          const SizedBox(height: 16),
          const _SectionTitle('Top Restaurants'),
          _TopListCard(entriesAsync: topRestaurants),
          const SizedBox(height: 16),
          const _SectionTitle('Top Users'),
          _TopListCard(entriesAsync: topUsers),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.seriesAsync, this.color});
  final AsyncValue<Result<List<TimePoint>>> seriesAsync;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 220,
          child: seriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed: $e')),
            data: (res) {
              if (res.isFailure) return Center(child: Text(res.errorOrNull ?? 'Error'));
              final pts = res.dataOrNull ?? const <TimePoint>[];
              if (pts.isEmpty) return const Center(child: Text('No data'));
              final spots = <FlSpot>[];
              for (int i = 0; i < pts.length; i++) {
                spots.add(FlSpot(i.toDouble(), pts[i].value.toDouble()));
              }
              return LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color ?? Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopListCard extends StatelessWidget {
  const _TopListCard({required this.entriesAsync});
  final AsyncValue<Result<List<TopEntry>>> entriesAsync;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: entriesAsync.when(
        loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed: $e'),
        ),
        data: (res) {
          if (res.isFailure) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(res.errorOrNull ?? 'Error'),
            );
          }
          final entries = res.dataOrNull ?? const <TopEntry>[];
          if (entries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No data'),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                title: Text(e.label),
                trailing: Text(e.value.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
