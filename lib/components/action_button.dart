import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

enum ActionButtonAnimation { none, rotate }

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  /// Background color; falls back to [ScaffoldPalette.deepBlueCardColor].
  final Color? backgroundColor;

  /// Icon tint; falls back to [ScaffoldPalette.lightGreenSecondary].
  final Color? iconColor;

  /// Label color; falls back to [ScaffoldPalette.gray500].
  final Color? textColor;

  final ActionButtonAnimation animation;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.animation = ActionButtonAnimation.none,
  }) : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.animation == ActionButtonAnimation.rotate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation == ActionButtonAnimation.rotate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final backgroundColor = widget.backgroundColor ?? palette.deepBlueCardColor;
    final iconColor = widget.iconColor ?? palette.lightGreenSecondary;
    final textColor = widget.textColor ?? palette.gray500;

    return LayoutBuilder(
      builder: (context, constraints) {
          final iconWidget = Icon(
            widget.icon,
            size: constraints.maxWidth * 0.38,
            color: iconColor,
          );

          final animatedIcon = widget.animation == ActionButtonAnimation.rotate
              ? RotationTransition(
                  turns: _controller,
                  child: iconWidget,
                )
              : iconWidget;

          return ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(0),
              fixedSize:
                  Size(constraints.maxWidth * 0.25, constraints.maxWidth),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  dimens.borderRadiusCard,
                ),
              ),
              disabledBackgroundColor: palette.deepBlueCardColor,
              backgroundColor: backgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                animatedIcon,
                Flexible(
                  child: AutoSizeText(
                    widget.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
    );
  }
}
