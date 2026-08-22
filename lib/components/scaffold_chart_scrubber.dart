/// `ScaffoldChartScrubber<T>` — point selection/scrubbing composition
/// around `ScaffoldChart` (WIDG-36).
///
/// Owns keyboard navigation (ArrowLeft/ArrowRight move selection, Enter
/// confirms, Escape clears), PointerExit clearing (D-05 hover-exit pattern),
/// focus outline, 48x48 touch-target expansion, and the scrub-area Semantics
/// label. The atom does NOT render a tooltip or readout — consumers compose
/// the readout externally using their own `selectedPoint` state.
///
/// Touch interaction inside the plot area is forwarded to the inner
/// `ScaffoldChart`'s `onPointSelected` — the chart-engine's touch handler
/// handles tap/drag; the scrubber's job is the keyboard + focus + hover-exit
/// + hit-area affordances that turn "a chart you can tap" into "a chart you
/// can scrub accessibly."
///
/// This file contains ZERO chart-library imports and zero domain knowledge.
/// Composition only: the atom stacks `ScaffoldLiveRegion` (optional) →
/// `Semantics` → `Shortcuts`/`Actions`/`Focus` → `ScaffoldFocusOutline` →
/// `MouseRegion` → `ScaffoldTouchTarget` → `ScaffoldChart<T>`.
///
/// Stateless for selection state — truth lives in the consumer. The atom
/// holds ONLY transient interaction state internally (a `FocusNode` shared
/// between the key-dispatch `Focus` widget and the `ScaffoldFocusOutline`
/// ring) — this is the standard "private StatefulWidget may hold transient
/// interaction state" carve-out from the inherited locked patterns.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scaffold_chart.dart';
import 'scaffold_focus_outline.dart';
import 'scaffold_live_region.dart';
import 'scaffold_touch_target.dart';

/// Point-selection composition atom — generic over the consumer's series
/// element type, exactly mirroring `ScaffoldChart<T>`'s generic.
///
/// See the file-level doc comment for the full contract. All keyboard,
/// pointer, focus, and a11y behavior is owned here; all chart rendering is
/// delegated to `ScaffoldChart<T>`; all readout rendering is delegated to
/// the consumer.
class ScaffoldChartScrubber<T> extends StatelessWidget {
  /// Creates a scrubber over [series].
  const ScaffoldChartScrubber({
    super.key,
    required this.series,
    required this.xAccessor,
    required this.yAccessor,
    this.selectedPoint,
    this.onPointSelected,
    this.scrubberSemanticsLabel,
    this.announceValue,
    this.announceLabel,
    this.plotHeight,
    this.lineColor,
    this.chartSemanticsLabel,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.viewMinX,
    this.viewMaxX,
  });

  /// The data series; passed through to `ScaffoldChart`.
  final List<T> series;

  /// Maps an element of [series] to its X coordinate.
  final double Function(T) xAccessor;

  /// Maps an element of [series] to its Y coordinate.
  final double Function(T) yAccessor;

  /// The currently selected point, owned by the consumer.
  final T? selectedPoint;

  /// Fires when the selection changes (tap, drag, ArrowLeft/Right, Enter,
  /// Escape, or PointerExit).
  final ValueChanged<T?>? onPointSelected;

  /// Optional semantics label for the scrub interaction area. Defaults to
  /// `'Chart scrubber'`.
  final String? scrubberSemanticsLabel;

  /// Optional consumer-supplied formatted value for the live region. When
  /// non-null, the atom wraps the scrub area in a `ScaffoldLiveRegion` so
  /// screen readers announce value changes; when null, no live-region
  /// wrapper is added.
  final String? announceValue;

  /// Optional live-region label. Defaults to `'Selected point'`. Ignored
  /// when [announceValue] is null.
  final String? announceLabel;

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

  @override
  Widget build(BuildContext context) {
    // Innermost layer: the composed chart.
    final Widget chart = ScaffoldChart<T>(
      series: series,
      xAccessor: xAccessor,
      yAccessor: yAccessor,
      selectedPoint: selectedPoint,
      onPointSelected: onPointSelected,
      plotHeight: plotHeight,
      lineColor: lineColor,
      semanticsLabel: chartSemanticsLabel,
      xLabelFormatter: xLabelFormatter,
      yLabelFormatter: yLabelFormatter,
      viewMinX: viewMinX,
      viewMaxX: viewMaxX,
    );

    // The interactive core is a private StatefulWidget that owns the
    // FocusNode shared between key dispatch and the focus ring — see the
    // file-level doc comment for the stateless-for-selection contract.
    final Widget interactive = _ScrubberCore<T>(
      series: series,
      xAccessor: xAccessor,
      yAccessor: yAccessor,
      selectedPoint: selectedPoint,
      onPointSelected: onPointSelected,
      child: chart,
    );

    // Scrub-area semantics — separate from the chart's own 'Chart' label so
    // screen readers announce the interaction affordance distinctly.
    final Widget labelled = Semantics(
      label: scrubberSemanticsLabel ?? 'Chart scrubber',
      child: interactive,
    );

    // Outermost layer: optional live-region announcement. The consumer
    // supplies the formatted value string; the atom only wires the region.
    final String? announce = announceValue;
    if (announce == null) {
      return labelled;
    }
    return ScaffoldLiveRegion(
      label: announceLabel ?? 'Selected point',
      value: announce,
      child: labelled,
    );
  }
}

/// Private stateful core — owns the shared [FocusNode] used by both the
/// key-dispatch [Focus] widget and the [ScaffoldFocusOutline] ring.
///
/// Holds ONLY transient interaction state (the focus node). Selection truth
/// stays with the consumer; this widget re-builds cleanly from its inputs.
class _ScrubberCore<T> extends StatefulWidget {
  const _ScrubberCore({
    required this.series,
    required this.xAccessor,
    required this.yAccessor,
    required this.selectedPoint,
    required this.onPointSelected,
    required this.child,
  });

  final List<T> series;
  final double Function(T) xAccessor;
  final double Function(T) yAccessor;
  final T? selectedPoint;
  final ValueChanged<T?>? onPointSelected;
  final Widget child;

  @override
  State<_ScrubberCore<T>> createState() => _ScrubberCoreState<T>();
}

class _ScrubberCoreState<T> extends State<_ScrubberCore<T>> {
  late final FocusNode _focusNode =
      FocusNode(debugLabel: 'ScaffoldChartScrubber');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Looks up [widget.selectedPoint] in [widget.series] by ACCESSOR-EQUALITY
  /// (not identity) so consumers can pass a freshly-constructed `T`
  /// equal-by-value to a series element. Returns -1 when selectedPoint is
  /// null or not found.
  int _selectedIndex() {
    final T? current = widget.selectedPoint;
    if (current == null) {
      return -1;
    }
    final double targetX = widget.xAccessor(current);
    final double targetY = widget.yAccessor(current);
    return widget.series.indexWhere(
      (T item) =>
          widget.xAccessor(item) == targetX &&
          widget.yAccessor(item) == targetY,
    );
  }

  void _handlePrev() {
    if (widget.series.isEmpty || widget.onPointSelected == null) {
      return;
    }
    final int idx = _selectedIndex();
    final int next = idx < 0
        ? widget.series.length - 1
        : (idx - 1).clamp(0, widget.series.length - 1);
    widget.onPointSelected!(widget.series[next]);
  }

  void _handleNext() {
    if (widget.series.isEmpty || widget.onPointSelected == null) {
      return;
    }
    final int idx = _selectedIndex();
    final int next =
        idx < 0 ? 0 : (idx + 1).clamp(0, widget.series.length - 1);
    widget.onPointSelected!(widget.series[next]);
  }

  void _handleConfirm() {
    final T? current = widget.selectedPoint;
    if (current == null || widget.onPointSelected == null) {
      return;
    }
    widget.onPointSelected!(current);
  }

  void _handleClear() {
    // Escape fires unconditionally — even on an empty series or when
    // selectedPoint is already null — so consumers can rely on it as a
    // generic "clear" signal.
    widget.onPointSelected?.call(null);
  }

  void _handleMouseExit(PointerExitEvent _) {
    // MouseRegion.onExit is the canonical "pointer left the hit area" hook
    // — the D-05 hover-exit pattern. The framework delivers this as a
    // PointerExitEvent (the plan-spec wording for this hook is
    // "onPointerExit"); MouseRegion surfaces it via its `onExit` parameter.
    // Fire unconditionally — even when selectedPoint is already null — so
    // consumers can rely on it as a generic "hover ended" signal.
    widget.onPointSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
        SingleActivator(LogicalKeyboardKey.enter): _ConfirmIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _ClearIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PrevIntent: CallbackAction<_PrevIntent>(
            onInvoke: (_PrevIntent intent) {
              _handlePrev();
              return null;
            },
          ),
          _NextIntent: CallbackAction<_NextIntent>(
            onInvoke: (_NextIntent intent) {
              _handleNext();
              return null;
            },
          ),
          _ConfirmIntent: CallbackAction<_ConfirmIntent>(
            onInvoke: (_ConfirmIntent intent) {
              _handleConfirm();
              return null;
            },
          ),
          _ClearIntent: CallbackAction<_ClearIntent>(
            onInvoke: (_ClearIntent intent) {
              _handleClear();
              return null;
            },
          ),
        },
        // Listener.onPointerDown requests focus BEFORE the gesture arena
        // resolves — GestureDetector.onTap would fire after the chart's
        // internal gesture recognizer claims the tap, which is too late for
        // focus traversal to see this widget as the intended target. Using
        // the raw pointer-down hook makes tap-to-focus deterministic.
        child: Listener(
          onPointerDown: (_) => _focusNode.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: Focus(
            focusNode: _focusNode,
            autofocus: false,
            child: ScaffoldFocusOutline(
              focusNode: _focusNode,
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                onExit: _handleMouseExit,
                child: ScaffoldTouchTarget(
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Intent for ArrowLeft — move selection to the previous data point.
final class _PrevIntent extends Intent {
  const _PrevIntent();
}

/// Intent for ArrowRight — move selection to the next data point.
final class _NextIntent extends Intent {
  const _NextIntent();
}

/// Intent for Enter — confirm the current selection.
final class _ConfirmIntent extends Intent {
  const _ConfirmIntent();
}

/// Intent for Escape — clear the selection.
final class _ClearIntent extends Intent {
  const _ClearIntent();
}
