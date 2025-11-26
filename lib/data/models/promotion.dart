import 'package:equatable/equatable.dart';

class Promotion extends Equatable {
  const Promotion({
    required this.id,
    required this.restaurantId,
    required this.title,
    this.description,
    required this.percentOff,
    required this.startsAt,
    required this.endsAt,
    this.userId,
    this.active = true,
  });

  final String id;
  final String restaurantId;
  final String title;
  final String? description;
  final double percentOff;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? userId;
  final bool active;

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      percentOff: (map['percent_off'] as num).toDouble(),
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: DateTime.parse(map['ends_at'] as String),
      userId: map['user_id'] as String?,
      active: (map['active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'title': title,
      'description': description,
      'percent_off': percentOff,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'user_id': userId,
      'active': active,
    };
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        title,
        description,
        percentOff,
        startsAt,
        endsAt,
        userId,
        active,
      ];
}
