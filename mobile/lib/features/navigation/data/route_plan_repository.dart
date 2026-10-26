import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/navigation/domain/route_option.dart';

class RoutePlanRepository {
  RoutePlanRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<RoutePlanResult> planSafeRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final result = await _functions.httpsCallable('planSafeRoutes').call({
      'originLat': origin.latitude,
      'originLng': origin.longitude,
      'destLat': destination.latitude,
      'destLng': destination.longitude,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final routesRaw = data['routes'] as List<dynamic>;
    final recommendation = Map<String, dynamic>.from(
      data['recommendation'] as Map,
    );

    final routes = routesRaw
        .map((r) => RouteOption.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();

    return RoutePlanResult(
      routes: routes,
      recommendationMessage: recommendation['message'] as String? ?? '',
      recommendedLabel: RouteLabel.fromWire(
        recommendation['recommendedLabel'] as String?,
      ),
      isDemo: data['isDemo'] as bool? ?? false,
    );
  }
}
