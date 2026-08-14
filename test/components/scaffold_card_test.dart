import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_card.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: ScaffoldMotion(
          reducedMotion: false,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('elevated variant renders ScaffoldSurface with elevation 4 + '
      'deepBlueCardColor', (tester) async {
    await _pump(tester, const ScaffoldCard(variant: 'elevated'));

    final ScaffoldSurface surface =
        tester.widget<ScaffoldSurface>(find.byType(ScaffoldSurface));
    expect(surface.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
    expect(surface.elevation, 4.0);
    expect(surface.border, isNull);
  });

  testWidgets('outlined variant renders elevation 0 + 1px borderSubtle border',
      (tester) async {
    await _pump(tester, const ScaffoldCard(variant: 'outlined'));

    final ScaffoldSurface surface =
        tester.widget<ScaffoldSurface>(find.byType(ScaffoldSurface));
    expect(surface.color, Colors.transparent);
    expect(surface.elevation, 0.0);
    final Border border = surface.border! as Border;
    expect(border.top.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(border.top.width, 1.0);
  });

  testWidgets('filled variant renders elevation 0 + surfaceElevated',
      (tester) async {
    await _pump(tester, const ScaffoldCard(variant: 'filled'));

    final ScaffoldSurface surface =
        tester.widget<ScaffoldSurface>(find.byType(ScaffoldSurface));
    expect(surface.color, ScaffoldPalette.defaultPalette.surfaceElevated);
    expect(surface.elevation, 0.0);
    expect(surface.border, isNull);
  });

  testWidgets('onTap wraps card in ScaffoldPressable and fires onTap',
      (tester) async {
    int taps = 0;
    await _pump(
      tester,
      ScaffoldCard(
        onTap: () => taps++,
        body: const Text('body'),
      ),
    );

    expect(find.byType(ScaffoldPressable), findsOneWidget);

    await tester.tap(find.byType(ScaffoldPressable));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('header/body/actions slots render', (tester) async {
    await _pump(
      tester,
      const ScaffoldCard(
        header: Text('Header'),
        body: Text('Body'),
        actions: Text('Actions'),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
  });
}
