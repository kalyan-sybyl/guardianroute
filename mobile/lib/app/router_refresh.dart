import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/features/authentication/presentation/auth_controller.dart';
import 'package:guardianroute/features/onboarding/presentation/onboarding_preferences.dart';

/// Notifies [GoRouter] when auth or onboarding state changes.
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(onboardingCompleteProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((ref) {
  final listenable = RouterRefreshListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
