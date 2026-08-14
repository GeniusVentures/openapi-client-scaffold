import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Pressed / hovered / focused / disabled interaction wrapper.
///
/// Wraps [child] in Material 3 state layers — `palette.textPrimary` at 8%
/// opacity on hover, 12% opacity on press — with a [ScaffoldFocusOutline] ring
/// when focused and a [ScaffoldDisabledOverlay] when [disabled]. Composes
/// [ScaffoldTouchTarget] internally for a 48x48 hit area, responds to Enter /
/// Space keys, and registers `Semantics(button: true)`.
class ScaffoldPressable extends StatefulWidget {
  const ScaffoldPressable({
    super.key,
    this.child,
    this.onPressed,
    this.onLongPress,
    this.onHoverChanged,
    this.focusNode,
    this.disabled = false,
  });

  /// Content rendered inside the pressable surface.
  final Widget? child;

  /// Called when the pressable is tapped or activated via Enter/Space.
  final VoidCallback? onPressed;

  /// Called on a long press.
  final VoidCallback? onLongPress;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChanged;

  /// The node whose focus state drives the ring; an internal node is created
  /// when none is supplied.
  final FocusNode? focusNode;

  /// When true, blocks interaction and applies [ScaffoldDisabledOverlay].
  final bool disabled;

  @override
  State<ScaffoldPressable> createState() => _ScaffoldPressableState();
}

class _ScaffoldPressableState extends State<ScaffoldPressable> {
  late FocusNode _focusNode;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(ScaffoldPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  bool get _enabled =>
      !widget.disabled &&
      (widget.onPressed != null || widget.onLongPress != null);

  void _setHovered(bool value) {
    if (_hovered != value) {
      setState(() => _hovered = value);
    }
    widget.onHoverChanged?.call(value);
  }

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_enabled) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onPressed?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget content = ScaffoldTouchTarget(child: widget.child);

    content = Stack(
      children: <Widget>[
        content,
        _buildStateLayer(palette),
      ],
    );

    content = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: _enabled ? widget.onPressed : null,
        onLongPress: _enabled ? widget.onLongPress : null,
        child: content,
      ),
    );

    content = ScaffoldFocusOutline(focusNode: _focusNode, child: content);

    content = Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Semantics(
        button: true,
        enabled: _enabled,
        child: content,
      ),
    );

    if (widget.disabled) {
      content = ScaffoldDisabledOverlay(disabled: true, child: content);
    }

    return content;
  }

  Widget _buildStateLayer(ScaffoldPalette palette) {
    final double opacity = _pressed ? 0.12 : (_hovered ? 0.08 : 0.0);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: ScaffoldMotionDurations.short,
          curve: ScaffoldMotionCurves.standard,
          child: ColoredBox(color: palette.textPrimary),
        ),
      ),
    );
  }
}
