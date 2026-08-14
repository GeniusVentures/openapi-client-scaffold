/// ScaffoldStateView -- M3 state widget for loading, empty, error, unavailable, and success states.
///
/// Generated from state.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/state.dart.jinja2
/// Generator version: 0.4.0
/// Renders the state variant held by the cubit's ``state.stateType`` at
/// runtime (loading skeleton, or a status panel for empty / error /
/// unavailable / success). The constructor ``state`` (``'empty'``)
/// seeds the cubit's initial variant only.
/// Composes ScaffoldSkeleton (loading) + ScaffoldStatusIndicator +
/// ScaffoldPressable (empty / error / unavailable / success).
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
/// Consumes ScaffoldStateViewCubit (hydrated_bloc).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_skeleton.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/toast/toast_manager.dart' show ToastType, showToast;
import 'package:frontend_scaffold/theme/scaffold_theme.dart';


import 'scaffold_state_view_cubit.dart';
import 'scaffold_state_view_state.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// A Material 3 state widget whose variant is runtime-driven.
///
/// The rendered state variant (loading, empty, error, unavailable, success)
/// is read from the cubit's ``state.stateType`` on every build; the
/// constructor ``state`` (``'empty'``) is only the cubit's initial
/// value. Calling ``cubit.showLoading()`` / ``showEmpty()`` /
/// ``showError(message)`` flips the rendered variant live, and
/// ``cubit.retry()`` increments the retry counter shown on the error
/// variant's retry button.
///
/// A parent can supply its own [cubit] to drive the view live (and read it
/// via ``context.read<ScaffoldStateViewCubit>()``); when [cubit] is
/// null the widget owns an internal cubit seeded from [state] and re-seeds it
/// when [state] or [instanceId] change.
class ScaffoldStateView extends StatefulWidget {
  /// Creates a [ScaffoldStateView].
  const ScaffoldStateView({
    this.instanceId = '',
    this.state = 'empty',
    this.loadingWidget,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyHeadline = 'Nothing here',
    this.emptyBody = 'No items to display.',
    this.emptyAction,
    this.errorIcon = Icons.error_outline,
    this.errorHeadline = 'Something went wrong',
    this.errorBody = 'Please try again.',
    this.onRetry,
    this.unavailableIcon = Icons.cloud_off,
    this.unavailableHeadline = 'Service unavailable',
    this.unavailableBody = 'Please try again later.',
    this.successIcon = Icons.check_circle,
    this.successHeadline = 'Done!',
    this.successBody,
    this.successAction,
    this.cubit,
    super.key,
  });

  /// Multi-instance hydration discriminator forwarded to the Cubit.
  ///
  /// Hydrated cubits sharing a [storagePrefix] disambiguate by this id;
  /// leave empty for a single (default) instance.
  final String instanceId;

  /// Initial state variant: 'loading', 'empty', 'error', 'unavailable', or
  /// 'success'. Seeds the cubit's hydrated state.
  final String state;

  /// Optional custom widget for the loading variant; defaults to a
  /// [ScaffoldSkeleton].
  final Widget? loadingWidget;

  /// Icon for the empty variant.
  final IconData emptyIcon;

  /// Headline for the empty variant.
  final String emptyHeadline;

  /// Body for the empty variant.
  final String emptyBody;

  /// Optional action rendered at the bottom of the empty variant.
  final Widget? emptyAction;

  /// Icon for the error variant.
  final IconData errorIcon;

  /// Headline for the error variant.
  final String errorHeadline;

  /// Body for the error variant, used when no runtime error message is set.
  final String errorBody;

  /// Callback for the error/unavailable retry button.
  final VoidCallback? onRetry;

  /// Icon for the unavailable variant.
  final IconData unavailableIcon;

  /// Headline for the unavailable variant.
  final String unavailableHeadline;

  /// Body for the unavailable variant.
  final String unavailableBody;

  /// Icon for the success variant.
  final IconData successIcon;

  /// Headline for the success variant.
  final String successHeadline;

  /// Optional body for the success variant.
  final String? successBody;

  /// Optional action rendered at the bottom of the success variant.
  final Widget? successAction;

  /// Optional cubit owned by the parent. When supplied, the parent drives the
  /// rendered variant; when null, the widget owns an internal cubit seeded
  /// from [state].
  final ScaffoldStateViewCubit? cubit;

  @override
  State<ScaffoldStateView> createState() => _ScaffoldStateViewState();
}

class _ScaffoldStateViewState extends State<ScaffoldStateView> {
  late ScaffoldStateViewCubit _cubit;
  late bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit = widget.cubit ??
        ScaffoldStateViewCubit(
          instanceId: widget.instanceId,
          initialStateType: widget.state,
        );
  }

  @override
  void didUpdateWidget(ScaffoldStateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool seedChanged = widget.instanceId != oldWidget.instanceId ||
        widget.state != oldWidget.state;
    if (widget.cubit != oldWidget.cubit || (_ownsCubit && seedChanged)) {
      if (_ownsCubit) {
        _cubit.close();
      }
      _ownsCubit = widget.cubit == null;
      _cubit = widget.cubit ??
          ScaffoldStateViewCubit(
            instanceId: widget.instanceId,
            initialStateType: widget.state,
          );
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScaffoldStateViewCubit>.value(
      value: _cubit,
      child: BlocConsumer<ScaffoldStateViewCubit, ScaffoldStateViewState>(
        listenWhen: (prev, curr) =>
            prev.lastError != curr.lastError && curr.lastError != null,
        listener: (context, state) {
          showToast(
            context,
            state.lastError!,
            title: 'Load failed',
            type: ToastType.error,
          );
        },
        builder: (context, state) {
          final palette = context.palette;
          final ScaffoldStateViewCubit cubit =
              context.read<ScaffoldStateViewCubit>();

          switch (state.stateType) {
            case 'loading':
              // ============================================================
              // Loading: ScaffoldSkeleton
              // ============================================================
              return Center(
                child: widget.loadingWidget ??
                    const ScaffoldSkeleton(width: 240.0, height: 128.0),
              );

            case 'error':
              // ============================================================
              // Error: status indicator + icon + headline + body + retry
              // ============================================================
              return _statePanel(
                context,
                status: StatusVariant.error,
                icon: widget.errorIcon,
                iconColor: palette.statusError,
                headline: widget.errorHeadline,
                body: state.lastError ?? widget.errorBody,
                action: ScaffoldPressable(
                  onPressed: () {
                    cubit.retry();
                    widget.onRetry?.call();
                  },
                  child: const Text('Retry'),
                ),
              );

            case 'unavailable':
              // ============================================================
              // Unavailable: status indicator + icon + headline + body
              // ============================================================
              return _statePanel(
                context,
                status: StatusVariant.neutral,
                icon: widget.unavailableIcon,
                iconColor: palette.textSecondary,
                headline: widget.unavailableHeadline,
                body: widget.unavailableBody,
                action: widget.onRetry != null
                    ? ScaffoldPressable(
                        onPressed: () {
                          cubit.retry();
                          widget.onRetry?.call();
                        },
                        child: const Text('Retry'),
                      )
                    : null,
              );

            case 'success':
              // ============================================================
              // Success: status indicator + icon + headline + optional action
              // ============================================================
              return _statePanel(
                context,
                status: StatusVariant.success,
                icon: widget.successIcon,
                iconColor: palette.statusSuccess,
                headline: widget.successHeadline,
                body: widget.successBody,
                action: widget.successAction,
              );

            case 'empty':
            default:
              // ============================================================
              // Empty: status indicator + icon + headline + body + CTA
              // ============================================================
              return _statePanel(
                context,
                status: StatusVariant.neutral,
                icon: widget.emptyIcon,
                iconColor: palette.textSecondary,
                headline: widget.emptyHeadline,
                body: widget.emptyBody,
                action: widget.emptyAction,
              );
          }
        },
      ),
    );
  }

  /// Renders the shared status-panel layout for the non-loading variants.
  Widget _statePanel(
    BuildContext context, {
    required StatusVariant status,
    required IconData icon,
    required Color iconColor,
    required String headline,
    required String? body,
    Widget? action,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ScaffoldStatusIndicator(status: status, label: headline),
            const SizedBox(height: 16.0),
            Icon(icon, size: 64.0, color: iconColor),
            const SizedBox(height: 16.0),
            Text(
              headline,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (body != null && body.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8.0),
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 24.0),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
