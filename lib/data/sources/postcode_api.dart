import 'package:dio/dio.dart';
import 'package:cleardish/data/models/postcode_lookup.dart';

/// Lightweight client for https://postcodes.io
class PostcodeApi {
  PostcodeApi({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));
  static const String _baseUrl = 'https://api.postcodes.io';
  final Dio _dio;

  /// Returns a list of matching postcode strings for the query.
  Future<List<String>> autocomplete(String query) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return const [];
    final res = await _dio.get('/postcodes', queryParameters: {'q': q});
    if (res.statusCode == 200 && res.data is Map) {
      final list = (res.data['result'] as List?) ?? const [];
      return list
          .map((e) => (e['postcode'] as String?)?.toUpperCase())
          .whereType<String>()
          .toList();
    }
    return const [];
  }

  /// Detailed lookup for a single postcode.
  Future<PostcodeLookup> lookup(String postcode) async {
    final pc = postcode.trim().toUpperCase().replaceAll(' ', '');
    final res = await _dio.get('/postcodes/$pc');
    if (res.statusCode == 200 && res.data is Map) {
      final data = res.data['result'] as Map<String, dynamic>;
      return PostcodeLookup.fromMap(data);
    }
    throw Exception('Postcode not found');
  }
}
