import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guardianroute/core/services/app_logger.dart';
import 'package:guardianroute/features/authentication/domain/app_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  Future<AppUser> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in returned no user.');
    }
    await _ensureUserProfile();
    await _logLogin('anonymous');
    return _mapUser(user)!;
  }

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Google sign-in returned no user.');
    }
    await _ensureUserProfile();
    await _logLogin('google');
    return _mapUser(user)!;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> _logLogin(String method) async {
    try {
      await FirebaseAnalytics.instance.logLogin(loginMethod: method);
      await FirebaseAnalytics.instance.logEvent(name: 'login_completed');
    } catch (_) {}
  }

  Future<void> _ensureUserProfile() async {
    try {
      await _functions.httpsCallable('ensureUserProfile').call();
    } catch (e, st) {
      appLogger.w('ensureUserProfile failed: $e\n$st');
    }
  }
}
