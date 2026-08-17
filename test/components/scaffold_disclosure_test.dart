import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
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

Future<void> _pumpLight(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.lightPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Future<void> _pumpReducedMotion(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: ScaffoldMotion(
        reducedMotion: true,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Test 1: uncontrolled initiallyExpanded:false hides body, tap reveals',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          body: Text('Body content'),
        ),
      );

      expect(find.text('Body content'), findsNothing);

      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      expect(find.text('Body content'), findsOneWidget);
    },
  );

  testWidgets(
    'Test 2: uncontrolled initiallyExpanded:true shows body, tap hides',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          initiallyExpanded: true,
          body: Text('Body content'),
        ),
      );

      expect(find.text('Body content'), findsOneWidget);

      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      expect(find.text('Body content'), findsNothing);
    },
  );

  testWidgets(
    'Test 3: controlled expanded:false does NOT expand on tap, only fires callback',
    (tester) async {
      bool? captured;
      await _pump(
        tester,
        ScaffoldDisclosure(
          title: 'Header',
          expanded: false,
          onExpandedChanged: (bool next) => captured = next,
          body: const Text('Body content'),
        ),
      );

      expect(find.text('Body content'), findsNothing);

      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      // Callback fired with next=true
      expect(captured, true);
      // But body is still hidden — the parent must update `expanded`
      expect(find.text('Body content'), findsNothing);
    },
  );

  testWidgets(
    'Test 4: onExpandedChanged fires exactly once per tap with the negated state',
    (tester) async {
      final List<bool> calls = <bool>[];
      await _pump(
        tester,
        ScaffoldDisclosure(
          title: 'Header',
          onExpandedChanged: calls.add,
          body: const Text('Body content'),
        ),
      );

      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();
      expect(calls, <bool>[true]);

      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();
      expect(calls, <bool>[true, false]);
    },
  );

  testWidgets(
    'Test 5: chevron AnimatedRotation turns is 0.0 collapsed and 0.25 expanded',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          body: Text('Body'),
        ),
      );

      AnimatedRotation rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0.0);

      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0.25);
    },
  );

  testWidgets(
    'Test 6: chevron tint — textSecondary default, lightGreenPrimary when expanded+highlight',
    (tester) async {
      // Case A: collapsed → textSecondary
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          body: Text('Body'),
        ),
      );
      Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, ScaffoldPalette.defaultPalette.textSecondary);

      // Case B: expanded + highlightWhenExpanded:true → lightGreenPrimary
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          initiallyExpanded: true,
          highlightWhenExpanded: true,
          body: Text('Body'),
        ),
      );
      icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);

      // Case C: expanded + highlightWhenExpanded:false → textSecondary
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          initiallyExpanded: true,
          body: Text('Body'),
        ),
      );
      icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, ScaffoldPalette.defaultPalette.textSecondary);
    },
  );

  testWidgets(
    'Test 7: Semantics node reports expanded flag matching state and label:title',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldDisclosure(
          title: 'My Section',
          body: Text('Body'),
        ),
      );

      Semantics sem = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(ScaffoldDisclosure),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere(
            (Semantics s) => s.properties.label == 'My Section',
          );
      expect(sem.properties.expanded, false);

      await tester.tap(find.text('My Section'));
      await tester.pumpAndSettle();

      sem = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(ScaffoldDisclosure),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere(
            (Semantics s) => s.properties.label == 'My Section',
          );
      expect(sem.properties.expanded, true);
    },
  );

  testWidgets(
    'Test 8: renders under ThemeData.light() + lightPalette, body indent is (left: space6, top: space4)',
    (tester) async {
      await _pumpLight(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          initiallyExpanded: true,
          body: Text('Body'),
        ),
      );

      expect(find.byType(ScaffoldDisclosure), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);

      // Find the Padding that wraps the body — it should use the locked indent.
      final Padding bodyPadding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Body'),
          matching: find.byType(Padding),
        ),
      );
      expect(
        bodyPadding.padding,
        EdgeInsets.only(
          left: ScaffoldDimens.defaultDimens.space6,
          top: ScaffoldDimens.defaultDimens.space4,
        ),
      );
    },
  );

  testWidgets(
    'Reduced-motion: durations collapse to zero when ScaffoldMotion.reducedMotion is true',
    (tester) async {
      await _pumpReducedMotion(
        tester,
        const ScaffoldDisclosure(
          title: 'Header',
          body: Text('Body'),
        ),
      );

      final AnimatedSize animatedSize = tester.widget<AnimatedSize>(
        find.byType(AnimatedSize),
      );
      expect(animatedSize.duration, Duration.zero);

      final AnimatedRotation rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.duration, Duration.zero);
    },
  );
}
