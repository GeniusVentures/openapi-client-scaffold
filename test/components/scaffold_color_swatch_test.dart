import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_color_swatch.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

List<Container> _circles(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(ScaffoldColorSwatch),
          matching: find.byType(Container),
        ),
      )
      .where((Container c) {
        final Decoration? decoration = c.decoration;
        return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
      })
      .toList();
}

void main() {
  testWidgets('renders 2 circles with focus ring on selected', (tester) async {
    await _pump(
      tester,
      ScaffoldColorSwatch(colors: [Colors.red, Colors.green], selectedIndex: 1),
    );

    final circles = _circles(tester);
    expect(circles.length, 2);

    final BoxDecoration redDecoration =
        circles[0].decoration! as BoxDecoration;
    expect(redDecoration.color, Colors.red);
    expect(redDecoration.border, isNull);

    final BoxDecoration greenDecoration =
        circles[1].decoration! as BoxDecoration;
    expect(greenDecoration.color, Colors.green);
    final Border border = greenDecoration.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
    expect(border.top.width, ScaffoldDimens.defaultDimens.focusRingWidth);
  });

  testWidgets('renders SizedBox.shrink for 0 colors', (tester) async {
    await _pump(tester, const ScaffoldColorSwatch(colors: []));

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.getSize(find.byType(ScaffoldColorSwatch)), Size.zero);
  });

  testWidgets('renders single swatch in 48px touch target', (tester) async {
    await _pump(tester, ScaffoldColorSwatch(colors: [Colors.red]));

    final ConstrainedBox constrained = tester.widget<ConstrainedBox>(
      find
          .descendant(
            of: find.byType(ScaffoldColorSwatch),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(
      constrained.constraints.minWidth,
      ScaffoldDimens.defaultDimens.minTouchTarget,
    );
    expect(
      constrained.constraints.minHeight,
      ScaffoldDimens.defaultDimens.minTouchTarget,
    );
  });

  testWidgets('renders 10 colors in a scrollable row', (tester) async {
    await _pump(
      tester,
      ScaffoldColorSwatch(
        colors: List<Color>.generate(
          10,
          (int i) => Colors.primaries[i % Colors.primaries.length],
        ),
      ),
    );

    final SingleChildScrollView scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.scrollDirection, Axis.horizontal);
    expect(_circles(tester).length, 10);
  });

  testWidgets('onSelected fires when a non-selected color is tapped', (
    tester,
  ) async {
    int? tapped;
    await _pump(
      tester,
      ScaffoldColorSwatch(
        colors: [Colors.red, Colors.green, Colors.blue],
        selectedIndex: 0,
        onSelected: (int i) => tapped = i,
      ),
    );

    final Finder gestures = find.descendant(
      of: find.byType(ScaffoldColorSwatch),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(gestures.at(1));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('disabled swatches apply dim overlay + IgnorePointer', (
    tester,
  ) async {
    await _pump(
      tester,
      ScaffoldColorSwatch(colors: [Colors.red, Colors.green], disabled: true),
    );

    final Iterable<IgnorePointer> disabledPointers = tester
        .widgetList<IgnorePointer>(
          find.descendant(
            of: find.byType(ScaffoldColorSwatch),
            matching: find.byType(IgnorePointer),
          ),
        )
        .where((IgnorePointer w) => w.ignoring);
    expect(disabledPointers.length, 2);

    final ColoredBox overlay = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(ScaffoldColorSwatch),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(
      overlay.color,
      ScaffoldPalette.defaultPalette.disabledOverlayColor.withValues(
        alpha: ScaffoldDimens.defaultDimens.disabledOverlayOpacity,
      ),
    );
  });
}
