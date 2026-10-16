import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_gradients.dart';
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
  const gradA = LinearGradient(
    colors: [Color(0xFF000000), Color(0x00000000)],
  );
  const gradB = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
  );
  const a = ScaffoldGradients(edgeFade: gradA);
  const b = ScaffoldGradients(edgeFade: gradB);

  group('defaults', () {
    test('edgeFade is null', () {
      expect(ScaffoldGradients.defaultGradients.edgeFade, isNull);
      expect(const ScaffoldGradients().edgeFade, isNull);
    });
  });

  group('copyWith', () {
    test('sets edgeFade', () {
      expect(
        ScaffoldGradients.defaultGradients.copyWith(edgeFade: gradA).edgeFade,
        gradA,
      );
    });

    test('no argument keeps edgeFade', () {
      expect(a.copyWith().edgeFade, gradA);
    });
  });

  group('lerp', () {
    test('two nulls give null', () {
      final result = ScaffoldGradients.defaultGradients.lerp(
        ScaffoldGradients.defaultGradients,
        0.5,
      );
      expect(result.edgeFade, isNull);
    });

    test('endpoints equal the operands', () {
      expect(a.lerp(b, 0.0).edgeFade!.colors, gradA.colors);
      expect(a.lerp(b, 1.0).edgeFade!.colors, gradB.colors);
    });

    test('a non-ScaffoldGradients returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });

  group('context.gradients', () {
    testWidgets('unregistered gives defaultGradients', (tester) async {
      final context = await _pumpContext(tester, ThemeData());
      expect(
        identical(context.gradients, ScaffoldGradients.defaultGradients),
        isTrue,
      );
    });

    testWidgets('registered extension wins', (tester) async {
      final context = await _pumpContext(
        tester,
        ThemeData(extensions: const [a]),
      );
      expect(identical(context.gradients, a), isTrue);
    });
  });
}
