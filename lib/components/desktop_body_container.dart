import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

class DesktopBodyContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final String? title;
  final String? subText;
  const DesktopBodyContainer(
      {super.key,
      this.child = const SizedBox(),
      this.width = 600,
      this.height,
      this.subText,
      this.title});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
        width: width,
        height: height,
        child: Column(children: [
          Text(title ?? '',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: palette.textPrimary)),
          const SizedBox(
            height: 20,
          ),
          Text(subText ?? '', style: TextStyle(color: palette.textSecondary)),
          const SizedBox(
            height: 20,
          ),
          child
        ]));
  }
}
