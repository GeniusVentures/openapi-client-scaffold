import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';

void main() {
  group('ScaffoldMotion static constants', () {
    test('durations.short is 150ms', () {
      expect(ScaffoldMotionDurations.short, const Duration(milliseconds: 150));
    });

    test('durations.medium is 300ms', () {
      expect(ScaffoldMotionDurations.medium, const Duration(milliseconds: 300));
    });

    test('durations.long is 500ms', () {
      expect(ScaffoldMotionDurations.long, const Duration(milliseconds: 500));
    });

    test('curves.standard is easeInOut', () {
      expect(ScaffoldMotionCurves.standard, Curves.easeInOut);
    });

    test('curves.decelerate is easeOut', () {
      expect(ScaffoldMotionCurves.decelerate, Curves.easeOut);
    });

    test('curves.emphasized overshoots above 1.0', () {
      final curve = ScaffoldMotionCurves.emphasized;
      var overshoots = false;
      for (var t = 0.0; t < 1.0; t += 0.05) {
        if (curve.transform(t) > 1.0) {
          overshoots = true;
          break;
        }
      }
      expect(overshoots, isTrue,
          reason: 'emphasized curve should exceed 1.0 near t -> 1.0');
    });
  });

  group('ScaffoldMotion InheritedWidget', () {
    testWidgets('reducedMotion true is readable via of(context)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaffoldMotion(
            reducedMotion: true,
            child: Text('child'),
          ),
        ),
      );
      final context = tester.element(find.text('child'));
      expect(ScaffoldMotion.of(context).reducedMotion, isTrue);
    });

    testWidgets('reducedMotion false is readable via of(context)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaffoldMotion(
            reducedMotion: false,
            child: Text('child'),
          ),
        ),
      );
      final context = tester.element(find.text('child'));
      expect(ScaffoldMotion.of(context).reducedMotion, isFalse);
    });

    testWidgets('of(context) falls back to reducedMotion=false without an '
        'ancestor', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('orphan')));
      final context = tester.element(find.text('orphan'));
      expect(ScaffoldMotion.of(context).reducedMotion, isFalse);
    });

    testWidgets('reducedMotion propagates to a nested child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaffoldMotion(
            reducedMotion: true,
            child: Center(child: Text('nested')),
          ),
        ),
      );
      final context = tester.element(find.text('nested'));
      expect(ScaffoldMotion.of(context).reducedMotion, isTrue);
    });
  });
}
