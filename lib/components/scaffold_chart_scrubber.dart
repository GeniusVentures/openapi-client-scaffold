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
/// Composition only: the atom stacks `ScaffoldLiveRegion` (always present,
/// silent when `announceValue` is null) → `Semantics` →
/// `Shortcuts`/`Actions`/`Focus` → `ScaffoldFocusOutline` → `MouseRegion` →
/// `ScaffoldTouchTarget` → `ScaffoldChart<T>`.
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

// Re-export the ScrubMode enum so consumers importing ONLY the scrubber can
// still name the D-08 smooth-mode switch without a second import of the
// chart atom. (The enum lives in scaffold_chart.dart — the base atom — to
// avoid a chart -> scrubber -> chart circular import.)
export 'scaffold_chart.dart' show ScrubMode;

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
    this.scrubMode = ScrubMode.snap,
    this.onPositionChanged,
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
  /// non-null, screen readers announce value changes; when null, the live
  /// region announces nothing. The `ScaffoldLiveRegion` wrapper is always
  /// present regardless of this value so the widget tree above the
  /// scrubber core stays type-stable across selection/clear cycles (a
  /// type change would drop the core's FocusNode and blink the focus
  /// ring).
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

  /// Scrub behavior mode (D-08); passed through to `ScaffoldChart`.
  /// Defaults to [ScrubMode.snap].
  final ScrubMode scrubMode;

  /// Continuous scrub-position callback (D-08); passed through to
  /// `ScaffoldChart`. Fires on hover/pan-move with the pointer's continuous
  /// chart-x and the linearly interpolated y between bracketing samples.
  final void Function(double x, double y)? onPositionChanged;

  @override
  Widget build(BuildContext context) {
    // The interactive core is a private StatefulWidget that owns the
    // FocusNode shared between key dispatch and the focus ring — see the
    // file-level doc comment for the stateless-for-selection contract.
    // The chart itself is built INSIDE the state so the state can wire
    // its own _dragActive tracking callbacks into the chart's gesture
    // lifecycle (Test 8b/8c — hover-exit must not clear during a drag).
    final Widget interactive = _ScrubberCore<T>(
      series: series,
      xAccessor: xAccessor,
      yAccessor: yAccessor,
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
    );

    // Scrub-area semantics — separate from the chart's own 'Chart' label so
    // screen readers announce the interaction affordance distinctly.
    final Widget labelled = Semantics(
      label: scrubberSemanticsLabel ?? 'Chart scrubber',
      child: interactive,
    );

    // Outermost layer: live-region announcement. The wrapper is ALWAYS
    // present — even when announceValue is null — so the widget TYPE
    // directly above _ScrubberCore never changes across selection/clear
    // cycles. Returning bare `labelled` when announceValue was null (the
    // previous shape) toggled Semantics <-> ScaffoldLiveRegion above the
    // core on every selection change, which discarded the _ScrubberCore
    // State (and its FocusNode) and made the focus ring blink off/on
    // (UAT defect). Semantics(value: null) announces nothing, so a null
    // announceValue stays silent.
    return ScaffoldLiveRegion(
      label: announceLabel ?? 'Selected point',
      value: announceValue,
      child: labelled,
    );
  }
}

/// Private stateful core — owns the shared [FocusNode] used by both the
/// key-dispatch [Focus] widget and the [ScaffoldFocusOutline] ring, and
/// tracks the chart's gesture lifecycle so hover-exit can be gated on
/// whether a drag is in progress (Test 8b/8c).
///
/// Holds ONLY transient interaction state (the focus node and the
/// drag-active flag). Selection truth stays with the consumer; this
/// widget re-builds cleanly from its inputs.
class _ScrubberCore<T> extends StatefulWidget {
  const _ScrubberCore({
    required this.series,
    required this.xAccessor,
    required this.yAccessor,
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
  State<_ScrubberCore<T>> createState() => _ScrubberCoreState<T>();
}

class _ScrubberCoreState<T> extends State<_ScrubberCore<T>> {
  late final FocusNode _focusNode =
      FocusNode(debugLabel: 'ScaffoldChartScrubber');

  /// Whether a scrub gesture (pan or tap) is currently active inside the
  /// chart's touch area. Tracked via the chart's gesture-lifecycle
  /// callbacks so the hover-exit handler can distinguish "pointer left
  /// during a drag" (must NOT clear) from "pointer left with no drag"
  /// (D-05 — must clear). See Test 8b/8c.
  bool _dragActive = false;

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
    //
    // UAT section 4 regression: MouseRegion.onExit fires for ANY pointer
    // exit — including synthetic exits while a drag is active (the pointer
    // crossing hit-test boundaries inside the chart). Clearing here raced
    // with the drag's own spot selection and produced the "scrub flickers
    // / oscillates with No selection" defect. Gate the clear on
    // `_dragActive`: only hover-exit with NO in-flight gesture clears.
    if (_dragActive) {
      return;
    }
    // Fire unconditionally (post-gate) — even when selectedPoint is
    // already null — so consumers can rely on it as a generic "hover
    // ended" signal.
    widget.onPointSelected?.call(null);
  }

  void _handleScrubGestureStart() {
    _dragActive = true;
  }

  void _handleScrubGestureEnd() {
    _dragActive = false;
  }

  @override
  Widget build(BuildContext context) {
    // Build the inner chart here (not in the parent) so the state's
    // _dragActive tracking callbacks can be wired into the chart's
    // gesture lifecycle.
    final Widget chart = ScaffoldChart<T>(
      series: widget.series,
      xAccessor: widget.xAccessor,
      yAccessor: widget.yAccessor,
      selectedPoint: widget.selectedPoint,
      onPointSelected: widget.onPointSelected,
      onScrubGestureStart: _handleScrubGestureStart,
      onScrubGestureEnd: _handleScrubGestureEnd,
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
              // UAT section 5 / UI-SPEC Interaction States row "Focus": the
              // scrub area MUST paint its focus ring on ANY primary focus,
              // not only keyboard-highlight focus. Tap-to-focus leaves the
              // FocusManager highlight mode in hover/touch, so the default
              // ScaffoldFocusOutline gating would never paint. Other atoms
              // (Phase 6 contract) keep the default keyboard-only behavior.
              showRingWhenFocused: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                onExit: _handleMouseExit,
                child: ScaffoldTouchTarget(
                  child: chart,
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
