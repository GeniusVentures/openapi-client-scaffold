/// ScaffoldStreamingCopyButton — small support-library copy action for the
/// streaming response-action row (D-07 demonstrability).
///
/// Slot into `ScaffoldStreamingRichText.actions`. 20px glyph inside a 48x48
/// [ScaffoldTouchTarget] hit area; label rendered with
/// `textTheme.labelMedium`. On press, copies [textToCopy] to the clipboard
/// and swaps the icon to `Icons.check` tinted `palette.statusSuccess` for
/// `ScaffoldMotionDurations.medium` (300ms), then reverts. Under
/// `ScaffoldMotion.reducedMotion`, the swap is a zero-duration
/// `AnimatedSwitcher`.
///
/// When [armed] is true the icon is tinted `palette.lightGreenPrimary`
/// (the "copy ready" accent affordance from the Phase 9 color contract).
/// When [announceCopied] is true, a sibling [ScaffoldLiveRegion] announces
/// "Copied" once per press.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Copy action button for `ScaffoldStreamingRichText.actions`.
class ScaffoldStreamingCopyButton extends StatefulWidget {
  /// Creates a streaming copy button.
  const ScaffoldStreamingCopyButton({
    super.key,
    required this.textToCopy,
    this.label = 'Copy',
    this.tooltip = 'Copy',
    this.armed = false,
    this.announceCopied = false,
  });

  /// Text written to the clipboard on press.
  final String textToCopy;

  /// Visible label rendered next to the icon with `textTheme.labelMedium`.
  final String label;

  /// Tooltip / semantics label for the pressable.
  final String tooltip;

  /// When true, the icon is tinted `palette.lightGreenPrimary` (the
  /// "copy ready" accent affordance from the Phase 9 color contract).
  final bool armed;

  /// When true, wraps the button in a column with a sibling
  /// [ScaffoldLiveRegion] that announces "Copied" once per press.
  final bool announceCopied;

  @override
  State<ScaffoldStreamingCopyButton> createState() =>
      _ScaffoldStreamingCopyButtonState();
}

class _ScaffoldStreamingCopyButtonState
    extends State<ScaffoldStreamingCopyButton> {
  bool _isCopied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.textToCopy));
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
    final dimens = context.dimens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;

    final Color iconColor = _isCopied
        ? palette.statusSuccess
        : (widget.armed ? palette.lightGreenPrimary : palette.textSecondary);

    final Widget button = ScaffoldPressable(
      semanticLabel: widget.tooltip,
      onPressed: _onCopy,
      child: ScaffoldTouchTarget(
        minWidth: 48,
        minHeight: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
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
            SizedBox(width: dimens.space2),
            Text(widget.label, style: textTheme.labelMedium),
          ],
        ),
      ),
    );

    if (!widget.announceCopied) {
      return button;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        button,
        ScaffoldLiveRegion(
          value: _isCopied ? 'Copied' : null,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
