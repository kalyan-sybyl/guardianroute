import 'package:guardianroute/core/config/app_flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.useFirebaseEmulators,
    this.emulatorHost = '10.0.2.2',
  });

  final AppFlavor flavor;
  final bool useFirebaseEmulators;

  /// Android emulator loopback to host machine.
  final String emulatorHost;

  static AppConfig fromEnvironment() {
    const flavorName = String.fromEnvironment(
      'FLAVOR',
      defaultValue: 'development',
    );
    const useEmulators = bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: false,
    );
    const host = String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    );

    return AppConfig(
      flavor: AppFlavor.fromName(flavorName),
      useFirebaseEmulators: useEmulators,
      emulatorHost: host,
    );
  }
}
