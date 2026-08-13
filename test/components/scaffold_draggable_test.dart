import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_drag_handle.dart';
import 'package:frontend_scaffold/components/scaffold_draggable.dart';
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

void main() {
  testWidgets('idle renders child normally', (tester) async {
    await _pump(
      tester,
      ScaffoldDraggable(data: 1, child: const Text('drag me')),
    );
    expect(find.text('drag me'), findsOneWidget);
  });

  testWidgets('long-press drag shows 1.05x feedback with shadow and 0.4 faded original', (
    tester,
  ) async {
    await _pump(
      tester,
      ScaffoldDraggable(
        data: 1,
        child: const SizedBox(
          width: 100,
          height: 100,
          child: Center(child: Text('drag')),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('drag')),
    );
    await tester.pump();
    await tester.pump(kLongPressTimeout);

    final Material feedback = tester
        .widgetList<Material>(find.byType(Material))
        .firstWhere(
          (Material m) =>
              m.color == ScaffoldPalette.defaultPalette.dragFeedbackBackground,
        );
    expect(feedback.elevation, 4);

    final Iterable<Transform> transforms = tester.widgetList<Transform>(
      find.byType(Transform),
    );
    expect(
      transforms.any(
        (Transform t) => (t.transform.getMaxScaleOnAxis() - 1.05).abs() < 0.001,
      ),
      isTrue,
    );

    final Iterable<Opacity> opacities = tester.widgetList<Opacity>(
      find.byType(Opacity),
    );
    expect(opacities.any((Opacity o) => o.opacity == 0.4), isTrue);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('composes ScaffoldDragHandle when true and custom widget when provided', (
    tester,
  ) async {
    await _pump(
      tester,
      ScaffoldDraggable(data: 1, dragHandle: true, child: const Text('x')),
    );
    expect(
      find.descendant(
        of: find.byType(ScaffoldDraggable),
        matching: find.byType(ScaffoldDragHandle),
      ),
      findsOneWidget,
    );

    await _pump(
      tester,
      ScaffoldDraggable(
        data: 1,
        dragHandle: const Icon(Icons.menu),
        child: const Text('x'),
      ),
    );
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byType(ScaffoldDragHandle), findsNothing);
  });

  testWidgets('onDragStarted/onDragEnd/onDraggableCanceled fire', (tester) async {
    int started = 0;
    int ended = 0;
    int canceled = 0;
    await _pump(
      tester,
      ScaffoldDraggable(
        data: 1,
        onDragStarted: () => started++,
        onDragEnd: () => ended++,
        onDraggableCanceled: () => canceled++,
        child: const SizedBox(
          width: 80,
          height: 80,
          child: Center(child: Text('d')),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('d')),
    );
    await tester.pump();
    await tester.pump(kLongPressTimeout);
    expect(started, 1);

    await gesture.moveBy(const Offset(20, 20));
    await tester.pump();

    await gesture.up();
    await tester.pump();
    expect(ended, 1);
    expect(canceled, 1);
  });
}
