// A compile or test failure here is a consumer-visible break for apps that
// register these constants in their own const extension lists.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_gradients.dart';
import 'package:frontend_scaffold/theme/scaffold_motion_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_shadows.dart';
import 'package:frontend_scaffold/theme/scaffold_shapes.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';

const List<ThemeExtension<dynamic>> _lightExtensions = [
  ScaffoldPalette.lightPalette,
  ScaffoldDimens.defaultDimens,
];

const List<ThemeExtension<dynamic>> _darkExtensions = [
  ScaffoldPalette.defaultPalette,
  ScaffoldDimens.defaultDimens,
];

void main() {
  test('light registration resolves the same const instances', () {
    final ThemeData theme = ThemeData(extensions: _lightExtensions);
    expect(
      identical(theme.extension<ScaffoldPalette>(), ScaffoldPalette.lightPalette),
      isTrue,
    );
    expect(
      identical(theme.extension<ScaffoldDimens>(), ScaffoldDimens.defaultDimens),
      isTrue,
    );
  });

  test('dark registration resolves the same const instances', () {
    final ThemeData theme = ThemeData(extensions: _darkExtensions);
    expect(
      identical(theme.extension<ScaffoldPalette>(), ScaffoldPalette.defaultPalette),
      isTrue,
    );
    expect(
      identical(theme.extension<ScaffoldDimens>(), ScaffoldDimens.defaultDimens),
      isTrue,
    );
  });

  test('scaffoldThemeExtensions holds the dark palette then the dimens', () {
    expect(scaffoldThemeExtensions, hasLength(2));
    expect(identical(scaffoldThemeExtensions[0], ScaffoldPalette.defaultPalette), isTrue);
    expect(identical(scaffoldThemeExtensions[1], ScaffoldDimens.defaultDimens), isTrue);
  });

  group('new getters resolve defaults under the old registrations', () {
    Future<BuildContext> pumpContext(
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

    testWidgets('light registration', (tester) async {
      final context = await pumpContext(
        tester,
        ThemeData(brightness: Brightness.light, extensions: _lightExtensions),
      );
      expect(identical(context.shadows, ScaffoldShadows.lightShadows), isTrue);
      expect(identical(context.motion, ScaffoldMotionTheme.defaultMotion), isTrue);
      expect(
        identical(context.typography, ScaffoldTypography.defaultTypography),
        isTrue,
      );
      expect(
        identical(context.gradients, ScaffoldGradients.defaultGradients),
        isTrue,
      );
      expect(identical(context.shapes, ScaffoldShapes.defaultShapes), isTrue);
      expect(context.colorRoles.accent, ScaffoldPalette.lightPalette.lightGreenPrimary);
      expect(context.colorRoles.accentOnSurface, const Color(0xFF00956F));
      expect(context.colorRoles.borderControl, ScaffoldPalette.lightPalette.borderGrey);
    });

    testWidgets('dark registration', (tester) async {
      final context = await pumpContext(
        tester,
        ThemeData(brightness: Brightness.dark, extensions: _darkExtensions),
      );
      expect(identical(context.shadows, ScaffoldShadows.defaultShadows), isTrue);
      expect(identical(context.motion, ScaffoldMotionTheme.defaultMotion), isTrue);
      expect(
        identical(context.typography, ScaffoldTypography.defaultTypography),
        isTrue,
      );
      expect(
        identical(context.gradients, ScaffoldGradients.defaultGradients),
        isTrue,
      );
      expect(identical(context.shapes, ScaffoldShapes.defaultShapes), isTrue);
      expect(context.colorRoles.accent, ScaffoldPalette.defaultPalette.lightGreenPrimary);
      expect(
        context.colorRoles.accentOnSurface,
        ScaffoldPalette.defaultPalette.lightGreenPrimary,
      );
      expect(context.colorRoles.borderControl, ScaffoldPalette.defaultPalette.borderGrey);
    });
  });

  test('ScaffoldPalette and ScaffoldDimens keep their old named parameters', () {
    // Every parameter is named, so a rename or a new required parameter fails to compile.
    const palette = ScaffoldPalette(
      deepBlueCardColor: Color(0xFF000001),
      lightGreenPrimary: Color(0xFF000002),
      lightGreenSecondary: Color(0xFF000003),
      gray500: Color(0xFF000004),
      blue500: Color(0xFF000005),
      borderGrey: Color(0xFF000006),
      grayPrimary: Color(0xFF000007),
      deepBlueTertiary: Color(0xFF000008),
      surfaceElevated: Color(0xFF000009),
      borderSubtle: Color(0xFF00000A),
      textPrimary: Color(0xFF00000B),
      textSecondary: Color(0xFF00000C),
      statusSuccess: Color(0xFF00000D),
      statusError: Color(0xFF00000E),
      statusWarningText: Color(0xFF00000F),
      focusRingColor: Color(0xFF000010),
      skeletonBaseColor: Color(0xFF000011),
      skeletonShimmerColor: Color(0xFF000012),
      disabledOverlayColor: Color(0xFF000013),
      dragFeedbackBackground: Color(0xFF000014),
      dropZoneHighlight: Color(0xFF000015),
      dropZoneRejected: Color(0xFF000016),
    );
    const dimens = ScaffoldDimens(
      horizontalPadding: 1.5,
      horizontalDesktopPadding: 2.5,
      verticalDesktopPadding: 3.5,
      itemSpacing: 4.5,
      borderRadiusCard: 5.5,
      borderRadiusButton: 6.5,
      appBarHeight: 7.5,
      space2: 8.5,
      space3: 9.5,
      space4: 10.5,
      space6: 11.5,
      space8: 12.5,
      space12: 13.5,
      radiusMd: 14.5,
      radiusPill: 15.5,
      focusRingWidth: 16.5,
      skeletonCornerRadius: 17.5,
      disabledOverlayOpacity: 18.5,
      dragHandleSize: 19.5,
      minTouchTarget: 20.5,
      touchTargetPadding: 21.5,
    );
    expect(palette.deepBlueCardColor, const Color(0xFF000001));
    expect(palette.dropZoneRejected, const Color(0xFF000016));
    expect(dimens.horizontalPadding, 1.5);
    expect(dimens.touchTargetPadding, 21.5);
  });
}
