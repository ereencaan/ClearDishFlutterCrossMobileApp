import 'package:equatable/equatable.dart';

/// Restaurant model
/// 
/// Represents a restaurant with basic information.
class Restaurant extends Equatable {
  const Restaurant({
    required this.id,
    required this.name,
    this.address,
    this.visible = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? address;
  final bool visible;
  final DateTime? createdAt;

  /// Creates Restaurant from Supabase map
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      visible: (map['visible'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Converts Restaurant to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'visible': visible,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, address, visible, createdAt];
}

