import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
