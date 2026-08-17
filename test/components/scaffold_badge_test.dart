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

Future<void> _pumpLight(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[
          ScaffoldPalette.lightPalette,
          ScaffoldDimens.defaultDimens,
        ],
      ),
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

  testWidgets('count variant renders pill with labelSmall dark text on bright fill', (
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
    // lightGreenPrimary (#00EAAE) is a bright fill → on-status color is dark
    // per the WIDG-46 WCAG-AA remediation.
    expect(text.style?.color, const Color(0xFF17191E));
  });

  testWidgets('count truncates to "99+" beyond maxDigits', (tester) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 150, maxDigits: 2),
    );

    expect(_badgeText(tester).data, '99+');
  });

  testWidgets('maxDigits=3 truncates to "999+" and maxDigits=1 to "9+"', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 1000, maxDigits: 3),
    );
    expect(_badgeText(tester).data, '999+');

    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 10, maxDigits: 1),
    );
    expect(_badgeText(tester).data, '9+');
  });

  testWidgets('maxDigits=3 does not truncate a value within range', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldBadge(variant: BadgeVariant.count, count: 999, maxDigits: 3),
    );
    expect(_badgeText(tester).data, '999');
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

  testWidgets('renders at intrinsic size (dot is 8x8, not inflated to 48)', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldBadge(variant: BadgeVariant.dot));

    expect(tester.getSize(find.byType(ScaffoldBadge)), const Size(8, 8));
  });

  group('on-status color resolution (WIDG-46)', () {
    testWidgets(
      'lightGreenPrimary fill renders dark label under defaultPalette',
      (tester) async {
        await _pump(
          tester,
          ScaffoldBadge(
            variant: BadgeVariant.text,
            text: 'OK',
            badgeColor: ScaffoldPalette.defaultPalette.lightGreenPrimary,
          ),
        );

        expect(_badgeText(tester).style?.color, const Color(0xFF17191E));
      },
    );

    testWidgets(
      'lightGreenPrimary fill renders dark label under lightPalette',
      (tester) async {
        await _pumpLight(
          tester,
          ScaffoldBadge(
            variant: BadgeVariant.text,
            text: 'OK',
            badgeColor: ScaffoldPalette.lightPalette.lightGreenPrimary,
          ),
        );

        expect(_badgeText(tester).style?.color, const Color(0xFF17191E));
      },
    );

    testWidgets(
      'statusError fill renders light label under defaultPalette',
      (tester) async {
        await _pump(
          tester,
          ScaffoldBadge(
            variant: BadgeVariant.text,
            text: 'ERR',
            badgeColor: ScaffoldPalette.defaultPalette.statusError,
          ),
        );

        expect(_badgeText(tester).style?.color, const Color(0xFFFFFFFF));
      },
    );

    testWidgets(
      'statusError fill renders light label under lightPalette',
      (tester) async {
        await _pumpLight(
          tester,
          ScaffoldBadge(
            variant: BadgeVariant.text,
            text: 'ERR',
            badgeColor: ScaffoldPalette.lightPalette.statusError,
          ),
        );

        expect(_badgeText(tester).style?.color, const Color(0xFFFFFFFF));
      },
    );

    testWidgets(
      'icon-only badge with lightGreenPrimary fill renders dark icon glyph',
      (tester) async {
        await _pump(
          tester,
          ScaffoldBadge(
            variant: BadgeVariant.icon,
            icon: Icons.check,
            badgeColor: ScaffoldPalette.defaultPalette.lightGreenPrimary,
          ),
        );

        final Icon icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(ScaffoldBadge),
            matching: find.byType(Icon),
          ),
        );
        expect(icon.color, const Color(0xFF17191E));
      },
    );

    testWidgets(
      'icon-only badge with statusError fill renders light icon glyph',
      (tester) async {
        await _pump(
          tester,
          ScaffoldBadge(
            variant: BadgeVariant.icon,
            icon: Icons.close,
            badgeColor: ScaffoldPalette.defaultPalette.statusError,
          ),
        );

        final Icon icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(ScaffoldBadge),
            matching: find.byType(Icon),
          ),
        );
        expect(icon.color, const Color(0xFFFFFFFF));
      },
    );
  });
}
