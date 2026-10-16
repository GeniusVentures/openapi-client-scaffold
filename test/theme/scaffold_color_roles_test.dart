import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<BuildContext> _pumpContext(
  WidgetTester tester,
  ThemeData theme,
) async {
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
    borderControl: Color(0xFF030303),
    inputForeground: Color(0xFF040404),
    sheetForeground: Color(0xFF050505),
    sheetDivider: Color(0xFF060606),
  );
  const b = ScaffoldColorRoles(
    accent: Color(0xFF101010),
    accentOnSurface: Color(0xFF202020),
    borderControl: Color(0xFF303030),
    inputForeground: Color(0xFF404040),
    sheetForeground: Color(0xFF505050),
    sheetDivider: Color(0xFF606060),
  );

  void expectRoles(ScaffoldColorRoles actual, ScaffoldColorRoles expected) {
    expect(actual.accent.toARGB32(), expected.accent.toARGB32());
    expect(actual.accentOnSurface.toARGB32(), expected.accentOnSurface.toARGB32());
    expect(actual.borderControl.toARGB32(), expected.borderControl.toARGB32());
    expect(actual.inputForeground.toARGB32(), expected.inputForeground.toARGB32());
    expect(actual.sheetForeground.toARGB32(), expected.sheetForeground.toARGB32());
    expect(actual.sheetDivider.toARGB32(), expected.sheetDivider.toARGB32());
  }

  group('defaults', () {
    test('dark roles equal what the widgets drew before', () {
      expect(dark.accent.toARGB32(), defaultPalette.lightGreenPrimary.toARGB32());
      expect(dark.accentOnSurface.toARGB32(), defaultPalette.lightGreenPrimary.toARGB32());
      expect(dark.borderControl.toARGB32(), defaultPalette.borderGrey.toARGB32());
      expect(dark.inputForeground.toARGB32(), 0xFFFFFFFF);
      expect(dark.sheetForeground.toARGB32(), 0xFFFFFFFF);
      expect(dark.sheetDivider.toARGB32(), 0x1FFFFFFF);
    });

    test('light roles differ from dark in borderControl and the input and sheet colors', () {
      expect(light.accent.toARGB32(), dark.accent.toARGB32());
      expect(light.accentOnSurface.toARGB32(), dark.accentOnSurface.toARGB32());
      expect(light.borderControl.toARGB32(), lightPalette.borderGrey.toARGB32());
      expect(light.inputForeground.toARGB32(), 0xFF17191E);
      expect(light.sheetForeground.toARGB32(), 0xFF17191E);
      expect(light.sheetDivider.toARGB32(), 0x1F000000);
    });
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
      expect(roles.borderControl.toARGB32(), 0xFF040506);
      expect(roles.inputForeground.toARGB32(), dark.inputForeground.toARGB32());
      expect(roles.sheetForeground.toARGB32(), dark.sheetForeground.toARGB32());
      expect(roles.sheetDivider.toARGB32(), dark.sheetDivider.toARGB32());
    });

    test('light takes palette colors and the light dark-foreground tokens', () {
      final roles = ScaffoldColorRoles.fallbackFor(custom, Brightness.light);
      expect(roles.accent.toARGB32(), 0xFF010203);
      expect(roles.accentOnSurface.toARGB32(), 0xFF010203);
      expect(roles.borderControl.toARGB32(), 0xFF040506);
      expect(roles.inputForeground.toARGB32(), light.inputForeground.toARGB32());
      expect(roles.sheetForeground.toARGB32(), light.sheetForeground.toARGB32());
      expect(roles.sheetDivider.toARGB32(), light.sheetDivider.toARGB32());
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

    testWidgets('unregistered light derives from the light palette', (tester) async {
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
          borderControl: Color(0xFF030303),
          inputForeground: Color(0xFF040404),
          sheetForeground: Color(0xFF050505),
          sheetDivider: Color(0xFF060606),
        ),
      );
      expect(a.copyWith(accentOnSurface: x).accentOnSurface, x);
      expect(a.copyWith(accentOnSurface: x).accent, a.accent);
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
    });

    test('a non-ScaffoldColorRoles returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });
}
