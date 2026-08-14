/// ScaffoldStateViewCubit -- Cubit for ScaffoldStateView state management.
///
/// Generated from state_cubit.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/state_cubit.dart.jinja2
/// Generator version: 0.4.0
/// In-memory Cubit (flutter_bloc). State does not persist across app
/// restarts -- persistence is a consumer concern, not a scaffold one.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'scaffold_state_view_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldStateView].
///
/// Owns the active state variant (``'loading'``, ``'empty'``, ``'error'``,
/// ``'unavailable'``, or ``'success'``), the retry counter, and the last
/// error message. Plain in-memory [Cubit] -- no hydration, so no global
/// storage bootstrap is required.
class ScaffoldStateViewCubit extends Cubit<ScaffoldStateViewState> {
  /// Creates a [ScaffoldStateViewCubit].
  ///
  /// The initial variant is [initialStateType] (seeded from the widget's
  /// ``state`` parameter); the widget renders whichever variant
  /// ``state.stateType`` holds at runtime, so [showLoading], [showEmpty],
  /// [showError], [showUnavailable], and [showSuccess] flip the UI live.
  ScaffoldStateViewCubit({
    this.instanceId = '',
    this.initialStateType = 'empty',
  }) : super(ScaffoldStateViewState(stateType: initialStateType));

  /// Reserved discriminator (kept for API compatibility; unused without
  /// persistence).
  final String instanceId;

  /// The variant used when no state exists yet.
  final String initialStateType;

  /// Switches to the loading variant.
  void showLoading() {
    emit(state.copyWith(stateType: 'loading'));
  }

  /// Switches to the empty variant.
  void showEmpty() {
    emit(state.copyWith(stateType: 'empty'));
  }

  /// Switches to the error variant with the given [message].
  void showError(String message) {
    emit(
      state.copyWith(
        stateType: 'error',
        lastError: message,
      ),
    );
  }

  /// Switches to the unavailable variant.
  void showUnavailable() {
    emit(state.copyWith(stateType: 'unavailable'));
  }

  /// Switches to the success variant.
  void showSuccess() {
    emit(state.copyWith(stateType: 'success'));
  }

  /// Increments the retry counter. Called by the widget when the user
  /// taps the error variant's retry button.
  void retry() {
    emit(state.copyWith(retryCount: state.retryCount + 1));
  }

  /// Resets to the seeded default state.
  void reset() {
    emit(ScaffoldStateViewState(stateType: initialStateType));
  }
}
