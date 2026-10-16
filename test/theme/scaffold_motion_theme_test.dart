import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
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

void expectSame(ScaffoldMotionTheme actual, ScaffoldMotionTheme expected) {
  expect(actual.short, expected.short);
  expect(actual.medium, expected.medium);
  expect(actual.long, expected.long);
  expect(identical(actual.standard, expected.standard), isTrue);
  expect(identical(actual.decelerate, expected.decelerate), isTrue);
  expect(identical(actual.emphasized, expected.emphasized), isTrue);
}

void main() {
  const a = ScaffoldMotionTheme(
    short: Duration(milliseconds: 150),
    medium: Duration(milliseconds: 300),
    long: Duration(milliseconds: 500),
    standard: Curves.linear,
    decelerate: Curves.easeIn,
    emphasized: Curves.bounceOut,
  );
  const b = ScaffoldMotionTheme(
    short: Duration(milliseconds: 250),
    medium: Duration(milliseconds: 400),
    long: Duration(milliseconds: 700),
    standard: Curves.ease,
    decelerate: Curves.easeInOut,
    emphasized: Curves.bounceIn,
  );

  group('defaults', () {
    test('durations equal the static tokens', () {
      const d = ScaffoldMotionTheme.defaultMotion;
      expect(d.short, ScaffoldMotionDurations.short);
      expect(d.medium, ScaffoldMotionDurations.medium);
      expect(d.long, ScaffoldMotionDurations.long);
    });

    test('curves are the static tokens', () {
      const d = ScaffoldMotionTheme.defaultMotion;
      expect(identical(d.standard, ScaffoldMotionCurves.standard), isTrue);
      expect(identical(d.decelerate, ScaffoldMotionCurves.decelerate), isTrue);
      expect(identical(d.emphasized, ScaffoldMotionCurves.emphasized), isTrue);
    });

    test('const ScaffoldMotionTheme() is the default', () {
      expectSame(const ScaffoldMotionTheme(), ScaffoldMotionTheme.defaultMotion);
    });
  });

  group('copyWith', () {
    test('each parameter changes only its field', () {
      const base = ScaffoldMotionTheme.defaultMotion;
      const d = Duration(milliseconds: 1);
      final cases = <String, ScaffoldMotionTheme>{
        'short': base.copyWith(short: d),
        'medium': base.copyWith(medium: d),
        'long': base.copyWith(long: d),
        'standard': base.copyWith(standard: Curves.linear),
        'decelerate': base.copyWith(decelerate: Curves.linear),
        'emphasized': base.copyWith(emphasized: Curves.linear),
      };
      for (final entry in cases.entries) {
        final c = entry.value;
        final k = entry.key;
        expect(c.short == d, k == 'short', reason: k);
        expect(c.medium == d, k == 'medium', reason: k);
        expect(c.long == d, k == 'long', reason: k);
        expect(identical(c.standard, Curves.linear), k == 'standard', reason: k);
        expect(identical(c.decelerate, Curves.linear), k == 'decelerate',
            reason: k);
        expect(identical(c.emphasized, Curves.linear), k == 'emphasized',
            reason: k);
      }
    });

    test('no arguments keeps every field', () {
      expectSame(a.copyWith(), a);
    });
  });

  group('lerp', () {
    test('endpoints', () {
      expectSame(a.lerp(b, 0.0), a);
      expectSame(a.lerp(b, 1.0), b);
    });

    test('durations interpolate and round', () {
      expect(a.lerp(b, 0.5).short, const Duration(milliseconds: 200));
    });

    test('curves snap at 0.5', () {
      expect(identical(a.lerp(b, 0.49).standard, a.standard), isTrue);
      expect(identical(a.lerp(b, 0.5).standard, b.standard), isTrue);
    });

    test('non-ScaffoldMotionTheme returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });

  group('context.motion', () {
    for (final theme in [ThemeData.light(), ThemeData.dark()]) {
      testWidgets('unregistered ${theme.brightness.name} gives defaultMotion',
          (tester) async {
        final context = await _pumpContext(tester, theme);
        expect(identical(context.motion, ScaffoldMotionTheme.defaultMotion),
            isTrue);
      });
    }

    testWidgets('registered extension wins', (tester) async {
      final context = await _pumpContext(
        tester,
        ThemeData(extensions: const [b]),
      );
      expect(identical(context.motion, b), isTrue);
    });
  });
}
