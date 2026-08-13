import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
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
  testWidgets('small child is expanded to a 48x48 hit area', (tester) async {
    await _pump(
      tester,
      ScaffoldTouchTarget(child: const SizedBox(width: 16, height: 16)),
    );

    final size = tester.getSize(find.byType(ScaffoldTouchTarget));
    expect(size.width, 48.0);
    expect(size.height, 48.0);
  });

  testWidgets('registers Semantics(container: true)', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      ScaffoldTouchTarget(child: const SizedBox(width: 16, height: 16)),
    );

    final node = tester.getSemantics(
      find.descendant(
        of: find.byType(ScaffoldTouchTarget),
        matching: find.byType(Semantics),
      ),
    );
    expect(node.hasFlag(SemanticsFlag.isContainer), isTrue);
    handle.dispose();
  });

  testWidgets('explicit minWidth/minHeight enforce 56x56', (tester) async {
    await _pump(
      tester,
      ScaffoldTouchTarget(
        minWidth: 56,
        minHeight: 56,
        child: const SizedBox(width: 16, height: 16),
      ),
    );

    final size = tester.getSize(find.byType(ScaffoldTouchTarget));
    expect(size.width, 56.0);
    expect(size.height, 56.0);
  });
}
