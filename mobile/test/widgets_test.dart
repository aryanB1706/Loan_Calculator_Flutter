import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/core/widgets/app_loader.dart';
import 'package:loan_app/core/widgets/app_text_field.dart';
import 'package:loan_app/core/widgets/primary_button.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
}

void main() {
  testWidgets('primary button shows label and handles taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Continue', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Continue'));

    expect(taps, 1);
  });

  testWidgets('primary button replaces its label with a loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const PrimaryButton(label: 'Continue', isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('text field renders its label and hint', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTextField(
          label: 'Mobile Number',
          hint: 'Please enter your mobile no.',
        ),
      ),
    );

    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Please enter your mobile no.'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('loader shows progress and message', (tester) async {
    await tester.pumpWidget(wrap(const AppLoader(message: 'Loading')));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
  });
}
