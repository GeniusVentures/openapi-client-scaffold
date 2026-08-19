import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Stateful focus-ring overlay.
///
/// Draws a rounded-rect ring around [child] when the [focusNode] has focus AND
/// either keyboard focus is active (traditional highlight mode) or
/// [MediaQueryData.accessibleNavigation] is true — so the ring is visible in
/// screen-reader (TalkBack/VoiceOver) mode, not only with a physical keyboard.
class ScaffoldFocusOutline extends StatefulWidget {
  const ScaffoldFocusOutline({
    super.key,
    this.child,
    this.focusNode,
    this.borderRadius,
    this.ringColor,
    this.ringWidth,
  });

  final Widget? child;

  /// The node whose focus state drives the ring; an internal node is created
  /// when none is supplied.
  final FocusNode? focusNode;

  /// Ring corner radius; defaults to `dimens.borderRadiusCard`.
  final BorderRadiusGeometry? borderRadius;

  /// Ring color; defaults to `palette.focusRingColor`.
  final Color? ringColor;

  /// Ring stroke width; defaults to `dimens.focusRingWidth`.
  final double? ringWidth;

  @override
  State<ScaffoldFocusOutline> createState() => _ScaffoldFocusOutlineState();
}

class _ScaffoldFocusOutlineState extends State<ScaffoldFocusOutline> {
  late FocusNode _focusNode;
  late bool _hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasFocus = _focusNode.hasFocus;
    _focusNode.addListener(_onFocusChanged);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void didUpdateWidget(ScaffoldFocusOutline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      // We own the node only when no external node was supplied; dispose the
      // internal node before swapping so it is not leaked.
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _hasFocus = _focusNode.hasFocus;
      _focusNode.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (mounted && _hasFocus != _focusNode.hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  void _onHighlightModeChanged(FocusHighlightMode mode) {
    // The ring shows only under traditional (keyboard) highlight, so a mode
    // change can flip showRing without a focus change.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (child == null) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final dimens = context.dimens;

    final resolvedRingColor = widget.ringColor ?? palette.focusRingColor;
    final resolvedRingWidth = widget.ringWidth ?? dimens.focusRingWidth;
    final resolvedRadius = (widget.borderRadius ??
            BorderRadius.circular(dimens.borderRadiusCard))
        .resolve(Directionality.of(context));

    final bool keyboardFocus =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final bool accessibleNavigation =
        MediaQuery.of(context).accessibleNavigation;

    final bool showRing = _hasFocus && (keyboardFocus || accessibleNavigation);

    // Always return the same root widget type (Stack) whether or not the ring
    // is visible. Returning bare `child` when hidden and a Stack when shown
    // changes the root runtimeType, which remounts the entire child subtree —
    // for a TextField that tears down EditableText state and the text input
    // connection the moment focus lands (desktop: first click lights the ring
    // but the caret/keyboard never attach). The ring simply appears or
    // disappears at slot 1; the child at slot 0 is preserved.
    // StackFit.passthrough keeps layout identical to returning the bare child.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        if (showRing)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScaffoldFocusRingPainter(
                  color: resolvedRingColor,
                  strokeWidth: resolvedRingWidth,
                  borderRadius: resolvedRadius,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints a rounded-rect focus ring inset by [strokeWidth] / 2 from the edge.
class ScaffoldFocusRingPainter extends CustomPainter {
  const ScaffoldFocusRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    canvas.drawRRect(borderRadius.toRRect(rect.deflate(inset)), paint);
  }

  @override
  bool shouldRepaint(ScaffoldFocusRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}
