import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardianroute/features/hazard_reporting/domain/hazard_report.dart';
import 'package:uuid/uuid.dart';

class HazardReportSubmission {
  const HazardReportSubmission({
    required this.imageFile,
    this.audioFile,
    this.transcript,
    required this.position,
    this.heading,
    this.speed,
  });

  final File imageFile;
  final File? audioFile;
  final String? transcript;
  final Position position;
  final double? heading;
  final double? speed;
}

class HazardReportRepository {
  HazardReportRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Stream<HazardReport> watchReport(String reportId) {
    return _firestore.collection('hazardReports').doc(reportId).snapshots().map(
      (snap) {
        if (!snap.exists) {
          throw StateError('Report not found.');
        }
        return HazardReport.fromFirestore(snap.id, snap.data()!);
      },
    );
  }

  Future<String> submit(HazardReportSubmission submission) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to report a hazard.');
    }

    final reportId = _uuid.v4();
    final imagePath = 'reports/${user.uid}/$reportId/images/photo.jpg';

    await _storage.ref(imagePath).putFile(
          submission.imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );

    String? audioPath;
    if (submission.audioFile != null) {
      audioPath = 'reports/${user.uid}/$reportId/audio/note.m4a';
      await _storage.ref(audioPath).putFile(
            submission.audioFile!,
            SettableMetadata(contentType: 'audio/mp4'),
          );
    }

    final doc = <String, dynamic>{
      'userId': user.uid,
      'status': 'PENDING',
      'location': GeoPoint(
        submission.position.latitude,
        submission.position.longitude,
      ),
      'imageStoragePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (audioPath != null) {
      doc['audioStoragePath'] = audioPath;
    }
    final transcript = submission.transcript?.trim();
    if (transcript != null && transcript.isNotEmpty) {
      doc['transcript'] = transcript;
    }
    if (submission.heading != null) {
      doc['heading'] = submission.heading;
    }
    if (submission.speed != null) {
      doc['speed'] = submission.speed;
    }

    await _firestore.collection('hazardReports').doc(reportId).set(doc);

    await FirebaseAnalytics.instance.logEvent(name: 'hazard_report_submitted');

    return reportId;
  }
}
