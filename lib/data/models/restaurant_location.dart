import 'package:equatable/equatable.dart';

class RestaurantLocation extends Equatable {
  const RestaurantLocation({
    required this.id,
    required this.restaurantId,
    required this.address,
    this.label,
    this.phone,
    this.lat,
    this.lng,
    this.isPrimary = false,
    this.createdAt,
  });

  final String id;
  final String restaurantId;
  final String address;
  final String? label;
  final String? phone;
  final double? lat;
  final double? lng;
  final bool isPrimary;
  final DateTime? createdAt;

  factory RestaurantLocation.fromMap(Map<String, dynamic> map) {
    return RestaurantLocation(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      address: map['address'] as String,
      label: map['label'] as String?,
      phone: map['phone'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      isPrimary: (map['is_primary'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'restaurant_id': restaurantId,
      'label': label,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'is_primary': isPrimary,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'is_primary': isPrimary,
    };
  }

  @override
  List<Object?> get props =>
      [id, restaurantId, address, label, phone, lat, lng, isPrimary, createdAt];
}

