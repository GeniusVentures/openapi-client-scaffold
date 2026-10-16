import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<BuildContext> _pumpContext(WidgetTester tester, ThemeData theme) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  const dark = ScaffoldColorRoles.defaultColorRoles;
  const light = ScaffoldColorRoles.lightColorRoles;
  final defaultPalette = ScaffoldPalette.defaultPalette;
  final lightPalette = ScaffoldPalette.lightPalette;

  const a = ScaffoldColorRoles(
    accent: Color(0xFF010101),
    accentOnSurface: Color(0xFF020202),
    accentSecondaryOnSurface: Color(0xFF070707),
    accentTextOnSurface: Color(0xFF080808),
    borderControl: Color(0xFF030303),
    inputForeground: Color(0xFF040404),
    sheetForeground: Color(0xFF050505),
    sheetDivider: Color(0xFF060606),
  );
  const b = ScaffoldColorRoles(
    accent: Color(0xFF101010),
    accentOnSurface: Color(0xFF202020),
    accentSecondaryOnSurface: Color(0xFF707070),
    accentTextOnSurface: Color(0xFF808080),
    borderControl: Color(0xFF303030),
    inputForeground: Color(0xFF404040),
    sheetForeground: Color(0xFF505050),
    sheetDivider: Color(0xFF606060),
  );

  void expectRoles(ScaffoldColorRoles actual, ScaffoldColorRoles expected) {
    expect(actual.accent.toARGB32(), expected.accent.toARGB32());
    expect(
      actual.accentOnSurface.toARGB32(),
      expected.accentOnSurface.toARGB32(),
    );
    expect(
      actual.accentSecondaryOnSurface.toARGB32(),
      expected.accentSecondaryOnSurface.toARGB32(),
    );
    expect(
      actual.accentTextOnSurface.toARGB32(),
      expected.accentTextOnSurface.toARGB32(),
    );
    expect(actual.borderControl.toARGB32(), expected.borderControl.toARGB32());
    expect(
      actual.inputForeground.toARGB32(),
      expected.inputForeground.toARGB32(),
    );
    expect(
      actual.sheetForeground.toARGB32(),
      expected.sheetForeground.toARGB32(),
    );
    expect(actual.sheetDivider.toARGB32(), expected.sheetDivider.toARGB32());
  }

  group('defaults', () {
    test('dark roles equal what the widgets drew before', () {
      expect(
        dark.accent.toARGB32(),
        defaultPalette.lightGreenPrimary.toARGB32(),
      );
      expect(
        dark.accentOnSurface.toARGB32(),
        defaultPalette.lightGreenPrimary.toARGB32(),
      );
      expect(
        dark.accentSecondaryOnSurface.toARGB32(),
        defaultPalette.lightGreenSecondary.toARGB32(),
      );
      expect(
        dark.accentTextOnSurface.toARGB32(),
        defaultPalette.lightGreenPrimary.toARGB32(),
      );
      expect(
        dark.borderControl.toARGB32(),
        defaultPalette.borderGrey.toARGB32(),
      );
      expect(dark.inputForeground.toARGB32(), 0xFFFFFFFF);
      expect(dark.sheetForeground.toARGB32(), 0xFFFFFFFF);
      expect(dark.sheetDivider.toARGB32(), 0x1FFFFFFF);
    });

    test(
      'light roles differ from dark in the accent foregrounds, borderControl and the input and sheet colors',
      () {
        expect(light.accent.toARGB32(), dark.accent.toARGB32());
        expect(light.accentOnSurface.toARGB32(), 0xFF00956F);
        expect(light.accentSecondaryOnSurface.toARGB32(), 0xFF01956D);
        expect(light.accentTextOnSurface.toARGB32(), 0xFF00795A);
        expect(
          light.borderControl.toARGB32(),
          lightPalette.borderGrey.toARGB32(),
        );
        expect(light.inputForeground.toARGB32(), 0xFF17191E);
        expect(light.sheetForeground.toARGB32(), 0xFF17191E);
        expect(light.sheetDivider.toARGB32(), 0x1F000000);
      },
    );
  });

  group('fallbackFor', () {
    final custom = defaultPalette.copyWith(
      lightGreenPrimary: const Color(0xFF010203),
      borderGrey: const Color(0xFF040506),
    );

    test('dark takes palette colors and the dark white tokens', () {
      final roles = ScaffoldColorRoles.fallbackFor(custom, Brightness.dark);
      expect(roles.accent.toARGB32(), 0xFF010203);
      expect(roles.accentOnSurface.toARGB32(), 0xFF010203);
      expect(roles.accentTextOnSurface.toARGB32(), 0xFF010203);
      expect(
        roles.accentSecondaryOnSurface.toARGB32(),
        custom.lightGreenSecondary.toARGB32(),
      );
      expect(roles.borderControl.toARGB32(), 0xFF040506);
      expect(roles.inputForeground.toARGB32(), dark.inputForeground.toARGB32());
      expect(roles.sheetForeground.toARGB32(), dark.sheetForeground.toARGB32());
      expect(roles.sheetDivider.toARGB32(), dark.sheetDivider.toARGB32());
    });

    test(
      'light takes the fill and border from the palette and the accent foregrounds from the light tokens',
      () {
        final roles = ScaffoldColorRoles.fallbackFor(custom, Brightness.light);
        expect(roles.accent.toARGB32(), 0xFF010203);
        expect(
          roles.accentOnSurface.toARGB32(),
          light.accentOnSurface.toARGB32(),
        );
        expect(
          roles.accentSecondaryOnSurface.toARGB32(),
          light.accentSecondaryOnSurface.toARGB32(),
        );
        expect(
          roles.accentTextOnSurface.toARGB32(),
          light.accentTextOnSurface.toARGB32(),
        );
        expect(roles.borderControl.toARGB32(), 0xFF040506);
        expect(
          roles.inputForeground.toARGB32(),
          light.inputForeground.toARGB32(),
        );
        expect(
          roles.sheetForeground.toARGB32(),
          light.sheetForeground.toARGB32(),
        );
        expect(roles.sheetDivider.toARGB32(), light.sheetDivider.toARGB32());
      },
    );
  });

  group('fallbackForPalette', () {
    test('dark surfaces get the dark tokens', () {
      final roles = ScaffoldColorRoles.fallbackForPalette(defaultPalette);
      expect(
        roles.accentOnSurface.toARGB32(),
        defaultPalette.lightGreenPrimary.toARGB32(),
      );
      expect(
        roles.accentTextOnSurface.toARGB32(),
        defaultPalette.lightGreenPrimary.toARGB32(),
      );
      expect(
        roles.accentSecondaryOnSurface.toARGB32(),
        defaultPalette.lightGreenSecondary.toARGB32(),
      );
      expect(roles.inputForeground.toARGB32(), dark.inputForeground.toARGB32());
      expect(roles.sheetForeground.toARGB32(), dark.sheetForeground.toARGB32());
      expect(roles.sheetDivider.toARGB32(), dark.sheetDivider.toARGB32());
    });

    test('light surfaces get the light tokens', () {
      final roles = ScaffoldColorRoles.fallbackForPalette(lightPalette);
      expect(
        roles.accentOnSurface.toARGB32(),
        light.accentOnSurface.toARGB32(),
      );
      expect(
        roles.accentTextOnSurface.toARGB32(),
        light.accentTextOnSurface.toARGB32(),
      );
      expect(
        roles.accentSecondaryOnSurface.toARGB32(),
        light.accentSecondaryOnSurface.toARGB32(),
      );
      expect(
        roles.inputForeground.toARGB32(),
        light.inputForeground.toARGB32(),
      );
      expect(
        roles.sheetForeground.toARGB32(),
        light.sheetForeground.toARGB32(),
      );
      expect(roles.sheetDivider.toARGB32(), light.sheetDivider.toARGB32());
    });

    test('input and sheet follow their own surface', () {
      final mixed = defaultPalette.copyWith(
        grayPrimary: lightPalette.grayPrimary,
      );
      final roles = ScaffoldColorRoles.fallbackForPalette(mixed);
      expect(
        roles.inputForeground.toARGB32(),
        light.inputForeground.toARGB32(),
      );
      expect(roles.sheetForeground.toARGB32(), dark.sheetForeground.toARGB32());
    });
  });

  group('context.colorRoles', () {
    testWidgets('returns a registered instance', (tester) async {
      final context = await _pumpContext(
        tester,
        ThemeData(extensions: const [b]),
      );
      expect(identical(context.colorRoles, b), isTrue);
    });

    testWidgets('unregistered dark derives from the palette', (tester) async {
      final context = await _pumpContext(
        tester,
        ThemeData(brightness: Brightness.dark, extensions: [defaultPalette]),
      );
      expectRoles(
        context.colorRoles,
        ScaffoldColorRoles.fallbackFor(defaultPalette, Brightness.dark),
      );
    });

    testWidgets('unregistered light derives from the light palette', (
      tester,
    ) async {
      final context = await _pumpContext(
        tester,
        ThemeData(brightness: Brightness.light, extensions: [lightPalette]),
      );
      expectRoles(
        context.colorRoles,
        ScaffoldColorRoles.fallbackFor(lightPalette, Brightness.light),
      );
      expect(
        context.colorRoles.borderControl.toARGB32(),
        lightPalette.borderGrey.toARGB32(),
      );
    });
  });

  group('surfaceEdge', () {
    const edge = Color(0x1F123456);
    const withEdge = ScaffoldColorRoles(surfaceEdge: edge);

    test('is null in the defaults and both fallbacks', () {
      expect(dark.surfaceEdge, isNull);
      expect(light.surfaceEdge, isNull);
      expect(
        ScaffoldColorRoles.fallbackFor(
          defaultPalette,
          Brightness.dark,
        ).surfaceEdge,
        isNull,
      );
      expect(
        ScaffoldColorRoles.fallbackFor(
          lightPalette,
          Brightness.light,
        ).surfaceEdge,
        isNull,
      );
      expect(
        ScaffoldColorRoles.fallbackForPalette(defaultPalette).surfaceEdge,
        isNull,
      );
      expect(
        ScaffoldColorRoles.fallbackForPalette(lightPalette).surfaceEdge,
        isNull,
      );
    });

    test('copyWith sets it and keeps it', () {
      expect(a.copyWith(surfaceEdge: edge).surfaceEdge, edge);
      expect(withEdge.copyWith().surfaceEdge, edge);
      expect(
        withEdge.copyWith(accent: const Color(0xFF111111)).surfaceEdge,
        edge,
      );
    });

    test('lerp keeps null, blends two values', () {
      expect(a.lerp(b, 0.5).surfaceEdge, isNull);
      const other = ScaffoldColorRoles(surfaceEdge: Color(0x1F654321));
      expect(
        withEdge.lerp(other, 0.5).surfaceEdge,
        Color.lerp(edge, other.surfaceEdge, 0.5),
      );
    });
  });

  group('scrim', () {
    const scrim = Color(0x99000000);
    const withScrim = ScaffoldColorRoles(scrim: scrim);

    test('is null in the defaults and every fallback', () {
      for (final roles in [
        dark,
        light,
        ScaffoldColorRoles.fallbackFor(defaultPalette, Brightness.dark),
        ScaffoldColorRoles.fallbackFor(lightPalette, Brightness.light),
        ScaffoldColorRoles.fallbackForPalette(defaultPalette),
        ScaffoldColorRoles.fallbackForPalette(lightPalette),
      ]) {
        expect(roles.scrim, isNull);
      }
    });

    test('copyWith sets it and keeps it', () {
      expect(a.copyWith(scrim: scrim).scrim, scrim);
      expect(withScrim.copyWith().scrim, scrim);
      expect(withScrim.copyWith(accent: const Color(0xFF111111)).scrim, scrim);
    });

    test('lerp keeps null, blends two values', () {
      expect(a.lerp(b, 0.5).scrim, isNull);
      const other = ScaffoldColorRoles(scrim: Color(0x33000000));
      expect(
        withScrim.lerp(other, 0.5).scrim,
        Color.lerp(scrim, other.scrim, 0.5),
      );
    });
  });

  group('checkbox roles', () {
    const fill = Color(0xFF0AAEE6);
    const mark = Color(0xFF000B18);
    const edge = Color(0xFF0A6885);
    const withCheckbox = ScaffoldColorRoles(
      checkboxFill: fill,
      checkboxMark: mark,
      checkboxEdge: edge,
    );

    test('are null in the defaults and every fallback', () {
      for (final roles in [
        dark,
        light,
        ScaffoldColorRoles.fallbackFor(defaultPalette, Brightness.dark),
        ScaffoldColorRoles.fallbackFor(lightPalette, Brightness.light),
        ScaffoldColorRoles.fallbackForPalette(defaultPalette),
        ScaffoldColorRoles.fallbackForPalette(lightPalette),
      ]) {
        expect(roles.checkboxFill, isNull);
        expect(roles.checkboxMark, isNull);
        expect(roles.checkboxEdge, isNull);
      }
    });

    test('copyWith sets them and keeps them', () {
      final changed = a.copyWith(
        checkboxFill: fill,
        checkboxMark: mark,
        checkboxEdge: edge,
      );
      expect(changed.checkboxFill, fill);
      expect(changed.checkboxMark, mark);
      expect(changed.checkboxEdge, edge);
      final kept = withCheckbox.copyWith(accent: const Color(0xFF111111));
      expect(kept.checkboxFill, fill);
      expect(kept.checkboxMark, mark);
      expect(kept.checkboxEdge, edge);
    });

    test('lerp keeps null, blends two values', () {
      final nulls = a.lerp(b, 0.5);
      expect(nulls.checkboxFill, isNull);
      expect(nulls.checkboxMark, isNull);
      expect(nulls.checkboxEdge, isNull);
      const other = ScaffoldColorRoles(
        checkboxFill: Color(0xFF000000),
        checkboxMark: Color(0xFF000000),
        checkboxEdge: Color(0xFF000000),
      );
      final mixed = withCheckbox.lerp(other, 0.5);
      expect(mixed.checkboxFill, Color.lerp(fill, other.checkboxFill, 0.5));
      expect(mixed.checkboxMark, Color.lerp(mark, other.checkboxMark, 0.5));
      expect(mixed.checkboxEdge, Color.lerp(edge, other.checkboxEdge, 0.5));
    });
  });

  group('hoverFill and hoverEdge', () {
    const fill = Color(0x1F123456);
    const edge = Color(0x3D123456);
    const hovered = ScaffoldColorRoles(hoverFill: fill, hoverEdge: edge);

    test('are null in the defaults and every fallback', () {
      for (final roles in [
        dark,
        light,
        ScaffoldColorRoles.fallbackFor(defaultPalette, Brightness.dark),
        ScaffoldColorRoles.fallbackFor(lightPalette, Brightness.light),
        ScaffoldColorRoles.fallbackForPalette(defaultPalette),
        ScaffoldColorRoles.fallbackForPalette(lightPalette),
      ]) {
        expect(roles.hoverFill, isNull);
        expect(roles.hoverEdge, isNull);
      }
    });

    test('copyWith sets and keeps them', () {
      expect(a.copyWith(hoverFill: fill).hoverFill, fill);
      expect(a.copyWith(hoverEdge: edge).hoverEdge, edge);
      final kept = hovered.copyWith(accent: const Color(0xFF111111));
      expect(kept.hoverFill, fill);
      expect(kept.hoverEdge, edge);
    });

    test('lerp keeps null, blends two values', () {
      expect(a.lerp(b, 0.5).hoverFill, isNull);
      expect(a.lerp(b, 0.5).hoverEdge, isNull);
      const other = ScaffoldColorRoles(
        hoverFill: Color(0x1F654321),
        hoverEdge: Color(0x3D654321),
      );
      final mid = hovered.lerp(other, 0.5);
      expect(mid.hoverFill, Color.lerp(fill, other.hoverFill, 0.5));
      expect(mid.hoverEdge, Color.lerp(edge, other.hoverEdge, 0.5));
    });
  });

  group('copyWith', () {
    test('no arguments keeps every field', () {
      expectRoles(a.copyWith(), a);
    });

    test('each argument changes only its field', () {
      const x = Color(0xFFABCDEF);
      expectRoles(
        a.copyWith(accent: x),
        const ScaffoldColorRoles(
          accent: x,
          accentOnSurface: Color(0xFF020202),
          accentSecondaryOnSurface: Color(0xFF070707),
          accentTextOnSurface: Color(0xFF080808),
          borderControl: Color(0xFF030303),
          inputForeground: Color(0xFF040404),
          sheetForeground: Color(0xFF050505),
          sheetDivider: Color(0xFF060606),
        ),
      );
      expect(a.copyWith(accentOnSurface: x).accentOnSurface, x);
      expect(a.copyWith(accentOnSurface: x).accent, a.accent);
      expect(
        a.copyWith(accentSecondaryOnSurface: x).accentSecondaryOnSurface,
        x,
      );
      expect(
        a.copyWith(accentSecondaryOnSurface: x).accentTextOnSurface,
        a.accentTextOnSurface,
      );
      expect(a.copyWith(accentTextOnSurface: x).accentTextOnSurface, x);
      expect(
        a.copyWith(accentTextOnSurface: x).accentSecondaryOnSurface,
        a.accentSecondaryOnSurface,
      );
      expect(a.copyWith(borderControl: x).borderControl, x);
      expect(a.copyWith(borderControl: x).sheetDivider, a.sheetDivider);
      expect(a.copyWith(inputForeground: x).inputForeground, x);
      expect(a.copyWith(inputForeground: x).borderControl, a.borderControl);
      expect(a.copyWith(sheetForeground: x).sheetForeground, x);
      expect(a.copyWith(sheetForeground: x).inputForeground, a.inputForeground);
      expect(a.copyWith(sheetDivider: x).sheetDivider, x);
      expect(a.copyWith(sheetDivider: x).sheetForeground, a.sheetForeground);
    });
  });

  group('lerp', () {
    test('endpoints equal the operands', () {
      expectRoles(a.lerp(b, 0.0), a);
      expectRoles(a.lerp(b, 1.0), b);
    });

    test('midpoint blends a field', () {
      final mid = a.lerp(b, 0.5);
      expect(mid.accent, Color.lerp(a.accent, b.accent, 0.5));
      expect(
        mid.accentSecondaryOnSurface,
        Color.lerp(a.accentSecondaryOnSurface, b.accentSecondaryOnSurface, 0.5),
      );
      expect(
        mid.accentTextOnSurface,
        Color.lerp(a.accentTextOnSurface, b.accentTextOnSurface, 0.5),
      );
    });

    test('a non-ScaffoldColorRoles returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });
}
