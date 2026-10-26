import 'package:guardianroute/app/bootstrap.dart';
import 'package:guardianroute/core/config/app_config.dart';

Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  await bootstrap(config);
}
