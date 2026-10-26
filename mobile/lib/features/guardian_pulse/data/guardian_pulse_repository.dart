import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/guardian_pulse/domain/guardian_pulse_event.dart';

class GuardianPulseRepository {
  GuardianPulseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _activeStatuses = ['EMERGING', 'ACTIVE'];

  Stream<List<GuardianPulseEvent>> watchActivePulses({int limit = 40}) {
    return _firestore
        .collection('guardianPulseEvents')
        .where('status', whereIn: _activeStatuses)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(_fromDocument)
          .whereType<GuardianPulseEvent>()
          .toList(growable: false);
    });
  }

  GuardianPulseEvent? _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final location = data['location'];
    LatLng? latLng;
    if (location is GeoPoint) {
      latLng = LatLng(location.latitude, location.longitude);
    }
    if (latLng == null) return null;

    return GuardianPulseEvent(
      id: doc.id,
      status: GuardianPulseStatus.fromString(data['status'] as String?),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      eventCount: (data['eventCount'] as num?)?.toInt() ?? 0,
      dominantEventType: data['dominantEventType'] as String? ?? 'UNKNOWN',
      location: latLng,
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ?? 40,
      hazardId: data['hazardId'] as String?,
    );
  }
}
