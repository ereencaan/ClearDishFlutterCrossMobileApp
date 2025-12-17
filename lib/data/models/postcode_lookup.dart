import 'package:equatable/equatable.dart';

class PostcodeLookup extends Equatable {
  const PostcodeLookup({
    required this.postcode,
    required this.latitude,
    required this.longitude,
    this.country,
    this.region,
    this.adminDistrict,
  });

  final String postcode;
  final double latitude;
  final double longitude;
  final String? country;
  final String? region;
  final String? adminDistrict;

  factory PostcodeLookup.fromMap(Map<String, dynamic> map) {
    return PostcodeLookup(
      postcode: (map['postcode'] as String).toUpperCase(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      country: map['country'] as String?,
      region: map['region'] as String?,
      adminDistrict: map['admin_district'] as String?,
    );
  }

  String formattedAddress() {
    final parts = <String>[
      postcode,
      if (adminDistrict != null && adminDistrict!.isNotEmpty) adminDistrict!,
      if (region != null && region!.isNotEmpty) region!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  @override
  List<Object?> get props =>
      [postcode, latitude, longitude, country, region, adminDistrict];
}
