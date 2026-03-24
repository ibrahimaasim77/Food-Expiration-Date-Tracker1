import 'package:flutter_test/flutter_test.dart';
import 'package:food_expiry_tracker/main.dart';

void main() {
  testWidgets('FoodExpiryApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FoodExpiryApp(showOnboarding: true, showWelcome: false),
    );
    expect(find.byType(FoodExpiryApp), findsOneWidget);
  });
}
