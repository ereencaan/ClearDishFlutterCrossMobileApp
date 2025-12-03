import 'package:dio/dio.dart';
import 'package:cleardish/core/utils/result.dart';

class PostcodeLookup {
  PostcodeLookup({
    required this.postcode,
    required this.lat,
    required this.lng,
    required this.suggestedAddress,
  });
  final String postcode;
  final double lat;
  final double lng;
  final String suggestedAddress;
}

/// Minimal UK postcode lookup using the public postcodes.io API
class PostcodeApi {
  PostcodeApi({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  final Dio _dio;

  Future<Result<PostcodeLookup>> lookup(String rawPostcode) async {
    try {
      final normalized = _normalize(rawPostcode);
      if (normalized.isEmpty) {
        return const Failure('Enter a valid UK postcode');
      }
      final url = 'https://api.postcodes.io/postcodes/$normalized';
      final res = await _dio.get(url);
      if (res.statusCode != 200 || res.data == null || res.data['status'] != 200) {
        return Failure('Postcode not found: $normalized');
      }
      final r = res.data['result'] as Map<String, dynamic>;
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        return Failure('Coordinates unavailable for $normalized');
      }
      final district = r['admin_district'] as String? ?? '';
      final ward = r['admin_ward'] as String? ?? '';
      final region = r['region'] as String? ?? '';
      final country = r['country'] as String? ?? '';
      final composed = [
        normalized,
        if (ward.isNotEmpty) ward,
        if (district.isNotEmpty) district,
        if (region.isNotEmpty) region,
        if (country.isNotEmpty) country,
      ].join(', ');
      return Success(PostcodeLookup(
        postcode: normalized,
        lat: lat,
        lng: lng,
        suggestedAddress: composed,
      ));
    } catch (e) {
      return Failure('Postcode lookup failed: ${e.toString()}');
    }
  }

  String _normalize(String s) {
    return s.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase().trim();
  }
}

