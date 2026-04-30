import 'package:flutter_test/flutter_test.dart';
import 'package:flower_shop/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowerShopApp());
    expect(find.byType(FlowerShopApp), findsOneWidget);
  });
}