import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Button that holds a string as value and appends value to provided controller
class StringButton extends StatelessWidget {
  final String value;
  final void Function(String) onPressed;
  final Color? color;
  final double? minWidth;
  const StringButton({
    super.key,
    required this.onPressed,
    required this.value,
    this.color,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;
    return MaterialButton(
      color: color,
      minWidth: minWidth,
      onPressed: () {
        onPressed(value);
      },
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
              Radius.circular(dimens.borderRadiusCard))),
      height: 60,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 30 * MediaQuery.of(context).textScaler.scale(1.0),
          // Only default the label to the palette text color on the
          // un-filled button. When a consumer supplies a fill [color],
          // keep MaterialButton's contrast-derived foreground — forcing
          // textPrimary would render white-on-white for light fills.
          color: color == null ? palette.textPrimary : null,
        ),
      ),
    );
  }
}
