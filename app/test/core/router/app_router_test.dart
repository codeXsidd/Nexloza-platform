import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/router/app_router.dart';

void main() {
  group('AppRouter', () {
    test('routerProvider can be created', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isNotNull);
    });

    test('initial location is /splash', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/splash',
      );
    });
  });
}
