import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_shadows.dart';
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

Future<void> _pumpMidnight(
  WidgetTester tester,
  Brightness brightness,
  Widget child,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: midnightTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<Container>(_surfaceContainer()).decoration! as BoxDecoration;

BoxDecoration? _foreground(WidgetTester tester) =>
    tester.widget<Container>(_surfaceContainer()).foregroundDecoration
        as BoxDecoration?;

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
    expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(8)));
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

  testWidgets('default theme: elevation uses Material and no BoxShadow', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSurface(elevation: 4));

    final decoration =
        tester.widget<Container>(_surfaceContainer()).decoration!
            as BoxDecoration;
    expect(decoration.boxShadow, isNull);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(ScaffoldSurface),
        matching: find.byType(Material),
      ),
    );
    expect(material.elevation, 4);
  });

  testWidgets('a registered elevated shadow replaces Material elevation', (
    tester,
  ) async {
    const shadow = [BoxShadow(color: Color(0xFF123456), blurRadius: 7.0)];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ...scaffoldThemeExtensions,
            const ScaffoldShadows(elevated: shadow),
          ],
        ),
        home: const Scaffold(
          body: Center(child: ScaffoldSurface(elevation: 4)),
        ),
      ),
    );

    final decoration =
        tester.widget<Container>(_surfaceContainer()).decoration!
            as BoxDecoration;
    expect(decoration.boxShadow, shadow);
    expect(
      find.descendant(
        of: find.byType(ScaffoldSurface),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
  });

  testWidgets('a registered elevated shadow is ignored at zero elevation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ...scaffoldThemeExtensions,
            const ScaffoldShadows(
              elevated: [BoxShadow(color: Color(0xFF123456), blurRadius: 7.0)],
            ),
          ],
        ),
        home: const Scaffold(body: Center(child: ScaffoldSurface())),
      ),
    );

    final decoration =
        tester.widget<Container>(_surfaceContainer()).decoration!
            as BoxDecoration;
    expect(decoration.boxShadow, isNull);
  });

  testWidgets(
    'default theme: elevated surface has no gradient and no hairline',
    (tester) async {
      await _pump(tester, const ScaffoldSurface(elevation: 4));

      expect(_decoration(tester).gradient, isNull);
      expect(
        _decoration(tester).color,
        ScaffoldPalette.defaultPalette.deepBlueCardColor,
      );
      expect(_foreground(tester), isNull);
    },
  );

  testWidgets(
    'midnight light: elevated surface paints the sheen and hairline',
    (tester) async {
      await _pumpMidnight(
        tester,
        Brightness.light,
        const ScaffoldSurface(elevation: 2),
      );

      expect(
        _decoration(tester).gradient,
        Midnight.lightScaffoldGradients.surfaceSheen,
      );
      expect(_decoration(tester).color, isNull);
      final edge = _foreground(tester)!.border! as Border;
      expect(edge.top.color, Midnight.lightColorRoles.surfaceEdge);
      expect(edge.top.width, 1.0);
    },
  );

  testWidgets(
    'midnight dark: elevated surface keeps the flat color and gets the hairline',
    (tester) async {
      await _pumpMidnight(
        tester,
        Brightness.dark,
        const ScaffoldSurface(elevation: 2),
      );

      expect(_decoration(tester).gradient, isNull);
      expect(_decoration(tester).color, Midnight.darkPalette.deepBlueCardColor);
      final edge = _foreground(tester)!.border! as Border;
      expect(edge.top.color, Midnight.darkColorRoles.surfaceEdge);
    },
  );

  testWidgets('sheen and hairline apply only to raised surfaces', (
    tester,
  ) async {
    await _pumpMidnight(tester, Brightness.light, const ScaffoldSurface());

    expect(_decoration(tester).gradient, isNull);
    expect(_foreground(tester), isNull);
  });

  testWidgets('a caller color keeps a flat fill with no sheen', (tester) async {
    await _pumpMidnight(
      tester,
      Brightness.light,
      const ScaffoldSurface(elevation: 2, color: Colors.red),
    );

    expect(_decoration(tester).gradient, isNull);
    expect(_decoration(tester).color, Colors.red);
    expect(_foreground(tester), isNotNull);
  });

  testWidgets('a caller border wins and no hairline is added', (tester) async {
    final border = Border.all(color: Colors.green, width: 3);
    await _pumpMidnight(
      tester,
      Brightness.light,
      ScaffoldSurface(elevation: 2, border: border),
    );

    expect(_decoration(tester).border, border);
    expect(_foreground(tester), isNull);
  });

  testWidgets('the hairline follows the circle shape', (tester) async {
    await _pumpMidnight(
      tester,
      Brightness.dark,
      const ScaffoldSurface(elevation: 2, shape: BoxShape.circle),
    );

    final foreground = _foreground(tester)!;
    expect(foreground.shape, BoxShape.circle);
    expect(foreground.borderRadius, isNull);
  });

  testWidgets('sheen and hairline also work with the Material elevation path', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ...scaffoldThemeExtensions,
            Midnight.lightScaffoldGradients,
            Midnight.lightColorRoles,
          ],
        ),
        home: const Scaffold(
          body: Center(child: ScaffoldSurface(elevation: 4)),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ScaffoldSurface),
        matching: find.byType(Material),
      ),
      findsWidgets,
    );
    expect(
      _decoration(tester).gradient,
      Midnight.lightScaffoldGradients.surfaceSheen,
    );
    expect(_foreground(tester), isNotNull);
  });

  testWidgets('the hairline does not change the laid-out size', (tester) async {
    const child = ScaffoldSurface(
      elevation: 2,
      padding: EdgeInsets.all(8),
      child: SizedBox(width: 100, height: 40),
    );
    Future<Size> sizeWith(List<ThemeExtension<dynamic>> extensions) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: extensions),
          home: const Scaffold(body: Center(child: child)),
        ),
      );
      return tester.getSize(find.byType(ScaffoldSurface));
    }

    final without = await sizeWith(scaffoldThemeExtensions);
    final withEdge = await sizeWith([
      ...scaffoldThemeExtensions,
      const ScaffoldColorRoles(surfaceEdge: Color(0x1FFFFFFF)),
    ]);
    final withSheen = await sizeWith([
      ...scaffoldThemeExtensions,
      Midnight.lightScaffoldGradients,
    ]);

    expect(withEdge, without);
    expect(withSheen, without);
    expect(without, const Size(116, 56));
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
