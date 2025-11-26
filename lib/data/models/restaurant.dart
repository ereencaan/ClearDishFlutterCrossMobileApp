import 'package:equatable/equatable.dart';

/// Restaurant model
///
/// Represents a restaurant with basic information.
class Restaurant extends Equatable {
  const Restaurant({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.lat,
    this.lng,
    this.visible = true,
    this.createdAt,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final double? lat;
  final double? lng;
  final bool visible;
  final DateTime? createdAt;
  final double? distanceMeters;

  /// Creates Restaurant from Supabase map
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      visible: (map['visible'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
    );
  }

  /// Converts Restaurant to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'visible': visible,
      'created_at': createdAt?.toIso8601String(),
      'distance_meters': distanceMeters,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, address, phone, lat, lng, visible, createdAt, distanceMeters];
}
