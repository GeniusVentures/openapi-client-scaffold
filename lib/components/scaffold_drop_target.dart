import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_dashed_border.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

enum _DropState { idle, overAccepted, overRejected, dropped }

/// Drop zone with idle / accepted / rejected / dropped states.
///
/// Composes [ScaffoldSurface] + [ScaffoldStatusIndicator] inside a [DragTarget].
/// Idle renders a dashed `palette.borderSubtle` border; hovering an accepted
/// drag shows `palette.dropZoneHighlight` with a `palette.lightGreenPrimary`
/// border; a rejected drag shows `palette.dropZoneRejected` with a
/// `palette.statusError` border; a successful drop holds the accepted tint for
/// 500ms before returning to idle. Transitions use
/// [ScaffoldMotionDurations.medium] with [ScaffoldMotionCurves.standard].
class ScaffoldDropTarget extends StatefulWidget {
  const ScaffoldDropTarget({
    super.key,
    this.child,
    this.acceptCondition,
    this.onAccept,
    this.onReject,
    this.acceptType,
    this.showIdleBorder = true,
  });

  /// Content rendered inside the drop zone.
  final Widget? child;

  /// Screens drag data; when null, [acceptType] (then accept-all) applies.
  final bool Function(dynamic data)? acceptCondition;

  /// Called with the dropped data when a drag is accepted.
  final ValueChanged<dynamic>? onAccept;

  /// Called when a rejected drag is dropped on (or leaves) the zone.
  final VoidCallback? onReject;

  /// When non-null, accepts only data whose runtime type matches this [Type].
  final Type? acceptType;

  /// When false, the idle state renders no dashed border (used when an outer
  /// surface owns the border, e.g. [ScaffoldFileInputSurface]).
  final bool showIdleBorder;

  @override
  State<ScaffoldDropTarget> createState() => _ScaffoldDropTargetState();
}

class _ScaffoldDropTargetState extends State<ScaffoldDropTarget> {
  _DropState _state = _DropState.idle;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  bool _willAccept(Object data) {
    final bool Function(dynamic data)? acceptCondition = widget.acceptCondition;
    if (acceptCondition != null) {
      return acceptCondition(data);
    }
    final Type? acceptType = widget.acceptType;
    if (acceptType != null) {
      return data.runtimeType == acceptType;
    }
    return true;
  }

  void _setDropState(_DropState next) {
    if (_state != next) {
      setState(() => _state = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldPalette palette = context.palette;
    final ScaffoldDimens dimens = context.dimens;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (DragTargetDetails<Object> details) {
        final bool accepted = _willAccept(details.data);
        _setDropState(
          accepted ? _DropState.overAccepted : _DropState.overRejected,
        );
        return accepted;
      },
      onMove: (DragTargetDetails<Object> details) {
        _setDropState(
          _willAccept(details.data)
              ? _DropState.overAccepted
              : _DropState.overRejected,
        );
      },
      onLeave: (Object? data) {
        final bool wasRejected = _state == _DropState.overRejected;
        _setDropState(_DropState.idle);
        if (wasRejected) {
          widget.onReject?.call();
        }
      },
      onAcceptWithDetails: (DragTargetDetails<Object> details) {
        _resetTimer?.cancel();
        _setDropState(_DropState.dropped);
        widget.onAccept?.call(details.data);
        _resetTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _setDropState(_DropState.idle);
          }
        });
      },
      builder:
          (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) =>
              _build(palette, dimens),
    );
  }

  Widget _build(ScaffoldPalette palette, ScaffoldDimens dimens) {
    final Widget child = widget.child ?? const SizedBox.shrink();
    final BorderRadius radius = BorderRadius.circular(dimens.borderRadiusCard);

    Widget content;
    if (_state == _DropState.idle && !widget.showIdleBorder) {
      content = child;
    } else if (_state == _DropState.idle) {
      content = ScaffoldDashedBorder(
        color: palette.borderSubtle,
        borderRadius: radius,
        child: ScaffoldSurface(child: child),
      );
    } else {
      final StatusVariant status = _state == _DropState.overRejected
          ? StatusVariant.error
          : StatusVariant.info;
      final String label = _state == _DropState.overRejected
          ? 'Drop rejected'
          : 'Drop accepted';
      content = ScaffoldSurface(
        child: Stack(
          children: <Widget>[
            child,
            Positioned(
              top: dimens.space2,
              right: dimens.space2,
              child: ScaffoldStatusIndicator(status: status, label: label),
            ),
          ],
        ),
      );
    }

    final Color? tint = _tintForState(palette);
    if (tint != null) {
      content = Stack(
        children: <Widget>[
          content,
          Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: tint)),
          ),
        ],
      );
    }

    return Semantics(
      label: _semanticsLabel,
      child: AnimatedContainer(
        duration: ScaffoldMotionDurations.medium,
        curve: ScaffoldMotionCurves.standard,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: _borderForState(palette),
          borderRadius: radius,
        ),
        child: content,
      ),
    );
  }

  Color? _tintForState(ScaffoldPalette palette) {
    switch (_state) {
      case _DropState.idle:
        return null;
      case _DropState.overAccepted:
      case _DropState.dropped:
        return palette.dropZoneHighlight;
      case _DropState.overRejected:
        return palette.dropZoneRejected;
    }
  }

  BoxBorder? _borderForState(ScaffoldPalette palette) {
    switch (_state) {
      case _DropState.idle:
        return null;
      case _DropState.overAccepted:
      case _DropState.dropped:
        return Border.all(color: palette.lightGreenPrimary, width: 1);
      case _DropState.overRejected:
        return Border.all(color: palette.statusError, width: 1);
    }
  }

  String get _semanticsLabel {
    switch (_state) {
      case _DropState.idle:
        return 'Drop zone. Idle';
      case _DropState.overAccepted:
      case _DropState.dropped:
        return 'Drop zone. Drop accepted';
      case _DropState.overRejected:
        return 'Drop zone. Drop rejected';
    }
  }
}
