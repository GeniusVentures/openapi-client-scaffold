
/// ScaffoldStateViewState -- Immutable state for the ScaffoldStateView state widget.
///
/// Generated from state_view_state.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/state_view_state.dart.jinja2
/// Generator version: 0.4.0
/// Plain Dart state class consumed by ScaffoldStateViewCubit.
/// In-memory only -- no hydration or persistence.
library;

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Immutable state for [ScaffoldStateView].
///
/// Holds the active state variant (``'loading'``, ``'empty'``,
/// ``'error'``, ``'unavailable'``, or ``'success'``), the retry counter, and
/// the last error message. New
/// instances are produced exclusively via [copyWith]; the cubit emits
/// them to drive widget rebuilds.
class ScaffoldStateViewState {
  /// Creates a [ScaffoldStateViewState] with the given values.
  const ScaffoldStateViewState({
    this.stateType = 'empty',
    this.retryCount = 0,
    this.lastError,
  });

  /// The active state variant: ``'loading'``, ``'empty'``, ``'error'``,
  /// ``'unavailable'``, or ``'success'``.
  ///
  /// Defaults to ``'empty'``.
  final String stateType;

  /// Number of times the user has retried from the error variant.
  ///
  /// Defaults to ``0``.
  final int retryCount;

  /// Message of the most recent error shown by the error variant, or
  /// ``null`` when no error has been shown.
  final String? lastError;

  /// Sentinel for [copyWith] marking an omitted optional field.
  static const Object _unset = Object();

  /// Returns a copy of this state with the given fields replaced.
  ///
  /// [lastError] may be reset to ``null`` by passing ``null`` explicitly.
  ScaffoldStateViewState copyWith({
    String? stateType,
    int? retryCount,
    Object? lastError = _unset,
  }) {
    return ScaffoldStateViewState(
      stateType: stateType ?? this.stateType,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError == _unset ? this.lastError : lastError as String?,
    );
  }
}
