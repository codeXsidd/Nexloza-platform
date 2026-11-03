import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/core/router/app_router.dart';

void main() {
  group('NexiozaApp', () {
    testWidgets('can be instantiated with mock router', (tester) async {
      final mockRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Test'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [routerProvider.overrideWithValue(mockRouter)],
          child: MaterialApp.router(routerConfig: mockRouter),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
