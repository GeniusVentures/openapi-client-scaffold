import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:genius_scaffold/theme/scaffold_theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loading extends StatelessWidget {
  final String? text;

  /// Left dot color; falls back to [ScaffoldPalette.lightGreenPrimary].
  final Color? leftDotColor;

  /// Right dot color; falls back to [ScaffoldPalette.blue500].
  final Color? rightDotColor;

  const Loading({
    Key? key,
    this.text,
    this.leftDotColor,
    this.rightDotColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          LoadingAnimationWidget.flickr(
            leftDotColor: leftDotColor ?? palette.lightGreenPrimary,
            rightDotColor: rightDotColor ?? palette.blue500,
            size: 50,
          ),
          AutoSizeText(
            text ?? "",
            style: const TextStyle(fontSize: 24),
          )
        ]);
  }
}
