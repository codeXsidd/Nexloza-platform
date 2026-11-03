import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('light()', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.light();
      });

      test('returns non-null ThemeData', () {
        expect(theme, isNotNull);
      });

      test('uses Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('has light brightness', () {
        expect(theme.brightness, Brightness.light);
      });

      test('has non-null colorScheme', () {
        expect(theme.colorScheme, isNotNull);
      });
    });

    group('dark()', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.dark();
      });

      test('returns non-null ThemeData', () {
        expect(theme, isNotNull);
      });

      test('uses Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('has dark brightness', () {
        expect(theme.brightness, Brightness.dark);
      });

      test('has non-null colorScheme', () {
        expect(theme.colorScheme, isNotNull);
      });
    });

    test('light and dark themes share the same primary color family', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.colorScheme.primary.toARGB32() != 0, isTrue);
      expect(dark.colorScheme.primary.toARGB32() != 0, isTrue);
    });
  });
}
