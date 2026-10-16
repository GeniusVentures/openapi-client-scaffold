import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_shapes.dart';
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
  const a = ScaffoldShapes(inputFocusedBorderWidth: 2.0);
  const b = ScaffoldShapes(inputFocusedBorderWidth: 4.0);

  group('defaults', () {
    test('every field is null', () {
      expect(ScaffoldShapes.defaultShapes.inputFocusedBorderWidth, isNull);
      expect(ScaffoldShapes.defaultShapes.sheetRadius, isNull);
      expect(ScaffoldShapes.defaultShapes.checkboxRadius, isNull);
      expect(ScaffoldShapes.defaultShapes.checkboxBorderWidth, isNull);
    });

    test('const ScaffoldShapes() is the default', () {
      const s = ScaffoldShapes();
      expect(s.inputFocusedBorderWidth, isNull);
    });
  });

  group('copyWith', () {
    test('changes the given field', () {
      expect(
        a.copyWith(inputFocusedBorderWidth: 3.0).inputFocusedBorderWidth,
        3.0,
      );
    });

    test('no arguments keeps every field', () {
      expect(a.copyWith().inputFocusedBorderWidth, 2.0);
      expect(
        ScaffoldShapes.defaultShapes.copyWith().inputFocusedBorderWidth,
        isNull,
      );
    });
  });

  group('sheetRadius', () {
    const sheet = ScaffoldShapes(sheetRadius: 24.0);

    test('copyWith sets it and keeps it', () {
      expect(a.copyWith(sheetRadius: 12.0).sheetRadius, 12.0);
      expect(sheet.copyWith().sheetRadius, 24.0);
      expect(sheet.copyWith(inputFocusedBorderWidth: 3.0).sheetRadius, 24.0);
    });

    test('lerp keeps null, blends two values', () {
      expect(a.lerp(b, 0.5).sheetRadius, isNull);
      expect(
        sheet.lerp(const ScaffoldShapes(sheetRadius: 8.0), 0.5).sheetRadius,
        16.0,
      );
    });
  });

  group('checkboxRadius and checkboxBorderWidth', () {
    const box = ScaffoldShapes(checkboxRadius: 4.0, checkboxBorderWidth: 1.5);

    test('copyWith sets them and keeps them', () {
      final changed = a.copyWith(checkboxRadius: 6.0, checkboxBorderWidth: 3.0);
      expect(changed.checkboxRadius, 6.0);
      expect(changed.checkboxBorderWidth, 3.0);
      final kept = box.copyWith(sheetRadius: 8.0);
      expect(kept.checkboxRadius, 4.0);
      expect(kept.checkboxBorderWidth, 1.5);
    });

    test('lerp keeps null, blends two values', () {
      expect(a.lerp(b, 0.5).checkboxRadius, isNull);
      expect(a.lerp(b, 0.5).checkboxBorderWidth, isNull);
      const other = ScaffoldShapes(checkboxRadius: 8.0, checkboxBorderWidth: 3.5);
      expect(box.lerp(other, 0.5).checkboxRadius, 6.0);
      expect(box.lerp(other, 0.5).checkboxBorderWidth, 2.5);
    });
  });

  group('lerp', () {
    test('two values interpolate', () {
      expect(a.lerp(b, 0.0).inputFocusedBorderWidth, 2.0);
      expect(a.lerp(b, 0.5).inputFocusedBorderWidth, 3.0);
      expect(a.lerp(b, 1.0).inputFocusedBorderWidth, 4.0);
    });

    test('two nulls stay null', () {
      final result = ScaffoldShapes.defaultShapes.lerp(
        ScaffoldShapes.defaultShapes,
        0.5,
      );
      expect(result.inputFocusedBorderWidth, isNull);
    });

    test('non-ScaffoldShapes returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });

  group('context.shapes', () {
    testWidgets('unregistered gives defaultShapes', (tester) async {
      final context = await _pumpContext(tester, ThemeData.dark());
      expect(identical(context.shapes, ScaffoldShapes.defaultShapes), isTrue);
    });

    testWidgets('registered extension wins', (tester) async {
      final context = await _pumpContext(
        tester,
        ThemeData(extensions: const [b]),
      );
      expect(identical(context.shapes, b), isTrue);
    });
  });
}
