import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:cut_above/core/env/build_secrets.dart';

class GeocodingService {
  static Future<String?> getAreaFromCoordinates({
    required double lat,
    required double lng,
  }) async {
    // Geocoding via HTTP is blocked by CORS on web — feature is mobile-first
    if (kIsWeb) return null;

    final key = BuildSecrets.googleMapsApiKey.isNotEmpty
        ? BuildSecrets.googleMapsApiKey
        : (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng&key=$key',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List;
      if (results.isEmpty) return null;

      for (final result in results) {
        final components = result['address_components'] as List;
        for (final component in components) {
          final types = component['types'] as List;
          if (types.contains('sublocality_level_1') ||
              types.contains('sublocality') ||
              types.contains('neighborhood')) {
            return component['long_name'] as String;
          }
        }
      }

      for (final result in results) {
        final components = result['address_components'] as List;
        for (final component in components) {
          final types = component['types'] as List;
          if (types.contains('locality')) {
            return component['long_name'] as String;
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
