import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_chip.dart';
import 'package:frontend_scaffold/components/scaffold_chip_group.dart';
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
  // Test 11 — empty chips list renders SizedBox.shrink().
  testWidgets('empty chips list renders SizedBox.shrink()', (tester) async {
    await _pump(
      tester,
      const ScaffoldChipGroup(chips: <ScaffoldChip>[]),
    );

    expect(tester.getSize(find.byType(ScaffoldChipGroup)), Size.zero);
    expect(find.byType(Wrap), findsNothing);
  });

  // Test 12 — single-select: tap 1 then 2 yields {1} then {2} (not {1,2}).
  testWidgets('single-select replaces selection on each tap', (tester) async {
    final List<Set<int>> emissions = <Set<int>>[];
    Set<int> selected = <int>{};

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: ScaffoldChipGroup(
                  chips: <ScaffoldChip>[
                    ScaffoldChip(label: 'One', onPressed: () {}),
                    ScaffoldChip(label: 'Two', onPressed: () {}),
                    ScaffoldChip(label: 'Three', onPressed: () {}),
                  ],
                  selected: selected,
                  onSelectionChanged: (Set<int> next) {
                    emissions.add(Set<int>.from(next));
                    setState(() => selected = next);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(emissions.last, <int>{1});

    await tester.tap(find.text('Three'));
    await tester.pump();
    expect(emissions.last, <int>{2});
    expect(emissions.last, isNot(<int>{1, 2}));
  });

  // Test 13 — multi-select: tap 1, tap 2, tap 1 → {1}, {1,2}, {2}.
  testWidgets('multi-select toggles membership on each tap', (tester) async {
    final List<Set<int>> emissions = <Set<int>>[];
    Set<int> selected = <int>{};

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: ScaffoldChipGroup(
                  chips: <ScaffoldChip>[
                    ScaffoldChip(label: 'One', onPressed: () {}),
                    ScaffoldChip(label: 'Two', onPressed: () {}),
                    ScaffoldChip(label: 'Three', onPressed: () {}),
                  ],
                  selected: selected,
                  multiSelect: true,
                  onSelectionChanged: (Set<int> next) {
                    emissions.add(Set<int>.from(next));
                    setState(() => selected = next);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(emissions.last, <int>{1});

    await tester.tap(find.text('Three'));
    await tester.pump();
    expect(emissions.last, <int>{1, 2});

    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(emissions.last, <int>{2});
  });

  // Test 14 — tapping an already-selected chip in single-select emits {1} again.
  testWidgets('single-select re-tapping selected chip emits the same set',
      (tester) async {
    final List<Set<int>> emissions = <Set<int>>[];
    Set<int> selected = <int>{1};

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: ScaffoldChipGroup(
                  chips: <ScaffoldChip>[
                    ScaffoldChip(label: 'One', onPressed: () {}),
                    ScaffoldChip(label: 'Two', onPressed: () {}),
                  ],
                  selected: selected,
                  onSelectionChanged: (Set<int> next) {
                    emissions.add(Set<int>.from(next));
                    setState(() => selected = next);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(emissions.last, <int>{1});
  });

  // Test 15 — selected state propagates to the chip at the selected index.
  testWidgets('selected set drives chip selected border', (tester) async {
    await _pump(
      tester,
      ScaffoldChipGroup(
        chips: <ScaffoldChip>[
          ScaffoldChip(label: 'One', onPressed: () {}),
          ScaffoldChip(label: 'Two', onPressed: () {}),
        ],
        selected: const <int>{1},
        onSelectionChanged: (_) {},
      ),
    );

    // The second chip (index 1) carries the selected border.
    final Iterable<ScaffoldChip> chips = tester.widgetList<ScaffoldChip>(
      find.byType(ScaffoldChip),
    );
    expect(chips.elementAt(0).selected, isFalse);
    expect(chips.elementAt(1).selected, isTrue);
  });

  // Test 16 — Wrap layout uses space8 spacing and space4 runSpacing.
  testWidgets('Wrap uses space8 spacing and space4 runSpacing', (tester) async {
    await _pump(
      tester,
      ScaffoldChipGroup(
        chips: <ScaffoldChip>[
          ScaffoldChip(label: 'One', onPressed: () {}),
          ScaffoldChip(label: 'Two', onPressed: () {}),
        ],
      ),
    );

    final Wrap wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.spacing, ScaffoldDimens.defaultDimens.space8);
    expect(wrap.runSpacing, ScaffoldDimens.defaultDimens.space4);
  });

  // Test 17 — Semantics role: radioGroup for single, list for multi.
  // Flutter SDK exposes `radioGroup` (camelCase) and has no generic `group`
  // role — multi-select uses `list` as the closest container role.
  testWidgets('single-select exposes radioGroup role; multi exposes list',
      (tester) async {
    await _pump(
      tester,
      ScaffoldChipGroup(
        chips: <ScaffoldChip>[
          ScaffoldChip(label: 'One', onPressed: () {}),
        ],
      ),
    );

    final Semantics singleNode = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldChipGroup),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics && w.properties.role == SemanticsRole.radioGroup,
        ),
      ),
    ).first;
    expect(singleNode.properties.role, SemanticsRole.radioGroup);

    await _pump(
      tester,
      ScaffoldChipGroup(
        chips: <ScaffoldChip>[
          ScaffoldChip(label: 'One', onPressed: () {}),
        ],
        multiSelect: true,
      ),
    );

    final Semantics multiNode = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(ScaffoldChipGroup),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics && w.properties.role == SemanticsRole.list,
        ),
      ),
    ).first;
    expect(multiNode.properties.role, SemanticsRole.list);
  });

  // Test 18 — renders under lightPalette without exception.
  testWidgets('renders under lightPalette without exception', (tester) async {
    await _pumpLight(
      tester,
      ScaffoldChipGroup(
        chips: <ScaffoldChip>[
          ScaffoldChip(label: 'One', onPressed: () {}),
          ScaffoldChip(label: 'Two', onPressed: () {}),
        ],
        selected: const <int>{0},
      ),
    );
    expect(find.byType(ScaffoldChipGroup), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
  });
}
