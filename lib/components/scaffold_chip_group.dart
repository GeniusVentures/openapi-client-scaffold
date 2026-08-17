/// ScaffoldChipGroup — M3 chip-set layout with consumer-owned selection.
///
/// Lays out [chips] via a [Wrap] with `dimens.space8` (16px) spacing and
/// `dimens.space4` (8px) runSpacing. Holds NO selection truth — the consumer
/// supplies the current [selected] index set and receives the next set via
/// [onSelectionChanged] on every tap (D-02). Single-select mode replaces the
/// set on each tap; multi-select toggles the tapped index. Registers
/// `Semantics(role: radiogroup)` in single-select mode and
/// `Semantics(role: group)` in multi-select mode.
library;

import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_chip.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Layout + selection dispatch for a set of [ScaffoldChip] atoms.
class ScaffoldChipGroup extends StatelessWidget {
  /// Creates a chip group. The consumer owns selection truth: pass the
  /// current [selected] indices and update state in [onSelectionChanged].
  const ScaffoldChipGroup({
    super.key,
    required this.chips,
    this.selected = const <int>{},
    this.onSelectionChanged,
    this.multiSelect = false,
  });

  /// The chips to lay out. Order defines the index used in [selected] and
  /// [onSelectionChanged].
  final List<ScaffoldChip> chips;

  /// Indices of the currently selected chips (consumer-owned).
  final Set<int> selected;

  /// Called with the next selection set after a chip tap.
  final ValueChanged<Set<int>>? onSelectionChanged;

  /// When true, taps toggle membership (checkbox semantics). When false,
  /// taps replace the set with the tapped index (radio semantics).
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    final Widget wrap = Wrap(
      spacing: dimens.space8,
      runSpacing: dimens.space4,
      children: <Widget>[
        for (int i = 0; i < chips.length; i++) _wrapChipAtIndex(i, chips[i]),
      ],
    );

    // Flutter SDK exposes `radioGroup` (not `radiogroup`) and has no generic
    // `group` role — multi-select uses `list` as the closest container role.
    return Semantics(
      role: multiSelect ? SemanticsRole.list : SemanticsRole.radioGroup,
      child: wrap,
    );
  }

  Widget _wrapChipAtIndex(int index, ScaffoldChip chip) {
    return ScaffoldChip(
      label: chip.label,
      icon: chip.icon,
      status: chip.status,
      selected: selected.contains(index),
      disabled: chip.disabled,
      semanticLabel: chip.semanticLabel,
      onPressed:
          chip.onPressed == null ? null : () => _handleChipTap(index),
    );
  }

  void _handleChipTap(int index) {
    final Set<int> next = Set<int>.from(selected);
    if (multiSelect) {
      if (next.contains(index)) {
        next.remove(index);
      } else {
        next.add(index);
      }
    } else {
      next
        ..clear()
        ..add(index);
    }
    onSelectionChanged?.call(next);
  }
}
