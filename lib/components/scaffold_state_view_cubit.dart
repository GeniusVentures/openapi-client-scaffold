/// ScaffoldStateViewCubit -- Cubit for ScaffoldStateView state management.
///
/// Generated from state_cubit.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/state_cubit.dart.jinja2
/// Generator version: 0.4.0
/// Persists state across reloads via hydrated_bloc; uses a stable
/// literal [storagePrefix] so minified builds retain hydrated state.
/// Requires HydratedBloc.storage initialized in the consuming app's
/// main(); see frontend/generated/widgets/README.md for the bootstrap
/// snippet.
library;

import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'scaffold_state_view_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldStateView].
///
/// Owns the active state variant (``'loading'``, ``'empty'``, ``'error'``,
/// ``'unavailable'``, or ``'success'``), the retry counter, and the last
/// error message. State is restored from hydrated storage on construction;
/// [hydrate] is the LAST constructor statement so the initial emit always
/// reflects the restored value.
class ScaffoldStateViewCubit extends Cubit<ScaffoldStateViewState>
    with HydratedMixin {
  /// Creates a [ScaffoldStateViewCubit].
  ///
  /// [instanceId] discriminates multi-instance persistence -- pass a
  /// unique value when two state widgets share a screen.
  ///
  /// The initial variant is [initialStateType] (seeded from the widget's
  /// ``state`` parameter); the widget renders whichever variant
  /// ``state.stateType`` holds at runtime, so [showLoading], [showEmpty],
  /// [showError], [showUnavailable], and [showSuccess] flip the UI live.
  ScaffoldStateViewCubit({
    this.instanceId = '',
    this.initialStateType = 'empty',
  }) : super(ScaffoldStateViewState(stateType: initialStateType)) {
    hydrate(
      onError: (error, stackTrace) => HydrationErrorBehavior.retain,
    );
  }

  /// Optional discriminator for multi-instance persistence. Empty by default.
  final String instanceId;

  /// The variant used when no hydrated value exists.
  final String initialStateType;

  @override
  String get id => instanceId;

  @override
  String get storagePrefix => 'ScaffoldStateViewCubit';

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

  /// Wipes hydrated storage and emits the seeded default state.
  Future<void> reset() async {
    await clear();
    emit(ScaffoldStateViewState(stateType: initialStateType));
  }

  @override
  ScaffoldStateViewState? fromJson(Map<String, dynamic> json) =>
      ScaffoldStateViewState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ScaffoldStateViewState state) =>
      state.toJson();
}
