import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/toast/ticker_provider.dart';
import 'package:frontend_scaffold/components/toast/toast_widget.dart';

class ToastManager {
  static final ToastManager _instance = ToastManager._internal();

  factory ToastManager() => _instance;

  ToastManager._internal();

  final List<_ToastEntry> _activeToasts = []; // Track all active toasts
  final Map<OverlayEntry, double> _toastPositions = {}; // Track fixed positions

  void showToast({
    required BuildContext context,
    required String title,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onClose,
  }) {
    final overlay = Overlay.of(context);

    // Create a TickerProvider
    final tickerProvider = ToastTickerProvider();

    // Create an AnimationController
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: tickerProvider,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    late OverlayEntry overlayEntry;
    late _ToastEntry toastEntry;

    // Determine the position for the new toast
    final topOffset = 100 + (_activeToasts.length * 85.0);

    overlayEntry = OverlayEntry(
      builder: (context) {
        // Short-circuit if the entry has been disposed (e.g. route popped
        // before the first frame after insert).
        if (toastEntry.isDisposed) {
          return const SizedBox.shrink();
        }

        final isMobile = MediaQuery.of(context).size.width < 600;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final fixedTopOffset = _toastPositions[overlayEntry] ?? topOffset;

            return Positioned(
              top: fixedTopOffset,
              left: isMobile ? 0 : null,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Align(
                  alignment: isMobile ? Alignment.center : Alignment.topRight,
                  child: SizedBox(
                    width: isMobile ? double.infinity : 600,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: ToastWidget(
                        title: title,
                        message: message,
                        type: type,
                        onDismiss: () {
                          _removeToast(toastEntry);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Create the entry record BEFORE inserting into the overlay so the
    // builder closure can safely read `toastEntry.isDisposed` even if a
    // synchronous route pop races the first frame.
    toastEntry = _ToastEntry(
      overlayEntry: overlayEntry,
      animationController: animationController,
      tickerProvider: tickerProvider,
      onClose: onClose,
    );

    // Insert the overlay entry
    overlay.insert(overlayEntry);
    animationController.forward();

    // Track the toast and its position
    _activeToasts.add(toastEntry);
    _toastPositions[overlayEntry] = topOffset;

    // Auto-remove the toast after the specified duration. Stored on the
    // entry so it can be cancelled when the toast is dismissed manually
    // or when the manager is disposed.
    toastEntry.autoDismissTimer = Timer(duration, () {
      _removeToast(toastEntry);
    });
  }

  /// Remove a toast. Idempotent — safe to call multiple times for the
  /// same entry (auto-timer + manual dismiss + dispose() all funnel here).
  /// The entry's `onClose` callback fires at most once.
  void _removeToast(_ToastEntry entry) {
    if (entry.isRemoved) {
      return;
    }
    entry.isRemoved = true;

    final toastIndex = _activeToasts.indexWhere(
      (e) => identical(e, entry),
    );

    if (toastIndex == -1) {
      return;
    }

    _activeToasts.removeAt(toastIndex);
    _toastPositions.remove(entry.overlayEntry);

    // Cancel any pending auto-dismiss timer so it doesn't fire later
    // against a disposed controller.
    entry.autoDismissTimer?.cancel();
    entry.autoDismissTimer = null;

    final controller = entry.animationController;
    final overlayEntry = entry.overlayEntry;
    final tickerProvider = entry.tickerProvider;

    // Only reverse if the controller is actively animating forward or has
    // completed. If it never started (e.g. dispose raced the first frame),
    // skip straight to synchronous teardown to avoid "used after dispose"
    // errors and to ensure the OverlayEntry is removed deterministically.
    if (controller.isAnimating || controller.isCompleted) {
      controller.reverse().then((_) {
        _teardownEntry(entry, overlayEntry, tickerProvider, controller);
      });
    } else {
      _teardownEntry(entry, overlayEntry, tickerProvider, controller);
    }

    // Fire onClose exactly once, from whichever path removed the toast.
    entry.onClose?.call();
    entry.onClose = null;
  }

  void _teardownEntry(
    _ToastEntry entry,
    OverlayEntry overlayEntry,
    ToastTickerProvider tickerProvider,
    AnimationController controller,
  ) {
    // Mark disposed BEFORE removing the overlay entry so any pending
    // rebuild short-circuits via the SizedBox.shrink() guard above.
    entry.isDisposed = true;
    overlayEntry.remove();
    tickerProvider.dispose();
    controller.dispose();
  }

  /// Clear all active toasts synchronously. Cancels every pending
  /// auto-dismiss timer first, then removes each OverlayEntry and disposes
  /// each controller without attempting an animated reverse (which would
  /// race the ticker disposal and could leak entries).
  void dispose() {
    // Cancel timers first so no timer fires while we tear down entries.
    for (final entry in _activeToasts) {
      entry.autoDismissTimer?.cancel();
      entry.autoDismissTimer = null;
      entry.isRemoved = true;
    }

    // Synchronously teardown every entry — no async reverse().then(...)
    // chains that could leak OverlayEntries if interrupted.
    final entriesToDispose = List<_ToastEntry>.from(_activeToasts);
    _activeToasts.clear();
    _toastPositions.clear();

    for (final entry in entriesToDispose) {
      _teardownEntry(
        entry,
        entry.overlayEntry,
        entry.tickerProvider,
        entry.animationController,
      );
      // Fire onClose so consumers are notified the toast went away.
      entry.onClose?.call();
      entry.onClose = null;
    }
  }
}

class _ToastEntry {
  final OverlayEntry overlayEntry;
  final AnimationController animationController;
  final ToastTickerProvider tickerProvider;

  /// Auto-dismiss timer; set immediately after construction by
  /// [ToastManager.showToast]. Cancelled by [_removeToast] and [dispose].
  Timer? autoDismissTimer;

  /// Idempotency guard — true once this entry has been removed.
  bool isRemoved = false;

  /// Set just before the OverlayEntry is removed so any in-flight builder
  /// invocation short-circuits instead of touching a disposed animation.
  bool isDisposed = false;

  /// Consumer-supplied close callback. Fires at most once, then nulled.
  VoidCallback? onClose;

  _ToastEntry({
    required this.overlayEntry,
    required this.animationController,
    required this.tickerProvider,
    required this.onClose,
  });
}

enum ToastType { success, error, warning }
