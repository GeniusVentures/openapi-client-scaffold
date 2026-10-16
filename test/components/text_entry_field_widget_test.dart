import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/text_entry_field_widget.dart';
import 'package:frontend_scaffold/components/text_form_field_logic.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_typography.dart';

Future<TextField> _pumpField(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextEntryFieldWidget(
            logic: TextFormFieldLogic(context, hintText: 'hint'),
          ),
        ),
      ),
    ),
  );
  return tester.widget<TextField>(find.byType(TextField));
}

Color _borderColor(InputBorder? border) {
  return (border! as OutlineInputBorder).borderSide.color;
}

TextStyle _expectedStyle(Color color, {String family = 'Roboto'}) {
  return TextStyle(
    fontFamily: family,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    color: color,
  );
}

void main() {
  final defaultPalette = ScaffoldPalette.defaultPalette;
  final lightPalette = ScaffoldPalette.lightPalette;

  final themes = <String, (ThemeData, ScaffoldPalette, Color)>{
    'dark': (
      ThemeData(
        brightness: Brightness.dark,
        extensions: [defaultPalette, ScaffoldDimens.defaultDimens],
      ),
      defaultPalette,
      const Color(0xFFFFFFFF),
    ),
    'light': (
      ThemeData(
        brightness: Brightness.light,
        extensions: [lightPalette, ScaffoldDimens.defaultDimens],
      ),
      lightPalette,
      const Color(0xFF17191E),
    ),
    // No palette registered: the dark default surfaces get the dark-mode foreground.
    'no extensions': (ThemeData(), defaultPalette, const Color(0xFFFFFFFF)),
  };

  group('defaults equal the values drawn before the tokens', () {
    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        final (theme, palette, typedColor) = entry.value;
        final field = await _pumpField(tester, theme);
        final decoration = field.decoration!;

        expect(field.style, _expectedStyle(typedColor));
        expect(decoration.hintStyle, _expectedStyle(palette.gray500));
        expect(
          _borderColor(decoration.focusedBorder),
          palette.lightGreenPrimary,
        );
        expect(_borderColor(decoration.enabledBorder), palette.borderGrey);
        expect(decoration.fillColor, palette.grayPrimary);
      });
    }
  });

  testWidgets('registered typography and color roles are drawn', (
    tester,
  ) async {
    final field = await _pumpField(
      tester,
      ThemeData(
        extensions: [
          defaultPalette,
          ScaffoldDimens.defaultDimens,
          const ScaffoldTypography(
            inputStyle: TextStyle(fontFamily: 'Courier', fontSize: 20.0),
          ),
          const ScaffoldColorRoles(
            inputForeground: Color(0xFF112233),
            borderControl: Color(0xFF445566),
            accentOnSurface: Color(0xFF778899),
          ),
        ],
      ),
    );
    final decoration = field.decoration!;

    expect(field.style!.fontFamily, 'Courier');
    expect(field.style!.fontSize, 20.0);
    expect(field.style!.color, const Color(0xFF112233));
    expect(decoration.hintStyle!.fontFamily, 'Courier');
    expect(_borderColor(decoration.enabledBorder), const Color(0xFF445566));
    expect(_borderColor(decoration.focusedBorder), const Color(0xFF778899));
  });
}
