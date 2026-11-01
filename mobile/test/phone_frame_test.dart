import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/widgets/phone_frame.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: PhoneFrame(
        child: Builder(
          builder: (context) => Text('${MediaQuery.sizeOf(context).width}'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a phone-sized screen is left alone', (tester) async {
    await _pump(tester, 390);

    expect(find.text('390.0'), findsOneWidget);
    expect(
      find.byType(SizedBox).evaluate().where((e) {
        final box = e.widget as SizedBox;
        return box.width == PhoneFrame.maxWidth;
      }),
      isEmpty,
    );
  });

  testWidgets('a wide screen shows a centred phone-width column', (
    tester,
  ) async {
    await _pump(tester, 1280);

    final rect = tester.getRect(find.byType(Text));
    expect(rect.width, lessThanOrEqualTo(PhoneFrame.maxWidth));
    expect(rect.center.dx, closeTo(640, 1));
  });

  testWidgets('screens inside see the column width, not the browser width', (
    tester,
  ) async {
    await _pump(tester, 1280);

    expect(find.text('${PhoneFrame.maxWidth}'), findsOneWidget);
  });
}
