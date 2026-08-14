import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_search_bar.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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
  testWidgets('idle renders ScaffoldSurface pill + TextField + hintText',
      (tester) async {
    await _pump(tester, const ScaffoldSearchBar());

    expect(find.byType(ScaffoldSurface), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search...'), findsOneWidget);
  });

  testWidgets('query shows clear; clear empties query', (tester) async {
    await _pump(tester, const ScaffoldSearchBar());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('hello'), findsNothing);
  });

  testWidgets('isLoading shows status indicator; resultCount shows badge',
      (tester) async {
    await _pump(
      tester,
      const ScaffoldSearchBar(isLoading: true, resultCount: 5),
    );

    expect(find.byType(ScaffoldStatusIndicator), findsOneWidget);
    expect(find.byType(ScaffoldBadge), findsOneWidget);
  });
}
