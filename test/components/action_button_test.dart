import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/action_button.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/presets/midnight_tokens.dart';
import 'package:frontend_scaffold/theme/scaffold_color_roles.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const Key _key = Key('action');

Future<void> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  VoidCallback? onPressed,
  Color? iconColor,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: ActionButton(
              key: _key,
              icon: Icons.send,
              text: 'Send',
              onPressed: onPressed,
              iconColor: iconColor,
            ),
          ),
        ),
      ),
    ),
  );
}

Color? _glyph(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.send)).color;

Color? _caption(WidgetTester tester) =>
    tester.widget<Text>(find.text('Send')).style?.color ??
    tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Send'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style
        .color;

Color? _fill(WidgetTester tester, Set<WidgetState> states) => tester
    .widget<ElevatedButton>(find.byType(ElevatedButton))
    .style
    ?.backgroundColor
    ?.resolve(states);

void main() {
  group('default theme', () {
    testWidgets('enabled glyph stays accentSecondaryOnSurface', (tester) async {
      await _pump(tester, onPressed: () {});
      final roles = tester.element(find.byKey(_key)).colorRoles;
      expect(_glyph(tester), roles.accentSecondaryOnSurface);
    });

    testWidgets('disabled keeps today fill, glyph and caption', (tester) async {
      await _pump(tester);
      final context = tester.element(find.byKey(_key));
      expect(_fill(tester, {WidgetState.disabled}),
          context.palette.deepBlueCardColor);
      expect(_glyph(tester), context.colorRoles.accentSecondaryOnSurface);
      expect(_caption(tester), context.palette.gray500);
    });

    testWidgets('caller iconColor wins when enabled', (tester) async {
      await _pump(tester, onPressed: () {}, iconColor: Colors.pink);
      expect(_glyph(tester), Colors.pink);
    });
  });

  for (final brightness in [Brightness.dark, Brightness.light]) {
    final roles = brightness == Brightness.dark
        ? Midnight.darkColorRoles
        : Midnight.lightColorRoles;

    group('midnight $brightness', () {
      testWidgets('enabled glyph is the on-surface accent', (tester) async {
        await _pump(
          tester,
          theme: midnightTheme(brightness),
          onPressed: () {},
        );
        expect(_glyph(tester), roles.accentOnSurface);
        expect(_glyph(tester), roles.actionIcon);
      });

      testWidgets('disabled uses the sunken fill and the 54% foreground', (
        tester,
      ) async {
        await _pump(tester, theme: midnightTheme(brightness));
        expect(_fill(tester, {WidgetState.disabled}), roles.actionDisabledFill);
        expect(_glyph(tester), roles.actionDisabledForeground);
        expect(_caption(tester), roles.actionDisabledForeground);
      });

      testWidgets('caller iconColor wins when enabled, role wins disabled', (
        tester,
      ) async {
        await _pump(
          tester,
          theme: midnightTheme(brightness),
          onPressed: () {},
          iconColor: Colors.pink,
        );
        expect(_glyph(tester), Colors.pink);
        await _pump(
          tester,
          theme: midnightTheme(brightness),
          iconColor: Colors.pink,
        );
        expect(_glyph(tester), roles.actionDisabledForeground);
      });
    });
  }

  test('roles default to null', () {
    expect(const ScaffoldColorRoles().actionIcon, isNull);
    expect(const ScaffoldColorRoles().actionDisabledFill, isNull);
    expect(const ScaffoldColorRoles().actionDisabledForeground, isNull);
  });
}
