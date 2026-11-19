/// ScaffoldSelectionCopyAction — small support-library copy action for the
/// selection toolbar (D-07 demonstrability).
///
/// Slot into `ScaffoldSelectionActions.toolbarBuilder`. Icon-only (no label)
/// 20px glyph inside a 48x48 [ScaffoldTouchTarget] hit area. On press,
/// copies [selectedText] to the clipboard and swaps the icon to
/// `Icons.check` tinted `palette.statusSuccess` for
/// `ScaffoldMotionDurations.medium` (300ms), then reverts. Under
/// `ScaffoldMotion.reducedMotion`, the swap is a zero-duration
/// `AnimatedSwitcher`.
///
/// The selection-toolbar copy action intentionally does NOT announce via
/// [ScaffoldLiveRegion] — per the UI-SPEC "Code block copied confirmation"
/// row, transient copy confirmation is icon-only by default.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Icon-only copy action for `ScaffoldSelectionActions.toolbarBuilder`.
class ScaffoldSelectionCopyAction extends StatefulWidget {
  /// Creates a selection-toolbar copy action.
  const ScaffoldSelectionCopyAction({
    super.key,
    required this.selectedText,
    this.tooltip = 'Copy',
  });

  /// Selected text written to the clipboard on press.
  final String selectedText;

  /// Tooltip / semantics label for the pressable.
  final String tooltip;

  @override
  State<ScaffoldSelectionCopyAction> createState() =>
      _ScaffoldSelectionCopyActionState();
}

class _ScaffoldSelectionCopyActionState
    extends State<ScaffoldSelectionCopyAction> {
  bool _isCopied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.selectedText));
    setState(() => _isCopied = true);
    _timer?.cancel();
    _timer = Timer(ScaffoldMotionDurations.medium, () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;

    final Color iconColor = _isCopied
        ? palette.statusSuccess
        : palette.textSecondary;

    return ScaffoldPressable(
      semanticLabel: widget.tooltip,
      onPressed: _onCopy,
      child: ScaffoldTouchTarget(
        minWidth: 48,
        minHeight: 48,
        child: AnimatedSwitcher(
          duration: reducedMotion
              ? Duration.zero
              : ScaffoldMotionDurations.medium,
          child: Icon(
            _isCopied ? Icons.check : Icons.copy,
            key: ValueKey<bool>(_isCopied),
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
