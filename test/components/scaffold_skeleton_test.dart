import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_skeleton.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reducedMotion = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: ScaffoldMotion(reducedMotion: reducedMotion, child: child),
        ),
      ),
    ),
  );
}

List<Container> _containers(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(ScaffoldSkeleton),
          matching: find.byType(Container),
        ),
      )
      .toList();
}

Container _baseContainer(WidgetTester tester) {
  return _containers(tester).firstWhere((Container c) {
    final Decoration? decoration = c.decoration;
    return decoration is BoxDecoration &&
        decoration.color == ScaffoldPalette.defaultPalette.skeletonBaseColor;
  });
}

Container _shimmerContainer(WidgetTester tester) {
  return _containers(tester).firstWhere((Container c) {
    final Decoration? decoration = c.decoration;
    return decoration is BoxDecoration && decoration.gradient != null;
  });
}

void main() {
  testWidgets('renders rounded-rect base with skeletonBaseColor + corner radius', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSkeleton(width: 120, height: 40));

    final Container base = _baseContainer(tester);
    final BoxDecoration decoration = base.decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.skeletonBaseColor);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(ScaffoldDimens.defaultDimens.skeletonCornerRadius),
    );
  });

  testWidgets('shimmer has a running LinearGradient sweep with shimmer color', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldSkeleton(width: 120, height: 40));

    final Container shimmer = _shimmerContainer(tester);
    final BoxDecoration decoration = shimmer.decoration! as BoxDecoration;
    final LinearGradient gradient = decoration.gradient! as LinearGradient;
    expect(
      gradient.colors,
      contains(ScaffoldPalette.defaultPalette.skeletonShimmerColor),
    );
    expect(gradient.colors.first, ScaffoldPalette.defaultPalette.skeletonBaseColor);
    expect(gradient.colors.last, ScaffoldPalette.defaultPalette.skeletonBaseColor);

    // The AnimationController is running: the gradient sweep alignment moves.
    final AlignmentGeometry before = gradient.begin;
    await tester.pump(const Duration(milliseconds: 150));
    final LinearGradient afterGradient =
        (_shimmerContainer(tester).decoration! as BoxDecoration).gradient!
            as LinearGradient;
    expect(afterGradient.begin, isNot(before));
  });

  testWidgets('reducedMotion uses static pulse opacity with no horizontal sweep', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldSkeleton(width: 120, height: 40),
      reducedMotion: true,
    );

    final Finder fadeFinder = find.descendant(
      of: find.byType(ScaffoldSkeleton),
      matching: find.byType(FadeTransition),
    );
    expect(fadeFinder, findsOneWidget);

    // No shimmer gradient is present (no horizontal sweep).
    expect(_containers(tester).where((Container c) {
      final Decoration? decoration = c.decoration;
      return decoration is BoxDecoration && decoration.gradient != null;
    }), isEmpty);

    final FadeTransition fade = tester.widget<FadeTransition>(fadeFinder);
    final double before = fade.opacity.value;
    expect(before, greaterThanOrEqualTo(0.6));
    expect(before, lessThanOrEqualTo(1.0));

    await tester.pump(const Duration(milliseconds: 150));
    final FadeTransition after = tester.widget<FadeTransition>(fadeFinder);
    expect(after.opacity.value, isNot(before));
    expect(after.opacity.value, greaterThanOrEqualTo(0.6));
    expect(after.opacity.value, lessThanOrEqualTo(1.0));
  });

  testWidgets('explicit width, height, and borderRadius override defaults', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldSkeleton(width: 200, height: 20, borderRadius: 8),
    );

    expect(tester.getSize(find.byType(ScaffoldSkeleton)), const Size(200, 20));
    final BoxDecoration decoration =
        _baseContainer(tester).decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(8));
  });
}
