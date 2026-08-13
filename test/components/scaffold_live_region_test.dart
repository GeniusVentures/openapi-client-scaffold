import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Semantics _semanticsOf(WidgetTester tester) {
  return tester.widget<Semantics>(
    find
        .descendant(
          of: find.byType(ScaffoldLiveRegion),
          matching: find.byType(Semantics),
        )
        .first,
  );
}

void main() {
  testWidgets('registers Semantics(liveRegion: true) with label', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldLiveRegion(label: 'Volume'));

    final semantics = _semanticsOf(tester);
    expect(semantics.liveRegion, isTrue);
    expect(semantics.label, 'Volume');
  });

  testWidgets('updates Semantics label when label parameter changes', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldLiveRegion(label: 'Volume'));
    await _pump(tester, const ScaffoldLiveRegion(label: 'Brightness'));

    final semantics = _semanticsOf(tester);
    expect(semantics.label, 'Brightness');
  });
}
