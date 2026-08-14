import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_dashed_border.dart';
import 'package:frontend_scaffold/components/scaffold_drop_target.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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

Widget _dragHarness(Widget target) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const LongPressDraggable<int>(
        data: 1,
        feedback: SizedBox(width: 10, height: 10),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Center(child: Text('src')),
        ),
      ),
      target,
    ],
  );
}

Future<TestGesture> _dragOnto(WidgetTester tester, Widget target) async {
  await _pump(tester, _dragHarness(target));
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.text('src')),
  );
  await tester.pump();
  await tester.pump(kLongPressTimeout);
  await gesture.moveTo(tester.getCenter(find.text('target')));
  await tester.pump();
  return gesture;
}

AnimatedContainer _dropAnimated(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(ScaffoldDropTarget),
      matching: find.byType(AnimatedContainer),
    ),
  );
}

ColoredBox _tint(WidgetTester tester, Color color) {
  return tester
      .widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(ScaffoldDropTarget),
          matching: find.byType(ColoredBox),
        ),
      )
      .firstWhere((ColoredBox b) => b.color == color);
}

void main() {
  testWidgets('idle renders dashed borderSubtle border on Surface', (
    tester,
  ) async {
    await _pump(
      tester,
      ScaffoldDropTarget(child: const SizedBox(width: 100, height: 50)),
    );

    final ScaffoldDashedBorder dashed = tester.widget<ScaffoldDashedBorder>(
      find.byType(ScaffoldDashedBorder),
    );
    expect(dashed.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(find.byType(ScaffoldSurface), findsOneWidget);
  });

  testWidgets('over accepted shows dropZoneHighlight tint + lightGreenPrimary border', (
    tester,
  ) async {
    final TestGesture gesture = await _dragOnto(
      tester,
      ScaffoldDropTarget(
        child: const SizedBox(width: 200, height: 100, child: Text('target')),
      ),
    );

    final BoxDecoration decoration =
        _dropAnimated(tester).decoration! as BoxDecoration;
    expect(
      decoration.border,
      Border.all(color: ScaffoldPalette.defaultPalette.lightGreenPrimary),
    );
    expect(
      _tint(tester, ScaffoldPalette.defaultPalette.dropZoneHighlight).color,
      isNotNull,
    );
    expect(find.byType(ScaffoldStatusIndicator), findsOneWidget);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('over rejected shows dropZoneRejected tint + statusError border', (
    tester,
  ) async {
    final TestGesture gesture = await _dragOnto(
      tester,
      ScaffoldDropTarget(
        acceptCondition: (dynamic data) => data is String,
        child: const SizedBox(width: 200, height: 100, child: Text('target')),
      ),
    );

    final BoxDecoration decoration =
        _dropAnimated(tester).decoration! as BoxDecoration;
    expect(
      decoration.border,
      Border.all(color: ScaffoldPalette.defaultPalette.statusError),
    );
    expect(
      _tint(tester, ScaffoldPalette.defaultPalette.dropZoneRejected).color,
      isNotNull,
    );
    expect(find.byType(ScaffoldStatusIndicator), findsOneWidget);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('dropped shows accepted tint then returns idle after 500ms', (
    tester,
  ) async {
    int accepted = 0;
    final TestGesture gesture = await _dragOnto(
      tester,
      ScaffoldDropTarget(
        onAccept: (_) => accepted++,
        child: const SizedBox(width: 200, height: 100, child: Text('target')),
      ),
    );

    await gesture.up();
    await tester.pump();
    expect(accepted, 1);
    expect(
      _tint(tester, ScaffoldPalette.defaultPalette.dropZoneHighlight).color,
      isNotNull,
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(ScaffoldDashedBorder), findsOneWidget);
  });

  testWidgets('Semantics label reports Drop zone + state', (tester) async {
    await _pump(
      tester,
      ScaffoldDropTarget(child: const SizedBox(width: 100, height: 50)),
    );

    final Semantics semantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldDropTarget),
            matching: find.byType(Semantics),
          ),
        )
        .firstWhere(
          (Semantics s) => (s.properties.label ?? '').startsWith('Drop zone'),
        );
    expect(semantics.properties.label, 'Drop zone. Idle');
  });
}
