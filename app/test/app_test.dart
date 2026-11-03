import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/app.dart';

void main() {
  group('NexiozaApp', () {
    testWidgets('can be instantiated and rendered', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: NexiozaApp()));

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(NexiozaApp), findsOneWidget);
    });
  });
}
