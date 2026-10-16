import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_bounce.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_fade.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_pulse.dart';
import 'package:frontend_scaffold/components/scaffold_animated_display_shake.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_search_bar.dart';
import 'package:frontend_scaffold/components/scaffold_selection_indicator_toggle.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const ScaffoldMotionTheme _custom = ScaffoldMotionTheme(
  short: Duration(milliseconds: 777),
  medium: Duration(milliseconds: 888),
  standard: Curves.linear,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ScaffoldMotionTheme? motion,
}) {
  final List<ThemeExtension<dynamic>> extensions =
      List<ThemeExtension<dynamic>>.of(scaffoldThemeExtensions);
  if (motion != null) {
    extensions.add(motion);
  }
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: extensions),
      themeAnimationDuration: Duration.zero,
      home: Scaffold(
        body: ScaffoldMotion(
          reducedMotion: false,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

T _in<T extends Widget>(WidgetTester tester, Type owner) {
  return tester.widget<T>(
    find.descendant(of: find.byType(owner), matching: find.byType(T)),
  );
}

void main() {
  group('selection indicator toggle', () {
    Widget toggle() =>
        ScaffoldSelectionIndicatorToggle(value: true, onChanged: (_) {});

    testWidgets('uses registered motion', (tester) async {
      await _pump(tester, toggle(), motion: _custom);

      final AnimatedPositioned positioned = _in<AnimatedPositioned>(
        tester,
        ScaffoldSelectionIndicatorToggle,
      );
      expect(positioned.duration, const Duration(milliseconds: 777));
      expect(positioned.curve, Curves.linear);
    });

    testWidgets('keeps default motion when nothing is registered',
        (tester) async {
      await _pump(tester, toggle());

      final AnimatedPositioned positioned = _in<AnimatedPositioned>(
        tester,
        ScaffoldSelectionIndicatorToggle,
      );
      expect(positioned.duration, const Duration(milliseconds: 150));
      expect(positioned.curve, Curves.easeInOut);
    });
  });

  group('search bar', () {
    testWidgets('results panel uses registered medium duration',
        (tester) async {
      await _pump(tester, const ScaffoldSearchBar(), motion: _custom);

      expect(
        _in<AnimatedSize>(tester, ScaffoldSearchBar).duration,
        const Duration(milliseconds: 888),
      );
    });

    testWidgets('results panel keeps default duration', (tester) async {
      await _pump(tester, const ScaffoldSearchBar());

      expect(
        _in<AnimatedSize>(tester, ScaffoldSearchBar).duration,
        const Duration(milliseconds: 300),
      );
    });
  });

  group('animated display', () {
    const ScaffoldMotionTheme slowLinear = ScaffoldMotionTheme(
      short: Duration(milliseconds: 1000),
      medium: Duration(milliseconds: 900),
      standard: Curves.linear,
    );

    double fadeOpacity(WidgetTester tester) {
      return _in<FadeTransition>(tester, ScaffoldAnimatedDisplayFade)
          .opacity
          .value;
    }

    testWidgets('fade follows registered medium duration and standard curve',
        (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayFade(child: Text('x')),
        motion: slowLinear,
      );
      await tester.pump(const Duration(milliseconds: 450));

      expect(fadeOpacity(tester), closeTo(0.5, 0.02));
    });

    testWidgets('fade is complete at 450 ms with default motion',
        (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayFade(child: Text('x')),
      );
      await tester.pump(const Duration(milliseconds: 450));

      expect(fadeOpacity(tester), 1.0);
    });

    testWidgets('pulse follows registered short duration', (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayPulse(child: Text('x')),
        motion: slowLinear,
      );
      await tester.pump(const Duration(milliseconds: 500));

      final double scale =
          _in<ScaleTransition>(tester, ScaffoldAnimatedDisplayPulse)
              .scale
              .value;
      expect(scale, closeTo(1.025, 0.002));
    });

    testWidgets('explicit duration wins over the theme', (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayFade(
          duration: Duration(milliseconds: 100),
          child: Text('x'),
        ),
        motion: slowLinear,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(fadeOpacity(tester), 1.0);
    });

    testWidgets('explicit curve wins over the theme', (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayFade(
          curve: Curves.easeIn,
          child: Text('x'),
        ),
        motion: slowLinear,
      );
      await tester.pump(const Duration(milliseconds: 450));

      expect(fadeOpacity(tester), lessThan(0.4));
    });

    testWidgets('changing the duration argument updates the controller',
        (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayFade(
          trigger: 1,
          duration: Duration(milliseconds: 1000),
          child: Text('x'),
        ),
        motion: slowLinear,
      );
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayFade(
          trigger: 2,
          duration: Duration(milliseconds: 100),
          child: Text('x'),
        ),
        motion: slowLinear,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fadeOpacity(tester), 1.0);
    });

    testWidgets('shake and bounce run under a registered theme',
        (tester) async {
      await _pump(
        tester,
        const ScaffoldAnimatedDisplayShake(child: Text('x')),
        motion: slowLinear,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        const ScaffoldAnimatedDisplayBounce(child: Text('x')),
        motion: slowLinear,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
