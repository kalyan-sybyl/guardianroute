import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);
