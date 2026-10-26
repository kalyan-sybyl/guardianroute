import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';
import 'package:guardianroute/features/route_safety/domain/road_segment.dart';

class RoadRiskRepository {
  RoadRiskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RoadSegment>> watchHighRiskSegments({
    int minRiskScore = 26,
    int limit = 60,
  }) {
    return _firestore
        .collection('roadSegments')
        .where('riskScore', isGreaterThanOrEqualTo: minRiskScore)
        .orderBy('riskScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(_fromDocument)
          .whereType<RoadSegment>()
          .toList(growable: false);
    });
  }

  RoadSegment? _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final location = data['location'];
    LatLng? latLng;
    if (location is GeoPoint) {
      latLng = LatLng(location.latitude, location.longitude);
    }
    if (latLng == null) return null;

    final score = (data['riskScore'] as num?)?.toInt() ?? 0;
    return RoadSegment(
      id: doc.id,
      geohash: data['geohash'] as String? ?? doc.id,
      location: latLng,
      riskScore: score,
      riskLevel: RoadRiskLevel.fromString(data['riskLevel'] as String?),
    );
  }
}
