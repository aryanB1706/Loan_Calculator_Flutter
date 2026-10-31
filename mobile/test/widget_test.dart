import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/app.dart';

void main() {
  testWidgets('starts on the auth route', (tester) async {
    await tester.pumpWidget(const LoanApp());
    await tester.pumpAndSettle();

    expect(find.text('Auth'), findsOneWidget);
  });
}
