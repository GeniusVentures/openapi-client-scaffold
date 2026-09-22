// ScaffoldChip / ScaffoldChipGroup demo for Phase 8 (WIDG-40).
//
// Exercises default / selected / disabled / leading-icon / status / icon-only
// single-chip compositions, plus single-select, multi-select, and empty
// chip-group compositions.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_chip.dart';
import 'package:frontend_scaffold/components/scaffold_chip_group.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Demo showing [ScaffoldChip] across every state and [ScaffoldChipGroup]
/// in single-select, multi-select, and empty compositions.
class ScaffoldChipDemo extends StatelessWidget {
  const ScaffoldChipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldChip')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Default ---
            Text('Default', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(label: 'Chip', onPressed: () {}),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. Selected ---
            Text('Selected (2px accent border)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(label: 'Chip', selected: true, onPressed: () {}),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Disabled ---
            Text('Disabled', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(label: 'Chip', disabled: true, onPressed: () {}),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Leading icon ---
            Text('With leading icon',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(label: 'Add', icon: Icons.add, onPressed: () {}),

            SizedBox(height: dimens.itemSpacing),

            // --- 5. Trailing status indicator ---
            Text('With status', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(
              label: 'Active',
              status: StatusVariant.success,
              onPressed: () {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 6. Icon-only (D-03 requires semanticLabel) ---
            Text('Icon only (requires semanticLabel)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldChip(
              icon: Icons.close,
              semanticLabel: 'Close',
              onPressed: () {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 7. ChipGroup — single-select ---
            Text('ChipGroup (single-select)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _SingleSelectGroup(),

            SizedBox(height: dimens.itemSpacing),

            // --- 8. ChipGroup — multi-select ---
            Text('ChipGroup (multi-select)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _MultiSelectGroup(),

            SizedBox(height: dimens.itemSpacing),

            // --- 9. Empty group → SizedBox.shrink() ---
            Text('Empty group (renders zero-size)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const ScaffoldChipGroup(chips: <ScaffoldChip>[]),
          ],
        ),
      ),
    );
  }
}

/// Single-select group owning its local selection state.
class _SingleSelectGroup extends StatefulWidget {
  const _SingleSelectGroup();

  @override
  State<_SingleSelectGroup> createState() => _SingleSelectGroupState();
}

class _SingleSelectGroupState extends State<_SingleSelectGroup> {
  Set<int> _selected = <int>{0};

  @override
  Widget build(BuildContext context) {
    return ScaffoldChipGroup(
      chips: <ScaffoldChip>[
        ScaffoldChip(
          label: 'One',
          onPressed: () => debugPrint('single-select chip "One" tapped'),
        ),
        ScaffoldChip(label: 'Two', onPressed: () {}),
        ScaffoldChip(label: 'Three', onPressed: () {}),
      ],
      selected: _selected,
      onSelectionChanged: (Set<int> next) {
        setState(() => _selected = next);
      },
    );
  }
}

/// Multi-select group owning its local selection state.
class _MultiSelectGroup extends StatefulWidget {
  const _MultiSelectGroup();

  @override
  State<_MultiSelectGroup> createState() => _MultiSelectGroupState();
}

class _MultiSelectGroupState extends State<_MultiSelectGroup> {
  Set<int> _selected = <int>{0, 2};

  @override
  Widget build(BuildContext context) {
    return ScaffoldChipGroup(
      chips: <ScaffoldChip>[
        ScaffoldChip(
          label: 'One',
          onPressed: () => debugPrint('multi-select chip "One" tapped'),
        ),
        ScaffoldChip(label: 'Two', onPressed: () {}),
        ScaffoldChip(label: 'Three', onPressed: () {}),
        ScaffoldChip(label: 'Four', onPressed: () {}),
      ],
      selected: _selected,
      multiSelect: true,
      onSelectionChanged: (Set<int> next) {
        setState(() => _selected = next);
      },
    );
  }
}
