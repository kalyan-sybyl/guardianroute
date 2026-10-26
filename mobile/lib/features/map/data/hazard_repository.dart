import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';

class HazardRepository {
  HazardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _activeStatuses = ['ACTIVE', 'VERIFIED', 'REPORTED', 'DETECTED'];

  Stream<List<Hazard>> watchActiveHazards({int limit = 150}) {
    return _firestore
        .collection('hazards')
        .where('status', whereIn: _activeStatuses)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(_fromDocument)
          .whereType<Hazard>()
          .toList(growable: false);
    });
  }

  Hazard? _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final location = data['location'];
    LatLng? latLng;
    if (location is GeoPoint) {
      latLng = LatLng(location.latitude, location.longitude);
    } else if (location is Map) {
      final lat = location['latitude'];
      final lng = location['longitude'];
      if (lat is num && lng is num) {
        latLng = LatLng(lat.toDouble(), lng.toDouble());
      }
    }
    if (latLng == null) return null;

    return Hazard(
      id: doc.id,
      publicId: data['publicId'] as String? ?? doc.id,
      type: data['type'] as String? ?? 'OTHER',
      severity: HazardSeverity.fromString(data['severity'] as String?),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      status: HazardStatus.fromString(data['status'] as String?),
      location: latLng,
      description: data['description'] as String? ?? 'Road hazard reported.',
      recommendedAction: data['recommendedAction'] as String?,
    );
  }
}
