import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianroute/app/theme.dart';

void main() {
  test('Guardian theme builds without error', () {
    final theme = buildGuardianTheme(brightness: Brightness.light);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
  });
}
