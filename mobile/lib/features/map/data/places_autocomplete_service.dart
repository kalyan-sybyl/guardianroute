import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/config/maps_config.dart';
import 'package:guardianroute/core/constants/map_constants.dart';
import 'package:guardianroute/features/map/domain/map_destination.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;
}

class PlacesAutocompleteService {
  PlacesAutocompleteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _uuid = const Uuid();
  String? _sessionToken;

  void resetSession() {
    _sessionToken = _uuid.v4();
  }

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (!MapsConfig.hasPlacesApiKey || input.trim().length < 2) {
      return const [];
    }

    _sessionToken ??= _uuid.v4();

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': MapsConfig.apiKey,
        'sessiontoken': _sessionToken!,
        'components': 'country:ug',
        'location': '${MapConstants.placesLocationBias.latitude},'
            '${MapConstants.placesLocationBias.longitude}',
        'radius': MapConstants.placesRadiusMeters.toString(),
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return const [];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK' && body['status'] != 'ZERO_RESULTS') {
      return const [];
    }

    final predictions = body['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((p) {
          final map = p as Map<String, dynamic>;
          return PlaceSuggestion(
            placeId: map['place_id'] as String,
            description: map['description'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<MapDestination?> resolvePlace(PlaceSuggestion suggestion) async {
    if (!MapsConfig.hasPlacesApiKey) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': suggestion.placeId,
        'fields': 'geometry,formatted_address,name',
        'key': MapsConfig.apiKey,
        'sessiontoken': _sessionToken ?? _uuid.v4(),
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK') return null;

    final result = body['result'] as Map<String, dynamic>;
    final geometry = result['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();

    final label = result['formatted_address'] as String? ??
        result['name'] as String? ??
        suggestion.description;

    _sessionToken = null;

    return MapDestination(
      placeId: suggestion.placeId,
      label: label,
      location: LatLng(lat, lng),
    );
  }
}
