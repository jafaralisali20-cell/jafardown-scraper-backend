import 'package:flutter_test/flutter_test.dart';
import 'package:universal_downloader/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JafarDownApp());
    expect(find.byType(JafarDownApp), findsOneWidget);
  });
}
