/// ScaffoldSelectionActions — generic selection-anchored toolbar wrapper
/// (WIDG-39, D-05).
///
/// Wraps arbitrary selectable content; reports
/// `onSelectionChanged(TextSelection, String)`; positions a consumer-built
/// toolbar over the ACTIVE SELECTION rect via the wrapped
/// [SelectionArea]'s live `SelectableRegionState.selectionEndpoints` + an
/// Overlay `Positioned` entry. The atom ships no default actions — consumers
/// supply [ScaffoldSelectionActions.toolbarBuilder].
/// See `ScaffoldSelectionCopyAction` in `lib/components/` for a reusable
/// copy action (Plan 05).
///
/// Selection detection: the child is wrapped in a [SelectionArea], so any
/// `Text` descendants become selectable without requiring the child itself
/// to be a `SelectableText`. The toolbar appears when the selection becomes
/// non-collapsed and disappears when the selection collapses, on tap-outside,
/// on scroll of the wrapped content, or on the Escape key. Under
/// [ScaffoldMotion.reducedMotion] the appear/hide fade is zero-duration.
///
/// Placement is consumer-configurable via
/// [ScaffoldSelectionActions.toolbarPlacement]:
/// - [ScaffoldToolbarPlacement.above] anchors the toolbar's bottom-center to
///   the selection's top-center (default for `auto`).
/// - [ScaffoldToolbarPlacement.below] anchors the toolbar's top-center to the
///   selection's bottom-center.
/// - [ScaffoldToolbarPlacement.auto] defaults to `above`; on the next frame
///   after insertion the follower's paint bounds are checked and, if the
///   toolbar would paint above the top of the screen, the anchor swaps to
///   `below`.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Toolbar placement strategy for [ScaffoldSelectionActions].
enum ScaffoldToolbarPlacement {
  /// Place above the selection; fall back to below when insufficient space.
  auto,

  /// Always anchor above the selection's top edge.
  above,

  /// Always anchor below the selection's bottom edge.
  below,
}

/// Horizontal alignment of the toolbar relative to the selection.
///
/// Two anchor sources:
/// - [left] / [center] / [right] anchor to the SELECTION BOUNDING BOX — the
///   left edge, horizontal center, or right edge of the selected text. These
///   are direction-independent: it does not matter whether the user dragged,
///   double-clicked, or keyboard-selected.
/// - [first] / [last] anchor to the SELECTION ORDER — the first or last
///   selected character in the order the user selected them (the anchor edge
///   where the selection started, then the cursor edge where it ended). A
///   left-to-right drag puts [first] on the left; a right-to-left drag puts
///   [first] on the right.
///
///   Caveat: the framework's [SelectableRegionState.selectionEndpoints] sorts
///   endpoints top-to-bottom rather than preserving base/extent order, so for a
///   reversed (upward) MULTI-line selection `first`/`last` resolve to the
///   top/bottom endpoints instead of the anchor/cursor edges. Single-line and
///   forward multi-line selections are unaffected.
enum ScaffoldToolbarAlignment {
  /// Toolbar's LEFT edge aligns to the selection bounding box's left edge.
  left,

  /// Toolbar is horizontally centered on the selection bounding box.
  center,

  /// Toolbar's RIGHT edge aligns to the selection bounding box's right edge.
  right,

  /// Toolbar's LEFT edge aligns to the FIRST selected character in selection
  /// order (the anchor edge where the selection started).
  first,

  /// Toolbar's RIGHT edge aligns to the LAST selected character in selection
  /// order (the cursor edge where the selection ended). Default.
  last,
}

/// Generic selection-anchored toolbar wrapper.
///
/// See file-level docstring for the contract. The atom never ships default
/// actions — [toolbarBuilder] is REQUIRED and the atom renders only what
/// the consumer supplies.
class ScaffoldSelectionActions extends StatefulWidget {
  /// Creates a wrapper around [child] that surfaces [toolbarBuilder] output
  /// anchored to the active text selection.
  const ScaffoldSelectionActions({
    super.key,
    required this.child,
    required this.toolbarBuilder,
    this.onSelectionChanged,
    this.toolbarPlacement = ScaffoldToolbarPlacement.auto,
    this.toolbarAlignment = ScaffoldToolbarAlignment.last,
  });

  /// The wrapped selectable subtree. Typically a [SelectableText] or any
  /// widget containing [Text] descendants — the atom wraps the child in a
  /// [SelectionArea], so plain `Text` becomes selectable automatically.
  final Widget child;

  /// REQUIRED builder for the toolbar contents. Called with the current
  /// [BuildContext], the last reported [TextSelection], and the last
  /// selected plain-text. Returning a `SizedBox.shrink()` causes the atom
  /// to skip inserting the overlay entirely (no empty card).
  final Widget Function(BuildContext, TextSelection, String) toolbarBuilder;

  /// Fired on every selection change in the wrapped subtree. When the
  /// selection collapses or becomes empty, this fires with
  /// `TextSelection.collapsed(offset: -1)` and an empty string.
  final void Function(TextSelection, String)? onSelectionChanged;

  /// Toolbar placement strategy. Defaults to [ScaffoldToolbarPlacement.auto].
  final ScaffoldToolbarPlacement toolbarPlacement;

  /// Horizontal alignment of the toolbar relative to the selection. Defaults
  /// to [ScaffoldToolbarAlignment.last] (toolbar right edge on the last
  /// selected character). See [ScaffoldToolbarAlignment] for the
  /// bounding-box ([left]/[center]/[right]) vs selection-order
  /// ([first]/[last]) anchor sources.
  final ScaffoldToolbarAlignment toolbarAlignment;

  @override
  State<ScaffoldSelectionActions> createState() =>
      _ScaffoldSelectionActionsState();

  /// Deterministic selection-injection hook for tests.
  ///
  /// Drives the SAME internal handler as a real [SelectionArea]
  /// `onSelectionChanged` callback. Exists because driving a real
  /// [SelectionArea] selection in `flutter_test` is framework-brittle.
  ///
  /// When [plainText] is empty, simulates a collapsed selection (hides the
  /// toolbar, fires `onSelectionChanged` with collapsed offset -1). When
  /// non-empty, updates the cached selection/plainText, shows the toolbar,
  /// and fires `onSelectionChanged` with the supplied or synthesized
  /// full-span [TextSelection].
  @visibleForTesting
  static void debugSimulateSelection(
    State<ScaffoldSelectionActions> state,
    String plainText, {
    TextSelection? selection,
  }) {
    (state as _ScaffoldSelectionActionsState)
        ._handleSelection(plainText, selection: selection);
  }
}

class _ScaffoldSelectionActionsState extends State<ScaffoldSelectionActions> {
  // Key into the SelectionArea so the toolbar can be anchored to the ACTIVE
  // SELECTION rect. The key resolves to the SelectionArea element; the live
  // SelectableRegionState (whose selectionEndpoints carry the selection
  // geometry) is reached by walking its subtree — see _findRegionState.
  final GlobalKey<SelectableRegionState> _selectionRegionKey =
      GlobalKey<SelectableRegionState>();
  final GlobalKey _toolbarCardKey = GlobalKey();
  final FocusNode _escapeFocusNode =
      FocusNode(debugLabel: 'selectionActionsEscape');

  OverlayEntry? _toolbarEntry;
  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);
  String _lastPlainText = '';
  bool _toolbarVisible = false;

  // Global anchor points for the current selection, captured when the
  // toolbar is shown. primaryAnchor is the top-center of the selection rect;
  // secondaryAnchor (when present) is the bottom-center.
  TextSelectionToolbarAnchors? _anchors;

  // Resolved placement actually used for the current overlay entry. `auto`
  // starts as `above` and may be flipped to `below` by the post-frame check.
  ScaffoldToolbarPlacement _resolvedPlacement =
      ScaffoldToolbarPlacement.above;

  ScrollPosition? _observedScrollPosition;

  // Pointer-down tracking used to DEFER the toolbar until the selecting
  // pointer is released (mouse-up). onSelectionChanged fires on every
  // drag-move mutation; inserting the overlay then makes the toolbar pop up
  // and chase the growing selection. While _pointerSelectingCount > 0 we
  // cache the selection but skip _insertOrRefreshToolbar; on release (or
  // cancel) we insert once with the final geometry. GestureBinding's
  // PointerRouter is used so the release is observed even when the pointer
  // is let go outside this widget's bounds.
  int _pointerSelectingCount = 0;
  PointerRoute? _pendingPointerUpRoute;
  PointerRoute? _pendingPointerCancelRoute;

  @override
  void initState() {
    super.initState();
    // Attach the Escape handler directly to the node. The node is also passed
    // to SelectionArea as its focusNode (see build()), so during an active
    // selection SelectableRegion owns focus on this same node and Escape
    // reaches this handler without stealing focus from the region.
    _escapeFocusNode.onKeyEvent = _handleEscapeKey;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollListener();
  }

  @override
  void dispose() {
    _detachScrollListener();
    _removePointerRoutes();
    _toolbarEntry?.remove();
    _toolbarEntry = null;
    _escapeFocusNode.dispose();
    super.dispose();
  }

  void _removePointerRoutes() {
    final PointerRouter router = GestureBinding.instance.pointerRouter;
    if (_pendingPointerUpRoute != null) {
      router.removeGlobalRoute(_pendingPointerUpRoute!);
      _pendingPointerUpRoute = null;
    }
    if (_pendingPointerCancelRoute != null) {
      router.removeGlobalRoute(_pendingPointerCancelRoute!);
      _pendingPointerCancelRoute = null;
    }
  }

  /// A pointer went down inside the wrapped subtree. Register global routes
  /// so the matching up/cancel is observed even off-bounds, and mark the
  /// selection as in-progress (defers the toolbar until release).
  void _onPointerDown(PointerDownEvent event) {
    _pointerSelectingCount++;
    _removePointerRoutes();
    final PointerRouter router = GestureBinding.instance.pointerRouter;
    _pendingPointerUpRoute = (PointerEvent e) {
      if (e is PointerUpEvent) {
        _onPointerReleased();
      }
    };
    _pendingPointerCancelRoute = (PointerEvent e) {
      if (e is PointerCancelEvent) {
        _onPointerReleased();
      }
    };
    router.addGlobalRoute(_pendingPointerUpRoute!);
    router.addGlobalRoute(_pendingPointerCancelRoute!);
  }

  void _onPointerReleased() {
    _removePointerRoutes();
    if (_pointerSelectingCount > 0) {
      _pointerSelectingCount--;
    }
    // Show the toolbar with the FINAL selection geometry now that the
    // selecting pointer is released.
    if (_pointerSelectingCount == 0 &&
        _toolbarVisible &&
        _lastPlainText.isNotEmpty) {
      _insertOrRefreshToolbar();
    }
  }

  void _attachScrollListener() {
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final ScrollPosition? position = scrollable?.position;
    if (identical(position, _observedScrollPosition)) {
      return;
    }
    _observedScrollPosition?.removeListener(_onScroll);
    _observedScrollPosition = position;
    _observedScrollPosition?.addListener(_onScroll);
  }

  void _detachScrollListener() {
    _observedScrollPosition?.removeListener(_onScroll);
    _observedScrollPosition = null;
  }

  void _onScroll() {
    if (_toolbarVisible) {
      _hideToolbar();
    }
  }

  /// Unified selection handler invoked by both the real [SelectionArea]
  /// callback and the [debugSimulateSelection] test hook.
  ///
  /// [SelectionArea] reports plain-text only; the exact [TextSelection]
  /// offsets are not exposed by the framework, so the atom reports a
  /// synthetic full-span selection. Consumers needing exact offsets should
  /// wrap a [SelectableText] directly and drive the atom externally.
  void _handleSelection(String plainText, {TextSelection? selection}) {
    if (plainText.isEmpty) {
      final bool wasVisible = _toolbarVisible;
      setState(() {
        _lastSelection = const TextSelection.collapsed(offset: -1);
        _lastPlainText = '';
        _toolbarVisible = false;
      });
      if (wasVisible) {
        _toolbarEntry?.remove();
        _toolbarEntry = null;
        _anchors = null;
      }
      widget.onSelectionChanged
          ?.call(const TextSelection.collapsed(offset: -1), '');
      return;
    }

    final TextSelection resolvedSelection = selection ??
        TextSelection(baseOffset: 0, extentOffset: plainText.length);

    setState(() {
      _lastSelection = resolvedSelection;
      _lastPlainText = plainText;
      _toolbarVisible = true;
      _resolvedPlacement =
          widget.toolbarPlacement == ScaffoldToolbarPlacement.below
              ? ScaffoldToolbarPlacement.below
              : ScaffoldToolbarPlacement.above;
    });

    // Defer the overlay while a selecting pointer is down so the toolbar
    // pops up once (on mouse-up) at the final selection instead of chasing
    // the drag. Keyboard selections have no pointer down and show at once.
    if (_pointerSelectingCount == 0) {
      _insertOrRefreshToolbar();
    }

    widget.onSelectionChanged?.call(resolvedSelection, plainText);
  }

  void _onSelectionAreaChanged(SelectedContent? content) {
    if (content == null || content.plainText.isEmpty) {
      _handleSelection('');
      return;
    }
    _handleSelection(content.plainText);
  }

  bool _isShrink(Widget w) {
    return w is SizedBox && w.width == 0.0 && w.height == 0.0;
  }

  /// Computes the ACTIVE SELECTION's global anchor points from the region's
  /// live selection geometry.
  ///
  /// NOTE: we do NOT use `region.contextMenuAnchors` — that API is designed
  /// for context menus and, for multi-line selections, deliberately spans the
  /// full width of the editing region, which would center the toolbar on the
  /// whole text block instead of the selection. Instead we derive the anchor
  /// from the raw selectionEndpoints: the top edge sits startGlyphHeight
  /// above the start point, the bottom edge at the end point, and the
  /// horizontal anchor is chosen per [ScaffoldSelectionActions.toolbarAlignment]
  /// (bounding-box min/mid/max for left/center/right; first/last endpoint for
  /// first/last).
  ///
  /// When there is no live selection (e.g. the debugSimulateSelection test
  /// hook synthesizes one without real geometry), falls back to the region's
  /// own top-center / bottom-center so the toolbar still renders on-screen.
  /// Resolves the live [SelectableRegionState] inside our [SelectionArea].
  ///
  /// [_selectionRegionKey] is attached to the [SelectionArea] widget, whose
  /// state is NOT a [SelectableRegionState] — [SelectionArea] builds an
  /// internal [SelectableRegion] child. We walk the element subtree (the
  /// same public-widget pattern Flutter's own tests use) to reach it.
  SelectableRegionState? _findRegionState() {
    final BuildContext? areaContext = _selectionRegionKey.currentContext;
    if (areaContext == null) {
      return null;
    }
    SelectableRegionState? found;
    void visitor(Element element) {
      if (found != null) {
        return;
      }
      if (element is StatefulElement && element.state is SelectableRegionState) {
        found = element.state as SelectableRegionState;
        return;
      }
      element.visitChildren(visitor);
    }

    (areaContext as Element).visitChildren(visitor);
    return found;
  }

  TextSelectionToolbarAnchors? _computeAnchors() {
    final SelectableRegionState? region = _findRegionState();
    final RenderBox? areaBox =
        _selectionRegionKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? regionBox =
        region?.context.findRenderObject() as RenderBox?;
    // Read the live selection endpoints defensively: the SDK getter throws
    // (null-check on _selectionStart/_selectionEnd) when there is no active
    // selection — exactly the case for the debugSimulateSelection test hook,
    // which synthesizes selection content without driving the region's own
    // selection geometry. Treat any throw as "no live selection".
    List<TextSelectionPoint>? endpoints;
    if (region != null) {
      try {
        endpoints = region.selectionEndpoints;
      } catch (_) {
        endpoints = null;
      }
    }
    if (region != null &&
        regionBox != null &&
        regionBox.hasSize &&
        endpoints != null &&
        endpoints.isNotEmpty) {
      final Offset regionOrigin = regionBox.localToGlobal(Offset.zero);
      // selectionEndpoints returns the two endpoints sorted TOP-TO-BOTTOM (by
      // dy), not as [base, extent]. For single-line and forward multi-line
      // selections that still matches selection order (`first` = anchor edge,
      // `last` = cursor edge), but a reversed (upward) multi-line selection
      // swaps them — see the enum doc caveat. We deliberately consume the
      // sorted order because the vertical anchors below require `first` to be
      // the top edge.
      final Offset firstGlobal = regionOrigin + endpoints.first.point;
      final Offset lastGlobal = regionOrigin + endpoints.last.point;
      final double firstDx = firstGlobal.dx;
      final double lastDx = lastGlobal.dx;
      // left/center/right anchor to the selection's BOUNDING BOX (left edge,
      // horizontal center, right edge) regardless of how the selection was
      // made; first/last anchor to the top/bottom endpoint dx (selection-order
      // for single-line and forward selections).
      final double anchorDx;
      switch (widget.toolbarAlignment) {
        case ScaffoldToolbarAlignment.left:
          anchorDx = math.min(firstDx, lastDx);
        case ScaffoldToolbarAlignment.center:
          anchorDx = (firstDx + lastDx) / 2;
        case ScaffoldToolbarAlignment.right:
          anchorDx = math.max(firstDx, lastDx);
        case ScaffoldToolbarAlignment.first:
          anchorDx = firstDx;
        case ScaffoldToolbarAlignment.last:
          anchorDx = lastDx;
      }
      return TextSelectionToolbarAnchors(
        primaryAnchor: Offset(
          anchorDx,
          firstGlobal.dy - region.startGlyphHeight,
        ),
        secondaryAnchor: Offset(anchorDx, lastGlobal.dy),
      );
    }
    if (areaBox != null && areaBox.hasSize) {
      final Offset topLeft = areaBox.localToGlobal(Offset.zero);
      return TextSelectionToolbarAnchors(
        primaryAnchor: topLeft + Offset(areaBox.size.width / 2, 0),
        secondaryAnchor:
            topLeft + Offset(areaBox.size.width / 2, areaBox.size.height),
      );
    }
    return null;
  }

  void _insertOrRefreshToolbar() {
    // Build the toolbar child once to decide if we should show anything.
    final Widget probe = widget.toolbarBuilder(
      context,
      _lastSelection,
      _lastPlainText,
    );
    if (_isShrink(probe)) {
      // Consumer returned SizedBox.shrink() — do not insert the overlay at all.
      _toolbarEntry?.remove();
      _toolbarEntry = null;
      return;
    }

    // Capture the ACTIVE SELECTION's global anchor points (see
    // _computeAnchors). Recomputed again at overlay build time so the
    // toolbar always tracks the latest selection geometry.
    _anchors = _computeAnchors();

    if (_toolbarEntry != null) {
      _toolbarEntry!.markNeedsBuild();
      return;
    }

    final OverlayState overlay = Overlay.of(context);
    _toolbarEntry = OverlayEntry(builder: _buildToolbarOverlay);
    overlay.insert(_toolbarEntry!);

    // For `auto`, run a post-frame flip check.
    if (widget.toolbarPlacement == ScaffoldToolbarPlacement.auto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _toolbarEntry == null) {
          return;
        }
        final RenderObject? render =
            _toolbarCardKey.currentContext?.findRenderObject();
        if (render is RenderBox) {
          final Offset global = render.localToGlobal(Offset.zero);
          if (global.dy < 0 &&
              _resolvedPlacement != ScaffoldToolbarPlacement.below) {
            setState(() {
              _resolvedPlacement = ScaffoldToolbarPlacement.below;
            });
            _toolbarEntry?.markNeedsBuild();
          }
        }
      });
    }

    // Request keyboard focus so Escape is deliverable.
    _escapeFocusNode.requestFocus();
  }

  Widget _buildToolbarOverlay(BuildContext overlayContext) {
    final palette = context.palette;
    final dimens = context.dimens;
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;

    final Widget toolbarCard = GestureDetector(
      // Absorb taps INSIDE the toolbar so the tap-outside dismissal below
      // does not fire when the user interacts with a toolbar action.
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: _toolbarCardKey,
        child: AnimatedOpacity(
          opacity: _toolbarVisible ? 1.0 : 0.0,
          duration: reducedMotion
              ? Duration.zero
              : ScaffoldMotionDurations.short,
          curve: ScaffoldMotionCurves.decelerate,
          child: ScaffoldSurface(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(dimens.radiusMd),
            border: Border.all(color: palette.borderSubtle, width: 1),
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space4,
              vertical: dimens.space4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                widget.toolbarBuilder(
                  overlayContext,
                  _lastSelection,
                  _lastPlainText,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Position the toolbar at the ACTIVE SELECTION's anchor point. The
    // anchors are recomputed HERE (at overlay build time) rather than only
    // when the entry was inserted, so the toolbar tracks the latest selection
    // geometry — the entry is inserted mid-gesture when the selection is
    // still changing, and the final geometry is only stable by the time the
    // overlay actually builds after the gesture completes.
    //
    // `above` centers the toolbar's bottom edge on the selection's
    // top-center (primaryAnchor); `below` centers its top edge on the
    // selection's bottom-center (secondaryAnchor). The overlay's Stack is
    // full-screen, so Positioned coordinates are global. FractionalTranslation
    // centers the card on the anchor; the vertical shift pins the correct
    // edge (bottom for above, top for below) plus the spacing offset.
    final TextSelectionToolbarAnchors? anchors = _computeAnchors() ?? _anchors;
    final Widget positionedToolbar;
    if (anchors == null) {
      // No geometry available (shouldn't happen — fallback anchors are set
      // before insert) — render unpositioned at the stack origin.
      positionedToolbar = toolbarCard;
    } else {
      final bool below =
          _resolvedPlacement == ScaffoldToolbarPlacement.below;
      final Offset anchor =
          below ? (anchors.secondaryAnchor ?? anchors.primaryAnchor)
              : anchors.primaryAnchor;
      final double verticalShift = below ? 0.0 : -1.0;
      // Pin the toolbar edge matching the requested alignment to the anchor:
      // left/first → toolbar LEFT edge on the anchor (no shift),
      // center → centered (-0.5), right/last → toolbar RIGHT edge on the
      // anchor (-1.0).
      final double horizontalShift;
      switch (widget.toolbarAlignment) {
        case ScaffoldToolbarAlignment.left:
          horizontalShift = 0.0;
        case ScaffoldToolbarAlignment.center:
          horizontalShift = -0.5;
        case ScaffoldToolbarAlignment.right:
          horizontalShift = -1.0;
        case ScaffoldToolbarAlignment.first:
          horizontalShift = 0.0;
        case ScaffoldToolbarAlignment.last:
          horizontalShift = -1.0;
      }
      positionedToolbar = Positioned(
        left: anchor.dx,
        top: anchor.dy + (below ? dimens.space4 : -dimens.space4),
        child: FractionalTranslation(
          translation: Offset(horizontalShift, verticalShift),
          child: toolbarCard,
        ),
      );
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: _hideToolbar,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        positionedToolbar,
      ],
    );
  }

  void _hideToolbar() {
    if (!_toolbarVisible && _toolbarEntry == null) {
      return;
    }
    setState(() {
      _toolbarVisible = false;
    });
    _toolbarEntry?.remove();
    _toolbarEntry = null;
    _anchors = null;
  }

  KeyEventResult _handleEscapeKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _toolbarVisible) {
      _hideToolbar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Deterministic selection-injection hook for tests — see
  /// [ScaffoldSelectionActions.debugSimulateSelection]. The static hook on
  /// the public class forwards here via the private [_handleSelection]
  /// handler so test-injected and real SelectionArea-driven selection
  /// updates share the exact same code path.
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      child: SelectionArea(
        key: _selectionRegionKey,
        focusNode: _escapeFocusNode,
        onSelectionChanged: _onSelectionAreaChanged,
        child: widget.child,
      ),
    );
  }
}
