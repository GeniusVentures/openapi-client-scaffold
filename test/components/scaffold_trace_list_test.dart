import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_trace_list.dart';
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

void main() {
  testWidgets('Test 9: empty items list renders SizedBox.shrink()', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldTraceList(items: <TraceItem>[]));

    expect(find.byType(ScaffoldDisclosure), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
    expect(tester.getSize(find.byType(ScaffoldTraceList)), Size.zero);
  });

  testWidgets(
    'Test 10: items render in supplied order — first title before second',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldTraceList(
          items: <TraceItem>[
            TraceItem(title: 'First', body: Text('b1')),
            TraceItem(title: 'Second', body: Text('b2')),
            TraceItem(title: 'Third', body: Text('b3')),
          ],
        ),
      );

      final Offset firstOffset = tester.getTopLeft(find.text('First'));
      final Offset secondOffset = tester.getTopLeft(find.text('Second'));
      final Offset thirdOffset = tester.getTopLeft(find.text('Third'));

      expect(firstOffset.dy, lessThan(secondOffset.dy));
      expect(secondOffset.dy, lessThan(thirdOffset.dy));
    },
  );

  testWidgets(
    'Test 11: groupHeader renders with titleSmall style and 24px top padding',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldTraceList(
          groupHeader: 'Pipeline',
          items: <TraceItem>[
            TraceItem(title: 'Step', body: Text('b')),
          ],
        ),
      );

      final Text header = tester.widget<Text>(find.text('Pipeline'));
      final BuildContext context = tester.element(find.text('Pipeline'));
      final TextStyle? expected = Theme.of(context).textTheme.titleSmall;
      expect(header.style, expected);

      final Padding padding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Pipeline'),
          matching: find.byType(Padding),
        ),
      );
      expect(
        padding.padding,
        EdgeInsets.only(top: ScaffoldDimens.defaultDimens.space12),
      );
    },
  );

  testWidgets('Test 12: items are separated vertically by dimens.space8 (16px)', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldTraceList(
        items: <TraceItem>[
          TraceItem(title: 'One', body: Text('b1')),
          TraceItem(title: 'Two', body: Text('b2')),
        ],
      ),
    );

    // Find the SizedBox separators inside the trace list column.
    final Iterable<SizedBox> spacers = tester
        .widgetList<SizedBox>(
          find.descendant(
            of: find.byType(ScaffoldTraceList),
            matching: find.byType(SizedBox),
          ),
        )
        .where((SizedBox s) => s.height == ScaffoldDimens.defaultDimens.space8);

    expect(spacers.length, greaterThanOrEqualTo(1));
  });

  testWidgets('Test 13: renders under lightPalette without exception', (
    tester,
  ) async {
    await _pumpLight(
      tester,
      const ScaffoldTraceList(
        groupHeader: 'Pipeline',
        items: <TraceItem>[
          TraceItem(
            title: 'Step 1',
            body: Text('loaded'),
            status: StatusVariant.success,
          ),
          TraceItem(
            title: 'Step 2',
            body: Text('filtered'),
            status: StatusVariant.info,
          ),
        ],
      ),
    );

    expect(find.byType(ScaffoldTraceList), findsOneWidget);
    expect(find.text('Pipeline'), findsOneWidget);
    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Step 2'), findsOneWidget);
  });

  testWidgets(
    'status indicator renders as a leading slot when TraceItem.status is set',
    (tester) async {
      await _pump(
        tester,
        const ScaffoldTraceList(
          items: <TraceItem>[
            TraceItem(
              title: 'Step',
              body: Text('b'),
              status: StatusVariant.success,
            ),
          ],
        ),
      );

      expect(find.byType(ScaffoldStatusIndicator), findsOneWidget);
    },
  );
}
