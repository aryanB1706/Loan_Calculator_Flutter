import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/widgets/onboarding_carousel.dart';

Future<void> _pump(WidgetTester tester, double width, {int page = 0}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: OnboardingCarousel(initialPage: page)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 390.0, 555.0]) {
    testWidgets('only the centred slide is visible at width $width', (
      tester,
    ) async {
      await _pump(tester, width);

      // Slide 2's icon is built by the PageView but must lie fully off-screen.
      final neighbour = find.byIcon(
        Icons.task_alt_outlined,
        skipOffstage: false,
      );
      if (neighbour.evaluate().isNotEmpty) {
        expect(tester.getTopLeft(neighbour).dx, greaterThanOrEqualTo(width));
      }
      expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
    });
  }

  testWidgets('a middle slide shows no part of its neighbours', (tester) async {
    await _pump(tester, 390, page: 1);

    final next = find.byIcon(Icons.support_agent_outlined, skipOffstage: false);
    final previous = find.byIcon(
      Icons.directions_car_outlined,
      skipOffstage: false,
    );

    for (final finder in [next, previous]) {
      if (finder.evaluate().isEmpty) continue;
      final box = tester.getRect(finder);
      expect(box.left >= 390 || box.right <= 0, isTrue);
    }
  });
}
