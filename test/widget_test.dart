import 'package:flutter_test/flutter_test.dart';
import 'package:florashop/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FloraShopApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(FloraShopApp), findsOneWidget);
  });
}
