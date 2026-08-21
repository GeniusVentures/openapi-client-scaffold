/// ScaffoldSelectionActions — generic selection-anchored toolbar wrapper
/// (WIDG-39, D-05).
///
/// Wraps arbitrary selectable content; reports
/// `onSelectionChanged(TextSelection, String)`; positions a consumer-built
/// toolbar via `LayerLink` + `CompositedTransformFollower`. The atom ships
/// no default actions — consumers supply [ScaffoldSelectionActions.toolbarBuilder].
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
  final LayerLink _toolbarLink = LayerLink();
  final GlobalKey _followerKey = GlobalKey();
  final FocusNode _escapeFocusNode =
      FocusNode(debugLabel: 'selectionActionsEscape');

  OverlayEntry? _toolbarEntry;
  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);
  String _lastPlainText = '';
  bool _toolbarVisible = false;

  // Resolved placement actually used for the current overlay entry. `auto`
  // starts as `above` and may be flipped to `below` by the post-frame check.
  ScaffoldToolbarPlacement _resolvedPlacement =
      ScaffoldToolbarPlacement.above;

  ScrollPosition? _observedScrollPosition;

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
    _toolbarEntry?.remove();
    _toolbarEntry = null;
    _escapeFocusNode.dispose();
    super.dispose();
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

    _insertOrRefreshToolbar();

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
            _followerKey.currentContext?.findRenderObject();
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

    final Alignment targetAnchor;
    final Alignment followerAnchor;
    final Offset offset;
    if (_resolvedPlacement == ScaffoldToolbarPlacement.below) {
      targetAnchor = Alignment.bottomCenter;
      followerAnchor = Alignment.topCenter;
      offset = Offset(0, dimens.space4);
    } else {
      targetAnchor = Alignment.topCenter;
      followerAnchor = Alignment.bottomCenter;
      offset = Offset(0, -dimens.space4);
    }

    final Widget toolbarCard = GestureDetector(
      // Absorb taps INSIDE the toolbar so the tap-outside dismissal below
      // does not fire when the user interacts with a toolbar action.
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: _followerKey,
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

    // A loose-fit Stack so the CompositedTransformFollower shrink-wraps to
    // the toolbar card. Under Positioned.fill (the old code) the Overlay
    // theater laid the follower out with tight full-screen constraints, so
    // RenderFollowerLayer sized to the full screen and
    // followerAnchor.alongSize(size) computed against the SCREEN — painting
    // the toolbar off-screen. Stack (StackFit.loose, the default) gives
    // non-positioned children loose constraints, letting the follower size
    // to its child so the anchor math resolves against the toolbar's own
    // extent.
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: _hideToolbar,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        CompositedTransformFollower(
          link: _toolbarLink,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          offset: offset,
          child: toolbarCard,
        ),
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
    return CompositedTransformTarget(
      link: _toolbarLink,
      child: SelectionArea(
        focusNode: _escapeFocusNode,
        onSelectionChanged: _onSelectionAreaChanged,
        child: widget.child,
      ),
    );
  }
}
