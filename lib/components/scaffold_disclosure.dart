/// ScaffoldDisclosure — M3 expand/collapse row atom.
///
/// Composes [ScaffoldPressable] (header interaction) + [AnimatedSize] (body
/// reveal) + [AnimatedRotation] (chevron spin) + [ScaffoldMotion] (reduced-
/// motion gating). Supports both controlled ([expanded] + [onExpandedChanged])
/// and uncontrolled ([initiallyExpanded]) modes — matching Flutter's standard
/// controlled/uncontrolled idiom. Chevron tints [ScaffoldPalette.textSecondary]
/// by default and flips to [ScaffoldPalette.lightGreenPrimary] when expanded
/// AND [highlightWhenExpanded] is true. Consumes `Theme.of(context)` via
/// `context.palette` / `context.dimens` only — no hardcoded colors or dims.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Generic expand/collapse row.
///
/// The header is a [ScaffoldPressable] wrapping a `Row(title, chevron)`;
/// tapping toggles the body visibility. The body is wrapped in [AnimatedSize]
/// with [ScaffoldMotionDurations.medium]; when [ScaffoldMotion.reducedMotion]
/// is true the duration collapses to zero. Chevron rotation uses
/// [ScaffoldMotionDurations.short] (or zero under reduced motion).
class ScaffoldDisclosure extends StatefulWidget {
  /// Creates a disclosure row.
  ///
  /// When [expanded] is non-null the widget is controlled — the parent must
  /// supply the new value via [onExpandedChanged] for the UI to change. When
  /// [expanded] is null the widget is uncontrolled and tracks its own state
  /// seeded from [initiallyExpanded].
  const ScaffoldDisclosure({
    super.key,
    required this.title,
    required this.body,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.highlightWhenExpanded = false,
  }) : assert(
         expanded == null || initiallyExpanded == false,
         'ScaffoldDisclosure: supply either `expanded` (controlled) or '
         '`initiallyExpanded` (uncontrolled), not both.',
       );

  /// Header text.
  final String title;

  /// Body content rendered inside [AnimatedSize] when expanded.
  final Widget body;

  /// Controlled expanded state. Null → uncontrolled (uses [initiallyExpanded]).
  final bool? expanded;

  /// Initial expansion state when uncontrolled. Ignored when [expanded] is
  /// non-null.
  final bool initiallyExpanded;

  /// Fires after every tap with the negated state. In controlled mode the
  /// parent must forward the new value into [expanded] for the UI to update.
  final ValueChanged<bool>? onExpandedChanged;

  /// When true, the chevron tints [ScaffoldPalette.lightGreenPrimary] while
  /// expanded. When false the chevron stays [ScaffoldPalette.textSecondary].
  final bool highlightWhenExpanded;

  @override
  State<ScaffoldDisclosure> createState() => _ScaffoldDisclosureState();
}

class _ScaffoldDisclosureState extends State<ScaffoldDisclosure> {
  late bool _internalExpanded = widget.initiallyExpanded;

  bool get _effectiveExpanded => widget.expanded ?? _internalExpanded;

  void _toggle() {
    final bool next = !_effectiveExpanded;
    if (widget.expanded == null) {
      setState(() => _internalExpanded = next);
    }
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final textTheme = Theme.of(context).textTheme;
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;

    final Widget headerRow = ScaffoldPressable(
      onPressed: _toggle,
      semanticLabel: widget.title,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(widget.title, style: textTheme.labelMedium),
          ),
          SizedBox(width: dimens.space4),
          AnimatedRotation(
            turns: _effectiveExpanded ? 0.25 : 0.0,
            duration: reducedMotion
                ? Duration.zero
                : ScaffoldMotionDurations.short,
            curve: ScaffoldMotionCurves.standard,
            child: Icon(
              Icons.chevron_right,
              size: 24,
              color: _effectiveExpanded && widget.highlightWhenExpanded
                  ? palette.lightGreenPrimary
                  : palette.textSecondary,
            ),
          ),
        ],
      ),
    );

    final Widget bodyReveal = AnimatedSize(
      duration: reducedMotion ? Duration.zero : ScaffoldMotionDurations.medium,
      curve: ScaffoldMotionCurves.standard,
      child: _effectiveExpanded
          ? Padding(
              padding: EdgeInsets.only(
                left: dimens.space6,
                top: dimens.space4,
              ),
              child: widget.body,
            )
          : const SizedBox.shrink(),
    );

    return Semantics(
      expanded: _effectiveExpanded,
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          headerRow,
          bodyReveal,
        ],
      ),
    );
  }
}
