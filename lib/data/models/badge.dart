import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  const Badge({
    required this.id,
    required this.restaurantId,
    required this.type, // 'weekly' | 'monthly' | other
    required this.periodStart,
    required this.periodEnd,
  });

  final String id;
  final String restaurantId;
  final String type;
  final DateTime periodStart;
  final DateTime periodEnd;

  bool get isActive {
    final now = DateTime.now().toUtc();
    return !now.isBefore(periodStart.toUtc()) && !now.isAfter(periodEnd.toUtc());
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      type: map['type'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
    );
  }

  @override
  List<Object?> get props => [id, restaurantId, type, periodStart, periodEnd];
}
