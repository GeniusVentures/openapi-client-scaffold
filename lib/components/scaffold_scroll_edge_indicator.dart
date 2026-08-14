import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Thin edge hairlines that signal when a scrollable's content extends beyond
/// the viewport.
///
/// Listens to [scrollController] and renders 1px hairlines (`palette.borderSubtle`)
/// at the top and/or bottom edge of the viewport when content overflows in
/// that direction. Edge lines fade in and out with
/// [ScaffoldMotionDurations.short] as the scroll position crosses the
/// boundaries. The indicator never participates in hit-testing, so it does not
/// steal gestures from the scrollable it decorates.
class ScaffoldScrollEdgeIndicator extends StatefulWidget {
  const ScaffoldScrollEdgeIndicator({
    super.key,
    required this.scrollController,
    this.edgeColor,
    this.edgeWidth = 1.0,
  });

  /// Controller of the scrollable whose edges are decorated.
  final ScrollController scrollController;

  /// Hairline color; defaults to `palette.borderSubtle`.
  final Color? edgeColor;

  /// Hairline thickness in logical pixels. Defaults to 1.0.
  final double edgeWidth;

  @override
  State<ScaffoldScrollEdgeIndicator> createState() =>
      _ScaffoldScrollEdgeIndicatorState();
}

class _ScaffoldScrollEdgeIndicatorState
    extends State<ScaffoldScrollEdgeIndicator> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(ScaffoldScrollEdgeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color color = widget.edgeColor ?? palette.borderSubtle;

    final bool showStart;
    final bool showEnd;
    if (widget.scrollController.hasClients) {
      final ScrollPosition position = widget.scrollController.position;
      // extentBefore/extentAfter read min/maxScrollExtent, which are null
      // until the position has laid out its content dimensions. Guard so the
      // first build (controller attached but not yet laid out) does not crash.
      if (position.hasContentDimensions) {
        showStart = position.extentBefore > 0;
        showEnd = position.extentAfter > 0;
      } else {
        showStart = false;
        showEnd = false;
      }
    } else {
      showStart = false;
      showEnd = false;
    }

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              key: const Key('scroll_edge_start'),
              opacity: showStart ? 1.0 : 0.0,
              duration: ScaffoldMotionDurations.short,
              curve: ScaffoldMotionCurves.standard,
              child: Container(height: widget.edgeWidth, color: color),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              key: const Key('scroll_edge_end'),
              opacity: showEnd ? 1.0 : 0.0,
              duration: ScaffoldMotionDurations.short,
              curve: ScaffoldMotionCurves.standard,
              child: Container(height: widget.edgeWidth, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
