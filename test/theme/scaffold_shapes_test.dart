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
