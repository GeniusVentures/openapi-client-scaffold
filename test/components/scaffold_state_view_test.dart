import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_skeleton.dart';
import 'package:frontend_scaffold/components/scaffold_state_view.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

import '../helpers/memory_storage.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: ScaffoldMotion(
          reducedMotion: false,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    HydratedBloc.storage = MemoryStorage();
  });

  setUp(() async {
    await HydratedBloc.storage.clear();
  });

  testWidgets('loading state renders ScaffoldSkeleton', (tester) async {
    await _pump(tester, const ScaffoldStateView(state: 'loading'));

    expect(find.byType(ScaffoldSkeleton), findsOneWidget);
  });

  testWidgets('error state renders error status indicator + headline + retry',
      (tester) async {
    await _pump(
      tester,
      ScaffoldStateView(state: 'error', onRetry: () {}),
    );

    final ScaffoldStatusIndicator indicator = tester
        .widget<ScaffoldStatusIndicator>(
          find.byType(ScaffoldStatusIndicator),
        );
    expect(indicator.status, StatusVariant.error);

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byType(ScaffoldPressable), findsOneWidget);
  });

  testWidgets('success state renders success status indicator + headline',
      (tester) async {
    await _pump(tester, const ScaffoldStateView(state: 'success'));

    final ScaffoldStatusIndicator indicator = tester
        .widget<ScaffoldStatusIndicator>(
          find.byType(ScaffoldStatusIndicator),
        );
    expect(indicator.status, StatusVariant.success);

    expect(find.text('Done!'), findsOneWidget);
  });
}
