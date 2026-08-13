import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Container _badgeContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.descendant(
      of: find.byType(ScaffoldBadge),
      matching: find.byType(Container),
    ),
  );
}

Text _badgeText(WidgetTester tester) {
  return tester.widget<Text>(
    find.descendant(
      of: find.byType(ScaffoldBadge),
      matching: find.byType(Text),
    ),
  );
}

void main() {
  testWidgets('dot variant renders an 8px circle in lightGreenPrimary', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldBadge(variant: BadgeVariant.dot));

    final Container dot = _badgeContainer(tester);
    expect(dot.constraints, const BoxConstraints.tightFor(width: 8, height: 8));
    final BoxDecoration decoration = dot.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
  });

  testWidgets('count variant renders pill with labelSmall white text', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 5),
    );

    final Container pill = _badgeContainer(tester);
    final BoxDecoration decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(ScaffoldDimens.defaultDimens.radiusPill),
    );

    final Text text = _badgeText(tester);
    expect(text.data, '5');
    expect(text.style?.color, Colors.white);
  });

  testWidgets('count truncates to "99+" beyond maxDigits', (tester) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 150, maxDigits: 2),
    );

    expect(_badgeText(tester).data, '99+');
  });

  testWidgets('count=0 renders empty (SizedBox.shrink)', (tester) async {
    await _pump(tester, const ScaffoldBadge(variant: BadgeVariant.count, count: 0));

    expect(tester.getSize(find.byType(ScaffoldBadge)), Size.zero);
  });

  testWidgets('icon variant renders 16px icon in 24px circle', (tester) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.icon, icon: Icons.star),
    );

    final Container circle = _badgeContainer(tester);
    expect(
      circle.constraints,
      const BoxConstraints.tightFor(width: 24, height: 24),
    );
    final BoxDecoration decoration = circle.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);

    final Icon icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(ScaffoldBadge),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon, Icons.star);
    expect(icon.size, 16);
  });

  testWidgets('text variant renders custom label pill', (tester) async {
    await _pump(tester, const ScaffoldBadge(variant: BadgeVariant.text, text: 'New'));

    final Container pill = _badgeContainer(tester);
    final BoxDecoration decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, ScaffoldPalette.defaultPalette.lightGreenPrimary);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(ScaffoldDimens.defaultDimens.radiusPill),
    );
    expect(_badgeText(tester).data, 'New');
  });

  testWidgets('disabled applies 0.4 opacity', (tester) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.dot, disabled: true),
    );

    final Opacity opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(ScaffoldBadge),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.4);
  });

  testWidgets('badgeColor override replaces default lightGreenPrimary', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.dot, badgeColor: Colors.purple),
    );

    final Container dot = _badgeContainer(tester);
    expect((dot.decoration! as BoxDecoration).color, Colors.purple);
  });

  testWidgets('registers Semantics role status with "5 items" label', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 5),
    );

    final Semantics semantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ScaffoldBadge),
            matching: find.byType(Semantics),
          ),
        )
        .first;
    expect(semantics.properties.role, SemanticsRole.status);
    expect(semantics.properties.label, '5 items');
  });

  testWidgets('hit-tests at a 48x48 touch target', (tester) async {
    await _pump(tester, const ScaffoldBadge(variant: BadgeVariant.dot));

    final Size size = tester.getSize(find.byType(ScaffoldBadge));
    expect(size.width, greaterThanOrEqualTo(ScaffoldDimens.defaultDimens.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(ScaffoldDimens.defaultDimens.minTouchTarget));
  });
}
