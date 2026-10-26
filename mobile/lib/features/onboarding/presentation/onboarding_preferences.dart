import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/core/providers/app_providers.dart';

const _onboardingCompleteKey = 'onboarding_complete';

final onboardingCompleteProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

Future<void> markOnboardingComplete(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool(_onboardingCompleteKey, true);
  ref.invalidate(onboardingCompleteProvider);
}
