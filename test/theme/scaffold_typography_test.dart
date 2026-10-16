import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';

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
  const a = ScaffoldTypography(
    inputStyle: TextStyle(fontFamily: 'Roboto', fontSize: 10.0),
    monoFontFamily: 'monospace',
  );
  const b = ScaffoldTypography(
    inputStyle: TextStyle(fontFamily: 'Roboto', fontSize: 20.0),
    monoFontFamily: 'Courier',
  );

  group('defaults', () {
    test('inputStyle matches the text field style without a color', () {
      expect(
        ScaffoldTypography.defaultTypography.inputStyle,
        const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.0,
        ),
      );
      expect(ScaffoldTypography.defaultTypography.inputStyle.color, isNull);
    });

    test('monoFontFamily is monospace', () {
      expect(ScaffoldTypography.defaultTypography.monoFontFamily, 'monospace');
    });

    test('const ScaffoldTypography() is the default', () {
      const t = ScaffoldTypography();
      expect(t.inputStyle, ScaffoldTypography.defaultTypography.inputStyle);
      expect(t.monoFontFamily, ScaffoldTypography.defaultTypography.monoFontFamily);
    });
  });

  group('copyWith', () {
    test('changes only the given field', () {
      final style = a.copyWith(inputStyle: b.inputStyle);
      expect(style.inputStyle, b.inputStyle);
      expect(style.monoFontFamily, a.monoFontFamily);
      final family = a.copyWith(monoFontFamily: 'Courier');
      expect(family.inputStyle, a.inputStyle);
      expect(family.monoFontFamily, 'Courier');
    });

    test('no arguments keeps every field', () {
      final c = a.copyWith();
      expect(c.inputStyle, a.inputStyle);
      expect(c.monoFontFamily, a.monoFontFamily);
    });
  });

  group('lerp', () {
    test('endpoints', () {
      final start = a.lerp(b, 0.0);
      final end = a.lerp(b, 1.0);
      expect(start.inputStyle, a.inputStyle);
      expect(start.monoFontFamily, a.monoFontFamily);
      expect(end.inputStyle, b.inputStyle);
      expect(end.monoFontFamily, b.monoFontFamily);
    });

    test('inputStyle interpolates and the family snaps at 0.5', () {
      expect(a.lerp(b, 0.5).inputStyle.fontSize, 15.0);
      expect(a.lerp(b, 0.49).monoFontFamily, a.monoFontFamily);
      expect(a.lerp(b, 0.5).monoFontFamily, b.monoFontFamily);
    });

    test('non-ScaffoldTypography returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });

  group('context.typography', () {
    testWidgets('unregistered gives defaultTypography', (tester) async {
      final context = await _pumpContext(tester, ThemeData.dark());
      expect(
        identical(context.typography, ScaffoldTypography.defaultTypography),
        isTrue,
      );
    });

    testWidgets('registered extension wins', (tester) async {
      final context = await _pumpContext(
        tester,
        ThemeData(extensions: const [b]),
      );
      expect(identical(context.typography, b), isTrue);
    });
  });
}
