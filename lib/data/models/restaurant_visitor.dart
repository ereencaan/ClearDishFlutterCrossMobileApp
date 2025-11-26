import 'package:equatable/equatable.dart';

class RestaurantVisitor extends Equatable {
  const RestaurantVisitor({
    required this.visitId,
    required this.userId,
    required this.restaurantId,
    this.fullName,
    required this.visitedAt,
  });

  final String visitId;
  final String userId;
  final String restaurantId;
  final String? fullName;
  final DateTime visitedAt;

  factory RestaurantVisitor.fromMap(Map<String, dynamic> map) {
    return RestaurantVisitor(
      visitId: map['id'] as String,
      userId: map['user_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      fullName: map['full_name'] as String?,
      visitedAt: DateTime.parse(map['visited_at'] as String),
    );
  }

  RestaurantVisitor copyWith({String? fullName}) {
    return RestaurantVisitor(
      visitId: visitId,
      userId: userId,
      restaurantId: restaurantId,
      fullName: fullName ?? this.fullName,
      visitedAt: visitedAt,
    );
  }

  @override
  List<Object?> get props =>
      [visitId, userId, restaurantId, fullName, visitedAt];
}
