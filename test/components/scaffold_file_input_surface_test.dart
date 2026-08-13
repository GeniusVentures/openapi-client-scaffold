import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_dashed_border.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_file_input_surface.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
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
  testWidgets('idle renders dashed border + upload icon + label', (tester) async {
    await _pump(tester, ScaffoldFileInputSurface(onFileSelected: (_) {}));

    final ScaffoldDashedBorder dashed = tester.widget<ScaffoldDashedBorder>(
      find.byType(ScaffoldDashedBorder),
    );
    expect(dashed.color, ScaffoldPalette.defaultPalette.borderSubtle);
    expect(find.byIcon(Icons.upload_file), findsOneWidget);
    expect(find.text('Choose a file or drag here'), findsOneWidget);
  });

  testWidgets('valid file shows statusSuccess border + check circle + filename', (
    tester,
  ) async {
    await _pump(
      tester,
      ScaffoldFileInputSurface(
        onFileSelected: (_) {},
        pickFile: () async => File('report.txt'),
      ),
    );

    await tester.tap(find.byType(ScaffoldFileInputSurface));
    await tester.pumpAndSettle();

    final ScaffoldSurface surface = tester.widget<ScaffoldSurface>(
      find.byType(ScaffoldSurface),
    );
    expect(
      (surface.border! as Border).top.color,
      ScaffoldPalette.defaultPalette.statusSuccess,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('report.txt'), findsOneWidget);
  });

  testWidgets('invalid file shows statusError border + error icon + message', (
    tester,
  ) async {
    await _pump(
      tester,
      ScaffoldFileInputSurface(
        onFileSelected: (_) {},
        pickFile: () async => File('bad.txt'),
        validate: (_) => 'File type not allowed',
      ),
    );

    await tester.tap(find.byType(ScaffoldFileInputSurface));
    await tester.pumpAndSettle();

    final ScaffoldSurface surface = tester.widget<ScaffoldSurface>(
      find.byType(ScaffoldSurface),
    );
    expect(
      (surface.border! as Border).top.color,
      ScaffoldPalette.defaultPalette.statusError,
    );
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('File type not allowed'), findsOneWidget);
  });

  testWidgets('disabled applies DisabledOverlay', (tester) async {
    await _pump(
      tester,
      ScaffoldFileInputSurface(onFileSelected: (_) {}, disabled: true),
    );

    expect(find.byType(ScaffoldDisabledOverlay), findsOneWidget);
  });

  testWidgets('tap-to-pick fires onFileSelected with the picked file', (
    tester,
  ) async {
    File? selected;
    final File fakeFile = File('picked.txt');
    await _pump(
      tester,
      ScaffoldFileInputSurface(
        onFileSelected: (File f) => selected = f,
        pickFile: () async => fakeFile,
      ),
    );

    await tester.tap(find.byType(ScaffoldFileInputSurface));
    await tester.pumpAndSettle();

    expect(selected, fakeFile);
    expect(find.text('picked.txt'), findsOneWidget);
  });
}
