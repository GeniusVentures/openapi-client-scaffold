import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_fade.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_pulse.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_scale.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reducedMotion = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: ScaffoldMotion(reducedMotion: reducedMotion, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('fade animates child opacity on trigger change', (tester) async {
    await _pump(
      tester,
      const ScaffoldAnimatedDisplayFade(trigger: 1, child: Text('x')),
    );

    final Finder fadeFinder = find.descendant(
      of: find.byType(ScaffoldAnimatedDisplayFade),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 0.0);

    await _pump(
      tester,
      const ScaffoldAnimatedDisplayFade(trigger: 2, child: Text('x')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final double animated = tester
        .widget<FadeTransition>(fadeFinder)
        .opacity
        .value;
    expect(animated, greaterThan(0.0));
  });

  testWidgets('reducedMotion substitutes a zero-duration fade', (tester) async {
    await _pump(
      tester,
      const ScaffoldAnimatedDisplayScale(child: Text('x')),
      reducedMotion: true,
    );

    expect(
      find.descendant(
        of: find.byType(ScaffoldAnimatedDisplayScale),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ScaffoldAnimatedDisplayScale),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('pulse repeats scale between 1.0 and 1.05', (tester) async {
    await _pump(tester, const ScaffoldAnimatedDisplayPulse(child: Text('x')));

    final Finder scaleFinder = find.descendant(
      of: find.byType(ScaffoldAnimatedDisplayPulse),
      matching: find.byType(ScaleTransition),
    );
    final double initial = tester
        .widget<ScaleTransition>(scaleFinder)
        .scale
        .value;
    expect(initial, greaterThanOrEqualTo(1.0));
    expect(initial, lessThanOrEqualTo(1.05));

    await tester.pump(const Duration(milliseconds: 50));
    final double after = tester
        .widget<ScaleTransition>(scaleFinder)
        .scale
        .value;
    expect(after, isNot(initial));
  });
}
