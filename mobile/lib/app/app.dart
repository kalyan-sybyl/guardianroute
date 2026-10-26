import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/app/router.dart';
import 'package:guardianroute/app/theme.dart';
import 'package:guardianroute/core/config/app_config.dart';
import 'package:guardianroute/core/config/app_flavor.dart';

class GuardianRouteApp extends ConsumerWidget {
  const GuardianRouteApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GuardianRoute',
      debugShowCheckedModeBanner: config.flavor != AppFlavor.production,
      theme: buildGuardianTheme(brightness: Brightness.light),
      darkTheme: buildGuardianTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        return Banner(
          message: config.flavor.displayName.toUpperCase(),
          location: BannerLocation.topEnd,
          color: config.flavor.isDemo ? Colors.deepOrange : Colors.blueGrey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
