import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/toast/toast_widget.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

enum ToastType { success, error, warning }

/// Height each toast reserves for the one below it. Density-aware rather than
/// one flat stride, because a compact pill is roughly half a card.
///
/// ponytail: these are measured constants, not laid-out heights — a card
/// whose message wraps to three lines at 2.0x text scale will overlap the
/// toast under it. The upgrade is to hoist all live toasts into a single
/// `OverlayEntry` holding a `Column`, at which point the stack lays itself
/// out and these disappear. Not done here because it rewrites the entry
/// lifecycle for a case only large text scale reaches.
const double _kCardStride = 84.0;
const double _kCompactStride = 44.0;

/// Beyond this the oldest is evicted. Was uncapped: at the old flat 85px
/// stride the fourth toast sat at 355px and the sixth was off screen.
const int _kMaxVisible = 3;

/// Mobile app bar height — `MobileHeader.preferredSize`.
const double _kMobileHeaderHeight = 60.0;

/// The one call. Everything in the app that has something to tell the user
/// comes through here.
///
/// Density is chosen by [title]: with one the toast is an alert and gets the
/// card, the dismiss button and the longer read; without one it is a
/// confirmation and gets the compact pill. That is not a shortcut — a title
/// is what distinguishes "Verification failed / Please try again" from
/// "Link copied", and the two want different amounts of the screen.
void showToast(
  BuildContext context,
  String message, {
  String? title,
  ToastType type = ToastType.success,
  Duration? duration,
  VoidCallback? onClose,
}) {
  ToastManager.instance.show(
    context: context,
    message: message,
    title: title,
    type: type,
    duration: duration,
    onClose: onClose,
  );
}

/// Manages toast notifications as overlay entries.
class ToastManager {
  static final ToastManager instance = ToastManager._();
  ToastManager._();

  final List<_ActiveToast> _toasts = [];

  /// The overlay the current toasts were inserted into. This manager is a
  /// singleton and can outlive the overlay itself (widget-test teardown,
  /// full-app restart). When `show` resolves a DIFFERENT overlay, every
  /// record from the old one is stale — those entries' overlays were torn
  /// down and (if the teardown raced the first frame) no State ever ran
  /// `_forget` for them (CR-02/CR-04 edge).
  OverlayState? _overlay;

  @visibleForTesting
  int get visibleCount => _toasts.length;

  void show({
    required BuildContext context,
    required String message,
    String? title,
    ToastType type = ToastType.success,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    // Every in-page caller has an ancestor Overlay (the app shell's own), so
    // `Overlay.maybeOf` resolves on the first branch. The fallback is for a
    // context that IS the root Navigator's own element, where there is no
    // Overlay ancestor to find. Deliberately no early return if neither
    // resolves: throwing is what `Overlay.of` already did, and swallowing
    // the toast would be worse.
    final overlay = Overlay.maybeOf(context) ?? Navigator.of(context).overlay!;
    final isCard = title != null;

    // New overlay, stale records: drop everything from the previous one.
    if (!identical(overlay, _overlay)) {
      for (final toast in _toasts) {
        toast.dismissed = true;
        toast.onClose = null;
      }
      _toasts.clear();
      _overlay = overlay;
    }

    while (_toasts.length >= _kMaxVisible) {
      _dismiss(_toasts.first, null);
    }

    late final _ActiveToast toast;
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AnimatedToast(
        offsetAbove: _offsetAbove(toast),
        title: title,
        message: message,
        type: type,
        // The auto-dismiss timer lives on the State, not here, so that a tree
        // torn down while a toast is up cancels it. Held on the manager it
        // survived its own overlay — which in a widget test is a
        // pending-timer failure, and in the app is a callback into a dead
        // route. (CR-02: this is the structural fix — the timer's lifecycle
        // is bound to the widget's element.)
        duration:
            duration ??
            (isCard ? const Duration(seconds: 5) : _kCompactDuration),
        onControllerReady: (c) => toast.controller = c,
        // CR-03 hybrid: the `dismissed` flag guards re-entry, and the
        // stored callback is nulled after firing so a second `_dismiss`
        // (swipe racing the auto-dismiss timer) cannot fire it twice.
        onDismiss: () => _dismiss(toast, onClose),
        onDisposed: () => _forget(toast),
      ),
    );

    toast = _ActiveToast(entry: entry, isCard: isCard, onClose: onClose);
    _toasts.add(toast);
    overlay.insert(entry);
    _restack();
  }

  /// Drops a toast whose widget has gone away without being dismissed — the
  /// route was popped, or the whole tree was disposed. No animation, no
  /// `entry.remove()`: the entry is already going. (CR-04: route-pop
  /// teardown path — the State's dispose runs before the controller's, so
  /// no builder ever runs against a disposed AnimationController.)
  void _forget(_ActiveToast toast) {
    if (toast.dismissed) {
      return;
    }
    toast.dismissed = true;
    _toasts.remove(toast);
    toast.onClose = null;
  }

  /// Unconditional list drop used by [disposeAll] and by `show` before
  /// insert, so a toast whose entry was inserted but never built (teardown
  /// raced the first frame — CR-02/CR-04) is not left behind when
  /// [ToastManager.instance]'s singleton list outlives the overlay.
  void _drop(_ActiveToast toast) {
    toast.dismissed = true;
    _toasts.remove(toast);
    toast.onClose = null;
  }

  static const Duration _kCompactDuration = Duration(seconds: 2);

  /// Sum of the strides of every toast currently above this one. Read inside
  /// the entry's builder, so [_restack] only has to mark entries dirty.
  double _offsetAbove(_ActiveToast toast) {
    final index = _toasts.indexOf(toast);
    if (index <= 0) {
      return 0;
    }
    var total = 0.0;
    for (var i = 0; i < index; i++) {
      total += _toasts[i].isCard ? _kCardStride : _kCompactStride;
    }
    return total;
  }

  /// Positions are derived from list order, so anything that changes the
  /// list has to rebuild the survivors — otherwise a dismissed toast leaves
  /// a hole and the ones under it never move up.
  void _restack() {
    for (final toast in _toasts) {
      // `mounted` guards the teardown path: _forget runs from State.dispose,
      // and marking a sibling entry dirty while the overlay itself is being
      // disposed asserts. (CR-04)
      if (toast.entry.mounted) {
        toast.entry.markNeedsBuild();
      }
    }
  }

  void _dismiss(_ActiveToast toast, VoidCallback? onClose) {
    if (toast.dismissed) {
      return;
    }
    toast.dismissed = true;
    _toasts.remove(toast);

    final controller = toast.controller;
    if (controller != null &&
        (controller.isAnimating || controller.isCompleted)) {
      controller.reverse().then((_) => toast.entry.remove());
    } else {
      // Synchronous teardown: the controller never started (dispose raced
      // the first frame), so reversing would hit "used after dispose" and
      // the OverlayEntry would leak. (CR-02)
      toast.entry.remove();
    }

    _restack();
    onClose?.call();
  }

  /// Clear all active toasts synchronously. Route-pop teardown should NOT
  /// trigger consumer close callbacks, so `onClose` is passed as null and
  /// any stored callback is dropped without firing. [_drop] is used instead
  /// of [_dismiss]: the latter's guard makes it a no-op for toasts that
  /// never built (teardown raced the first frame), which would leak them
  /// from the singleton list across overlays.
  void disposeAll() {
    // Iterate a copy — _drop mutates the list.
    for (final toast in [..._toasts]) {
      _drop(toast);
    }
  }
}

class _ActiveToast {
  final OverlayEntry entry;
  final bool isCard;
  AnimationController? controller; // set once the widget initializes
  bool dismissed = false;

  /// Consumer-supplied close callback. Fires at most once, then nulled —
  /// the CR-03 "fire exactly once" guarantee. A second `_dismiss` (e.g.
  /// swipe racing the auto-dismiss timer) finds the callback already gone.
  VoidCallback? onClose;

  _ActiveToast({required this.entry, required this.isCard, this.onClose});
}

class _AnimatedToast extends StatefulWidget {
  final double offsetAbove;
  final String? title;
  final String message;
  final ToastType type;
  final Duration duration;
  final ValueChanged<AnimationController> onControllerReady;
  final VoidCallback onDismiss;
  final VoidCallback onDisposed;

  const _AnimatedToast({
    required this.offsetAbove,
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onControllerReady,
    required this.onDismiss,
    required this.onDisposed,
  });

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    widget.onControllerReady(_controller);
    _controller.forward();
    _autoDismiss = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    // CR-02: cancelling the auto-dismiss timer here means a manual close
    // can never be followed by a second timer fire (CR-03), and a torn-down
    // tree never leaves a pending timer.
    _autoDismiss?.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dimens = context.dimens;
    final isMobile = media.size.width < 600;

    // Derived, never guessed. The old `top: 100` was a literal with no
    // reference to the inset anywhere in this file, so it landed differently
    // on every device — on a 14 Pro the inset alone is 44-59pt before the
    // 60pt header.
    final top = isMobile
        ? media.padding.top +
              _kMobileHeaderHeight +
              dimens.space4 +
              widget.offsetAbove
        : dimens.space12 + widget.offsetAbove;

    // A phone toast drops from the top and is swiped back up; a desktop one
    // slides in horizontally at the top-right and is swiped back out the way
    // it came.
    final slideFrom = isMobile ? const Offset(0, -1) : const Offset(1, 0);
    final dismissDirection = isMobile
        ? DismissDirection.up
        : DismissDirection.startToEnd;

    final toast = ToastWidget(
      title: widget.title,
      message: widget.message,
      type: widget.type,
      onDismiss: widget.onDismiss,
    );

    // Respect the OS "reduce motion" switch: fade in place rather than
    // travel.
    final animated = media.disableAnimations
        ? FadeTransition(opacity: _controller, child: toast)
        : SlideTransition(
            position: Tween<Offset>(begin: slideFrom, end: Offset.zero).animate(
              CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
            ),
            child: toast,
          );

    return Positioned(
      top: top,
      left: isMobile ? dimens.space3 : null,
      right: isMobile ? dimens.space3 : dimens.space12,
      child: Align(
        alignment: isMobile ? Alignment.topCenter : Alignment.topRight,
        child: ConstrainedBox(
          // Not full screen off mobile — a 1400px-wide toast for
          // "Link copied" is what the desktop branch used to allow at
          // maxWidth 600.
          constraints: BoxConstraints(maxWidth: isMobile ? 560 : 420),
          child: Dismissible(
            key: ValueKey(widget.hashCode),
            direction: dismissDirection,
            onDismissed: (_) => widget.onDismiss(),
            child: animated,
          ),
        ),
      ),
    );
  }
}
