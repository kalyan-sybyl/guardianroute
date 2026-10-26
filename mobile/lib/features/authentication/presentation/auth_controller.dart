import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/features/authentication/data/auth_repository.dart';
import 'package:guardianroute/features/authentication/domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<void> signInAnonymously() => _repository.signInAnonymously();

  Future<void> signInWithGoogle() => _repository.signInWithGoogle();

  Future<void> signOut() => _repository.signOut();
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
