import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_responsive_visibility.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Widget _visibility({
  double? showAt,
  double? hideAt,
  ComparisonOperator operator = ComparisonOperator.greaterThanOrEqual,
  Widget? replacement,
}) {
  return ScaffoldResponsiveVisibility(
    showAt: showAt,
    hideAt: hideAt,
    operator: operator,
    replacement: replacement,
    child: const Text('visible'),
  );
}

void main() {
  testWidgets('showAt with >= renders child at width 800', (tester) async {
    await _pumpAtSize(
      tester,
      const Size(800, 600),
      _visibility(showAt: 760),
    );

    expect(find.text('visible'), findsOneWidget);
  });

  testWidgets('showAt with >= renders SizedBox.shrink at width 600', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const Size(600, 600),
      _visibility(showAt: 760),
    );

    expect(find.text('visible'), findsNothing);
    final SizedBox box = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(ScaffoldResponsiveVisibility),
        matching: find.byType(SizedBox),
      ),
    );
    expect(box.width, 0.0);
    expect(box.height, 0.0);
  });

  testWidgets('hideAt with <= hides at 600 and renders at 800', (tester) async {
    await _pumpAtSize(
      tester,
      const Size(600, 600),
      _visibility(hideAt: 760, operator: ComparisonOperator.lessThanOrEqual),
    );
    expect(find.text('visible'), findsNothing);

    tester.view.physicalSize = const Size(800, 600);
    await tester.pump();
    expect(find.text('visible'), findsOneWidget);
  });

  testWidgets('replacement widget shows when hide condition is met', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const Size(600, 600),
      _visibility(
        hideAt: 760,
        operator: ComparisonOperator.lessThanOrEqual,
        replacement: const Text('replacement'),
      ),
    );

    expect(find.text('visible'), findsNothing);
    expect(find.text('replacement'), findsOneWidget);
  });

  testWidgets('responds to MediaQuery size change', (tester) async {
    await _pumpAtSize(
      tester,
      const Size(600, 600),
      _visibility(showAt: 760),
    );
    expect(find.text('visible'), findsNothing);

    tester.view.physicalSize = const Size(800, 600);
    await tester.pump();
    expect(find.text('visible'), findsOneWidget);
  });
}
