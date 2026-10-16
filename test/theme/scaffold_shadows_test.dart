import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/toast/toast_manager.dart';
import 'package:frontend_scaffold/components/toast/toast_widget.dart';
import 'package:frontend_scaffold/theme/scaffold_elevation.dart';
import 'package:frontend_scaffold/theme/scaffold_shadows.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const List<BoxShadow> _custom = [
  BoxShadow(color: Color(0xFF123456), blurRadius: 3.0),
];

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

Future<List<List<BoxShadow>>> _pumpToast(
  WidgetTester tester, {
  required ThemeData theme,
  String? title,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: ToastWidget(
          message: 'm',
          title: title,
          type: ToastType.success,
          onDismiss: () {},
        ),
      ),
    ),
  );
  final shadows = <List<BoxShadow>>[];
  for (final container in tester.widgetList<Container>(
    find.descendant(
      of: find.byType(ToastWidget),
      matching: find.byType(Container),
    ),
  )) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.boxShadow != null) {
      shadows.add(decoration.boxShadow!);
    }
  }
  return shadows;
}

void main() {
  group('defaults', () {
    test('equal ScaffoldElevation.card in both modes', () {
      expect(ScaffoldShadows.defaultShadows.card, ScaffoldElevation.card);
      expect(ScaffoldShadows.lightShadows.card, ScaffoldElevation.card);
    });

    test('const ScaffoldShadows() is the default', () {
      expect(const ScaffoldShadows().card, ScaffoldShadows.defaultShadows.card);
    });
  });

  group('copyWith and lerp', () {
    const a = ScaffoldShadows();
    const b = ScaffoldShadows(card: _custom);

    test('copyWith replaces only the given field', () {
      expect(a.copyWith(card: _custom).card, _custom);
      expect(a.copyWith().card, a.card);
    });

    test('lerp endpoints', () {
      expect(a.lerp(b, 0.0).card, a.card);
      expect(a.lerp(b, 1.0).card, b.card);
    });

    test('lerp with a non-ScaffoldShadows returns this', () {
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });
  });

  group('context.shadows', () {
    testWidgets('dark theme without extension gives defaultShadows',
        (tester) async {
      final context = await _pumpContext(tester, ThemeData.dark());
      expect(identical(context.shadows, ScaffoldShadows.defaultShadows), isTrue);
    });

    testWidgets('light theme without extension gives lightShadows',
        (tester) async {
      final context = await _pumpContext(tester, ThemeData.light());
      expect(identical(context.shadows, ScaffoldShadows.lightShadows), isTrue);
    });

    testWidgets('registered extension wins', (tester) async {
      const registered = ScaffoldShadows(card: _custom);
      final context = await _pumpContext(
        tester,
        ThemeData(extensions: const [registered]),
      );
      expect(identical(context.shadows, registered), isTrue);
    });
  });

  group('ToastWidget', () {
    for (final title in <String?>[null, 't']) {
      final density = title == null ? 'compact' : 'card';

      testWidgets('$density draws the registered card shadow', (tester) async {
        final shadows = await _pumpToast(
          tester,
          theme: ThemeData(
            extensions: const [ScaffoldShadows(card: _custom)],
          ),
          title: title,
        );
        expect(shadows, [_custom]);
      });

      testWidgets('$density draws ScaffoldElevation.card by default',
          (tester) async {
        for (final theme in [ThemeData.dark(), ThemeData.light()]) {
          final shadows = await _pumpToast(tester, theme: theme, title: title);
          expect(shadows, [ScaffoldElevation.card]);
        }
      });
    }
  });
}
