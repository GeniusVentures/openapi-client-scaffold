import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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

Finder _surfaceContainer() => find.descendant(
      of: find.byType(ScaffoldSurface),
      matching: find.byType(Container),
    );

void main() {
  testWidgets('default renders Container with card color and radius', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSurface());

    final container = tester.widget<Container>(_surfaceContainer());
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.deepBlueCardColor);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(ScaffoldDimens.defaultDimens.borderRadiusCard),
    );
  });

  testWidgets('explicit overrides are applied', (tester) async {
    await _pump(
      tester,
      ScaffoldSurface(
        color: Colors.red,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: Colors.white, width: 2),
        padding: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );

    final container = tester.widget<Container>(_surfaceContainer());
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, Colors.red);
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(8)),
    );
    expect(decoration.border, Border.all(color: Colors.white, width: 2));
    expect(container.padding, const EdgeInsets.all(16));

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(ScaffoldSurface),
        matching: find.byType(Material),
      ),
    );
    expect(material.elevation, 4);
  });

  testWidgets('renders the child', (tester) async {
    await _pump(tester, const ScaffoldSurface(child: Text('hello')));
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('circle shape renders a circular container', (tester) async {
    await _pump(tester, const ScaffoldSurface(shape: BoxShape.circle));

    expect(find.byType(ClipOval), findsOneWidget);
    final container = tester.widget<Container>(_surfaceContainer());
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
  });
}
