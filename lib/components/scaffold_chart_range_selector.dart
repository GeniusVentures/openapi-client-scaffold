/// `ScaffoldChartRangeSelector<T>` — drag-range selection composition
/// around `ScaffoldChart` (D-09).
///
/// Wraps a chart (or scrubber-composed chart) in a Stack with a drag-band
/// overlay. Horizontal drag in the plot paints a selection band (accent 12%
/// alpha fill, 1px accent edge rules) tracking the drag; on release fires
/// `onRangeSelected((startT, endT))` with nearest-point endpoints.
/// REPORT-ONLY — the atom never rescales, zooms, or filters on its own; the
/// consumer decides via the callback (e.g. set `viewMinX`/`viewMaxX` on the
/// next build).
///
/// Gesture-conflict rule (D-10): while a range drag is active, the inner
/// chart's pan-scrub is suppressed. Mechanism: the band overlay's
/// GestureDetector sits ABOVE the chart in the Stack and its
/// HorizontalDragGestureRecognizer is hit-tested first, so it claims
/// horizontal drags before the chart's internal PanGestureRecognizer can.
/// Tap/hover events still reach the chart below (the overlay registers no
/// tap/hover handlers AND uses `HitTestBehavior.translucent` — NOT opaque —
/// so hit-testing continues through to the chart), keeping point-scrub
/// functional when no drag is active. An `opaque` overlay would absorb the
/// hit and starve the chart of ALL tap and hover events, contradicting the
/// D-10 tap/hover pass-through contract.
///
/// Keyboard: Shift+ArrowLeft/Right adjusts the range end by one series
/// point; Enter confirms; Escape clears. Plain ArrowLeft/Right routes to
/// the inner scrubber when one is composed.
///
/// This file contains ZERO chart-library imports and zero domain
/// knowledge. Composition only.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/scaffold_palette.dart';
import '../theme/scaffold_theme.dart';
import '../utils/chart_geometry.dart';
import 'scaffold_chart.dart';
import 'scaffold_focus_outline.dart';
import 'scaffold_touch_target.dart';

// Re-export the ScrubMode enum so consumers importing ONLY the range
// selector can still name the D-08 smooth-mode switch without a second
// import of the chart atom. (Mirrors the scrubber's re-export.)
export 'scaffold_chart.dart' show ScrubMode;

/// Alpha of the band fill (12%) — `palette.lightGreenPrimary` at this alpha
/// forms the translucent selection band (D-09).
const double _kBandFillAlpha = 0.12;

/// Stroke width of the band's accent edge rules.
const double _kEdgeRuleWidth = 1.0;

/// Drag-range selection composition atom — generic over the consumer's
/// series element type, exactly mirroring `ScaffoldChart<T>`'s generic.
///
/// See the file-level doc comment for the full contract. All band-drag,
/// keyboard, focus, and a11y behavior is owned here; all chart rendering is
/// delegated to `ScaffoldChart<T>`; all zoom/filter/window mutation is
/// delegated to the consumer via `onRangeSelected`.
class ScaffoldChartRangeSelector<T> extends StatelessWidget {
  /// Creates a range selector over [series].
  const ScaffoldChartRangeSelector({
    super.key,
    required this.series,
    required this.xAccessor,
    required this.yAccessor,
    this.selectedRange,
    this.onRangeSelected,
    this.rangeSemanticsLabel,
    this.selectedPoint,
    this.onPointSelected,
    this.plotHeight,
    this.lineColor,
    this.chartSemanticsLabel,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.viewMinX,
    this.viewMaxX,
    this.scrubMode = ScrubMode.snap,
    this.onPositionChanged,
  });

  /// The data series; passed through to `ScaffoldChart`.
  final List<T> series;

  /// Maps an element of [series] to its X coordinate.
  final double Function(T) xAccessor;

  /// Maps an element of [series] to its Y coordinate.
  final double Function(T) yAccessor;

  /// The currently selected range (startT, endT), owned by the consumer.
  /// When non-null and no band drag is in progress, the band paints at the
  /// range's X positions.
  final (T, T)? selectedRange;

  /// Fires when a range selection is made (drag release, Shift+Arrow
  /// adjustment, Enter confirm) or cleared (Escape). Carries `(startT,
  /// endT)` ordered so startT.x <= endT.x, or null on clear.
  ///
  /// null is fired ONLY on an explicit clear (Escape). A band drag whose
  /// pixel→chart mapping fails (degenerate X window, collapsed layout
  /// mid-gesture, empty series) fires NOTHING — the consumer's existing
  /// range is preserved rather than silently cleared.
  final ValueChanged<(T, T)?>? onRangeSelected;

  /// Optional semantics label for the range interaction area. Defaults to
  /// `'Chart range selector'`.
  final String? rangeSemanticsLabel;

  /// The currently selected point, owned by the consumer; passed through to
  /// `ScaffoldChart` so tap/hover point-scrub remains functional (D-10
  /// pass-through).
  final T? selectedPoint;

  /// Fires when a point is selected (tap/hover); passed through to
  /// `ScaffoldChart`.
  final ValueChanged<T?>? onPointSelected;

  /// Optional explicit plot height; passed through to `ScaffoldChart`.
  final double? plotHeight;

  /// Optional line color override; passed through to `ScaffoldChart`.
  final Color? lineColor;

  /// Optional chart semantics label; passed through to `ScaffoldChart`.
  final String? chartSemanticsLabel;

  /// Optional X-axis label formatter; passed through to `ScaffoldChart`.
  final String Function(double)? xLabelFormatter;

  /// Optional Y-axis label formatter; passed through to `ScaffoldChart`.
  final String Function(double, double)? yLabelFormatter;

  /// Optional visible-window minimum X; passed through to `ScaffoldChart`.
  final double? viewMinX;

  /// Optional visible-window maximum X; passed through to `ScaffoldChart`.
  final double? viewMaxX;

  /// Scrub behavior mode (D-08); passed through to `ScaffoldChart`.
  /// Defaults to [ScrubMode.snap].
  final ScrubMode scrubMode;

  /// Continuous scrub-position callback (D-08); passed through to
  /// `ScaffoldChart`.
  final void Function(double x, double y)? onPositionChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: rangeSemanticsLabel ?? 'Chart range selector',
      child: _RangeSelectorCore<T>(
        series: series,
        xAccessor: xAccessor,
        yAccessor: yAccessor,
        selectedRange: selectedRange,
        onRangeSelected: onRangeSelected,
        selectedPoint: selectedPoint,
        onPointSelected: onPointSelected,
        plotHeight: plotHeight,
        lineColor: lineColor,
        chartSemanticsLabel: chartSemanticsLabel,
        xLabelFormatter: xLabelFormatter,
        yLabelFormatter: yLabelFormatter,
        viewMinX: viewMinX,
        viewMaxX: viewMaxX,
        scrubMode: scrubMode,
        onPositionChanged: onPositionChanged,
      ),
    );
  }
}

/// Private stateful core — owns the shared [FocusNode] used by both the
/// key-dispatch [Focus] widget and the [ScaffoldFocusOutline] ring, plus the
/// transient band-drag pixel state. Holds ONLY transient interaction state;
/// range-selection truth stays with the consumer.
class _RangeSelectorCore<T> extends StatefulWidget {
  const _RangeSelectorCore({
    required this.series,
    required this.xAccessor,
    required this.yAccessor,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.selectedPoint,
    required this.onPointSelected,
    this.plotHeight,
    this.lineColor,
    this.chartSemanticsLabel,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.viewMinX,
    this.viewMaxX,
    this.scrubMode = ScrubMode.snap,
    this.onPositionChanged,
  });

  final List<T> series;
  final double Function(T) xAccessor;
  final double Function(T) yAccessor;
  final (T, T)? selectedRange;
  final ValueChanged<(T, T)?>? onRangeSelected;
  final T? selectedPoint;
  final ValueChanged<T?>? onPointSelected;
  final double? plotHeight;
  final Color? lineColor;
  final String? chartSemanticsLabel;
  final String Function(double)? xLabelFormatter;
  final String Function(double, double)? yLabelFormatter;
  final double? viewMinX;
  final double? viewMaxX;
  final ScrubMode scrubMode;
  final void Function(double x, double y)? onPositionChanged;

  @override
  State<_RangeSelectorCore<T>> createState() => _RangeSelectorCoreState<T>();
}

class _RangeSelectorCoreState<T> extends State<_RangeSelectorCore<T>> {
  late final FocusNode _focusNode =
      FocusNode(debugLabel: 'ScaffoldChartRangeSelector');

  /// Widget-space (overlay-local) pixel position of the band drag's start.
  Offset? _dragStart;

  /// Widget-space (overlay-local) pixel position of the band drag's current
  /// pointer. Updated on every drag-update so the band tracks the pointer.
  Offset? _dragCurrent;

  /// Raw pointer-down position captured by the outer Listener. Used as the
  /// band's start anchor — the recognizer's own `DragStartDetails
  /// .localPosition` is reported at the slop-exceeded point
  /// (DragStartBehavior.start), which would offset the band's left edge by
  /// the touch slop from where the user actually pressed.
  Offset? _downPosition;

  /// True when at least one `DragUpdateDetails` arrived between drag-start
  /// and drag-end. The tap-vs-drag discriminator: a tap is force-accepted
  /// by the gesture arena and never fires `_onDragUpdate`, so it leaves
  /// this false. A drag that returns to its start pixel still sets this
  /// true (the user moved), so it is reported as a real drag even though
  /// start.dx == current.dx at release. Comparing pixel coordinates for
  /// exact equality is unreliable (pointer quantization on some platforms
  /// reports the up-coordinate as exactly the down-coordinate after a small
  /// out-and-back drag) — the bool flag matches what the gesture arena
  /// actually decided.
  bool _sawDragUpdate = false;

  /// Stack width/height captured during layout — the overlay's coordinate
  /// space, used to map drag pixels to chart-x and back.
  double _stackWidth = 0.0;
  double _stackHeight = 0.0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The chart's visible-window X bounds, mirroring ScaffoldChart's
  /// `lo`/`hi` resolution (viewMinX ?? first.x, viewMaxX ?? last.x).
  (double, double)? _windowXBounds() {
    if (widget.series.isEmpty) {
      return null;
    }
    final double lo = widget.viewMinX ?? widget.xAccessor(widget.series.first);
    final double hi = widget.viewMaxX ?? widget.xAccessor(widget.series.last);
    return (lo, hi);
  }

  /// Maps a widget-space (overlay-local) pixel x to chart-x, mirroring the
  /// renderer's linear mapping — accounting for the surface's `space8` inset
  /// and the framed chart's `kChartAxisGutter` right gutter.
  double? _chartXOfPixel(double pixelX) {
    final (double, double)? bounds = _windowXBounds();
    if (bounds == null) {
      return null;
    }
    final (double lo, double hi) = bounds;
    final double plotLeft = context.dimens.space8;
    final double plotWidth = _stackWidth - 2 * context.dimens.space8;
    final bool useFrame = chartUsesFrame(widget.plotHeight ?? _stackHeight);
    final double usableWidth = plotWidth - (useFrame ? kChartAxisGutter : 0.0);
    final double span = hi - lo;
    if (span <= 0.0 || usableWidth <= 0.0) {
      return null;
    }
    final double t = (pixelX - plotLeft) / usableWidth;
    return lo + t * span;
  }

  /// Inverse of [_chartXOfPixel] — maps a chart-x back to a widget-space
  /// pixel x (used to paint the persistent band from `selectedRange`).
  double? _pixelXOfChart(double chartX) {
    final (double, double)? bounds = _windowXBounds();
    if (bounds == null) {
      return null;
    }
    final (double lo, double hi) = bounds;
    final double plotLeft = context.dimens.space8;
    final double plotWidth = _stackWidth - 2 * context.dimens.space8;
    final bool useFrame = chartUsesFrame(widget.plotHeight ?? _stackHeight);
    final double usableWidth = plotWidth - (useFrame ? kChartAxisGutter : 0.0);
    final double span = hi - lo;
    if (span <= 0.0 || usableWidth <= 0.0) {
      return null;
    }
    final double t = (chartX - lo) / span;
    return plotLeft + t * usableWidth;
  }

  /// Resolves the band's left/right widget-space pixel x, preferring the
  /// live drag (when active) and falling back to the consumer's
  /// `selectedRange` (persistent band). Returns null when there is no band.
  (double, double)? _resolveBand() {
    final Offset? start = _dragStart;
    final Offset? current = _dragCurrent;
    if (start != null && current != null) {
      return (math.min(start.dx, current.dx), math.max(start.dx, current.dx));
    }
    final (T, T)? range = widget.selectedRange;
    if (range == null) {
      return null;
    }
    final double? a = _pixelXOfChart(widget.xAccessor(range.$1));
    final double? b = _pixelXOfChart(widget.xAccessor(range.$2));
    if (a == null || b == null) {
      return null;
    }
    return (math.min(a, b), math.max(a, b));
  }

  /// The series point nearest [chartX] by accessor-x distance (O(n) over
  /// the series — series are small; the renderer uses the same threshold
  /// notion for its own nearest-spot lookup).
  T _nearestPoint(double chartX) {
    T best = widget.series.first;
    double bestDistance = double.infinity;
    for (final T item in widget.series) {
      final double d = (widget.xAccessor(item) - chartX).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = item;
      }
    }
    return best;
  }

  /// Maps the drag's start/current pixel positions to a `(startT, endT)`
  /// range of nearest series points, ordered so startT.x <= endT.x.
  (T, T)? _mapPixelsToRange(Offset? start, Offset? current) {
    if (start == null || current == null || widget.series.isEmpty) {
      return null;
    }
    final double? cx1 = _chartXOfPixel(start.dx);
    final double? cx2 = _chartXOfPixel(current.dx);
    if (cx1 == null || cx2 == null) {
      return null;
    }
    final T a = _nearestPoint(cx1);
    final T b = _nearestPoint(cx2);
    final double ax = widget.xAccessor(a);
    final double bx = widget.xAccessor(b);
    if (ax <= bx) {
      return (a, b);
    }
    return (b, a);
  }

  /// Looks up [value] in [widget.series] by ACCESSOR-EQUALITY (not
  /// identity), mirroring the scrubber's `_selectedIndex`. Returns -1 when
  /// not found.
  int _indexOf(T value) {
    final double tx = widget.xAccessor(value);
    final double ty = widget.yAccessor(value);
    return widget.series.indexWhere(
      (T item) =>
          widget.xAccessor(item) == tx && widget.yAccessor(item) == ty,
    );
  }

  void _handleExtendRange() {
    final (T, T)? current = widget.selectedRange;
    if (current == null || widget.onRangeSelected == null) {
      return;
    }
    if (widget.series.isEmpty) {
      return;
    }
    final int endIdx = _indexOf(current.$2);
    if (endIdx < 0) {
      return;
    }
    final int newEnd = (endIdx + 1).clamp(0, widget.series.length - 1);
    widget.onRangeSelected!((current.$1, widget.series[newEnd]));
  }

  void _handleShrinkRange() {
    final (T, T)? current = widget.selectedRange;
    if (current == null || widget.onRangeSelected == null) {
      return;
    }
    if (widget.series.isEmpty) {
      return;
    }
    final int startIdx = _indexOf(current.$1);
    final int endIdx = _indexOf(current.$2);
    if (startIdx < 0 || endIdx < 0) {
      return;
    }
    final int newEnd = (endIdx - 1).clamp(startIdx, widget.series.length - 1);
    widget.onRangeSelected!((current.$1, widget.series[newEnd]));
  }

  void _handleConfirmRange() {
    final (T, T)? current = widget.selectedRange;
    if (current == null || widget.onRangeSelected == null) {
      return;
    }
    widget.onRangeSelected!(current);
  }

  void _handleClearRange() {
    widget.onRangeSelected?.call(null);
  }

  void _onDragStart(DragStartDetails details) {
    // Anchor the band's LEFT edge at the raw pointer-down position (captured
    // by the outer Listener) rather than the recognizer's slop-shifted
    // start, so the band starts where the user actually pressed. The band's
    // RIGHT edge tracks the recognizer's reported position — slop-shifted
    // for a real drag, or the down position for a force-accepted tap
    // (zero-width) — so `_onDragEnd` can distinguish a tap from a real drag.
    final Offset start = _downPosition ?? details.localPosition;
    setState(() {
      _dragStart = start;
      _dragCurrent = details.localPosition;
      _sawDragUpdate = false;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragCurrent = details.localPosition;
      _sawDragUpdate = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final Offset? start = _dragStart;
    final Offset? current = _dragCurrent;
    final bool sawDragUpdate = _sawDragUpdate;
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
      _sawDragUpdate = false;
    });
    _downPosition = null;
    // A tap (pointer down + up with no horizontal movement) is force-accepted
    // by the gesture arena sweep, which fires onHorizontalDragStart/End
    // without any DragUpdateDetails. That is NOT a range drag — the tap
    // passes through to point-scrub (D-10). Discriminate via the update
    // flag, NOT pixel equality: a drag that returns to its start pixel
    // (start.dx == current.dx at release) is still a real drag, and on
    // some platforms pointer quantization reports the up-coordinate as
    // exactly the down-coordinate after a small out-and-back drag.
    if (start == null || current == null || !sawDragUpdate) {
      return;
    }
    // If the pixel→chart mapping fails (degenerate X window, collapsed
    // layout mid-gesture, series emptied between drag start and end) the
    // drag cannot be interpreted. Do NOT fire onRangeSelected(null) — that
    // is the "clear the range" signal and would silently drop the user's
    // existing selection. Only fire when a real range was produced.
    final (T, T)? mapped = _mapPixelsToRange(start, current);
    if (mapped == null) {
      return;
    }
    widget.onRangeSelected?.call(mapped);
  }

  @override
  Widget build(BuildContext context) {
    final Widget chart = ScaffoldChart<T>(
      series: widget.series,
      xAccessor: widget.xAccessor,
      yAccessor: widget.yAccessor,
      selectedPoint: widget.selectedPoint,
      onPointSelected: widget.onPointSelected,
      plotHeight: widget.plotHeight,
      lineColor: widget.lineColor,
      semanticsLabel: widget.chartSemanticsLabel,
      xLabelFormatter: widget.xLabelFormatter,
      yLabelFormatter: widget.yLabelFormatter,
      viewMinX: widget.viewMinX,
      viewMaxX: widget.viewMaxX,
      scrubMode: widget.scrubMode,
      onPositionChanged: widget.onPositionChanged,
    );

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            _ExtendRangeIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            _ShrinkRangeIntent(),
        SingleActivator(LogicalKeyboardKey.enter): _ConfirmRangeIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _ClearRangeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ExtendRangeIntent: CallbackAction<_ExtendRangeIntent>(
            onInvoke: (_ExtendRangeIntent intent) {
              _handleExtendRange();
              return null;
            },
          ),
          _ShrinkRangeIntent: CallbackAction<_ShrinkRangeIntent>(
            onInvoke: (_ShrinkRangeIntent intent) {
              _handleShrinkRange();
              return null;
            },
          ),
          _ConfirmRangeIntent: CallbackAction<_ConfirmRangeIntent>(
            onInvoke: (_ConfirmRangeIntent intent) {
              _handleConfirmRange();
              return null;
            },
          ),
          _ClearRangeIntent: CallbackAction<_ClearRangeIntent>(
            onInvoke: (_ClearRangeIntent intent) {
              _handleClearRange();
              return null;
            },
          ),
        },
        // Listener.onPointerDown requests focus BEFORE the gesture arena
        // resolves AND captures the raw down position — the latter anchors
        // the band's left edge at the true press point (see _onDragStart).
        child: Listener(
          onPointerDown: (PointerDownEvent event) {
            _focusNode.requestFocus();
            _downPosition = event.localPosition;
          },
          behavior: HitTestBehavior.translucent,
          child: Focus(
            focusNode: _focusNode,
            autofocus: false,
            child: ScaffoldFocusOutline(
              focusNode: _focusNode,
              // UAT-driven policy shared with the scrubber: paint the ring
              // on ANY primary focus (tap-to-focus leaves the FocusManager
              // in hover/touch highlight mode).
              showRingWhenFocused: true,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  _stackWidth = constraints.maxWidth;
                  _stackHeight = constraints.maxHeight;
                  final ScaffoldPalette palette = context.palette;
                  final (double left, double right)? band = _resolveBand();
                  return Stack(
                    children: <Widget>[
                      ScaffoldTouchTarget(child: chart),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: _onDragStart,
                          onHorizontalDragUpdate: _onDragUpdate,
                          onHorizontalDragEnd: _onDragEnd,
                          // IgnorePointer on the painter is load-bearing: a
                          // CustomPainter is hit-test-opaque by default
                          // (CustomPainter.hitTest defers to `true`), which
                          // would short-circuit the Stack's child hit test and
                          // starve the chart below of tap AND hover. Ignoring
                          // the painter keeps the translucent GestureDetector's
                          // Listener in the hit path (so the horizontal-drag
                          // recognizer still joins the arena first and beats
                          // the chart's pan), while the chart below is also hit
                          // — tap/hover pass through to point-scrub (D-10).
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _RangeBandPainter(
                                left: band?.$1,
                                right: band?.$2,
                                bandColor: palette.lightGreenPrimary
                                    .withValues(alpha: _kBandFillAlpha),
                                edgeColor: palette.lightGreenPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the selection band: a 12%-alpha accent fill between the band's
/// left/right edge pixels, plus 1px accent edge rules at both ends.
///
/// The edge rules are the band's visual "handles". The hit area for the
/// edges is the full band extent — the overlay GestureDetector covers the
/// entire plot (translucent), and the whole interaction surface is wrapped
/// in `ScaffoldTouchTarget` to guarantee the 48x48 minimum interactive
/// dimension. No separate edge-handle geometry is needed because the band is
/// report-only: resizing happens via Shift+Arrow, not edge dragging.
class _RangeBandPainter extends CustomPainter {
  const _RangeBandPainter({
    required this.left,
    required this.right,
    required this.bandColor,
    required this.edgeColor,
  });

  /// Left edge x (widget-space), or null when no band is active.
  final double? left;

  /// Right edge x (widget-space), or null when no band is active.
  final double? right;

  /// Fill color — `palette.lightGreenPrimary` at 12% alpha.
  final Color bandColor;

  /// Edge-rule color — `palette.lightGreenPrimary` at full opacity.
  final Color edgeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double? l = left;
    final double? r = right;
    if (l == null || r == null) {
      return;
    }
    final double lo = math.min(l, r);
    final double hi = math.max(l, r);
    canvas.drawRect(
      Rect.fromLTRB(lo, 0.0, hi, size.height),
      Paint()..color = bandColor,
    );
    final Paint edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = _kEdgeRuleWidth;
    canvas.drawLine(Offset(lo, 0.0), Offset(lo, size.height), edgePaint);
    canvas.drawLine(Offset(hi, 0.0), Offset(hi, size.height), edgePaint);
  }

  @override
  bool shouldRepaint(_RangeBandPainter oldDelegate) =>
      left != oldDelegate.left ||
      right != oldDelegate.right ||
      bandColor != oldDelegate.bandColor ||
      edgeColor != oldDelegate.edgeColor;
}

/// Intent for Shift+ArrowRight — extend the range end by one series point.
final class _ExtendRangeIntent extends Intent {
  const _ExtendRangeIntent();
}

/// Intent for Shift+ArrowLeft — shrink the range end by one series point.
final class _ShrinkRangeIntent extends Intent {
  const _ShrinkRangeIntent();
}

/// Intent for Enter — confirm the current range (re-fire).
final class _ConfirmRangeIntent extends Intent {
  const _ConfirmRangeIntent();
}

/// Intent for Escape — clear the range.
final class _ClearRangeIntent extends Intent {
  const _ClearRangeIntent();
}
