import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_image_placeholder_empty.dart';
import 'package:frontend_scaffold/components/scaffold_image_placeholder_failed.dart';
import 'package:frontend_scaffold/components/scaffold_image_placeholder_loading.dart';
import 'package:frontend_scaffold/components/scaffold_image_placeholder_missing.dart';
import 'package:frontend_scaffold/components/scaffold_skeleton.dart';
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

void main() {
  testWidgets('loading renders a ScaffoldSkeleton', (tester) async {
    await _pump(
      tester,
      const ScaffoldImagePlaceholderLoading(width: 120, height: 60),
    );

    expect(
      find.descendant(
        of: find.byType(ScaffoldImagePlaceholderLoading),
        matching: find.byType(ScaffoldSkeleton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('missing renders image_not_supported icon with configurable label', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldImagePlaceholderMissing(label: 'No image available'),
    );

    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    expect(find.text('No image available'), findsOneWidget);
  });

  testWidgets('failed renders broken_image icon in statusError', (tester) async {
    await _pump(
      tester,
      const ScaffoldImagePlaceholderFailed(label: 'Image failed to load'),
    );

    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.broken_image));
    expect(icon.color, ScaffoldPalette.defaultPalette.statusError);
    expect(find.text('Image failed to load'), findsOneWidget);
  });

  testWidgets('empty renders photo_outlined icon', (tester) async {
    await _pump(tester, const ScaffoldImagePlaceholderEmpty(label: 'No image'));

    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
  });
}
