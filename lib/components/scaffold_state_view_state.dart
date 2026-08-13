
/// ScaffoldStateViewState -- Immutable state for the ScaffoldStateView state widget.
///
/// Generated from state_view_state.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/state_view_state.dart.jinja2
/// Generator version: 0.4.0
/// Plain Dart state class consumed by ScaffoldStateViewCubit.
/// All fields are persisted via hydrated_bloc -- this component has no
/// transient fields, so the active variant, retry count, and last error
/// all survive reload. The cubit's literal ``storagePrefix`` keeps the
/// hydration key stable across minified builds.
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

  /// Returns a copy of this state with the given fields replaced.
  ScaffoldStateViewState copyWith({
    String? stateType,
    int? retryCount,
    String? lastError,
  }) {
    return ScaffoldStateViewState(
      stateType: stateType ?? this.stateType,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Serializes this state to a JSON map for hydrated_bloc persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'stateType': stateType,
        'retryCount': retryCount,
        if (lastError != null) 'lastError': lastError,
      };

  /// Deserializes a [ScaffoldStateViewState] from hydrated JSON.
  ///
  /// Uses defensive casts throughout -- hydrated JSON can be hand-edited
  /// on native targets, so every field falls back to its default when
  /// missing or of the wrong type.
  factory ScaffoldStateViewState.fromJson(Map<String, dynamic> json) {
    return ScaffoldStateViewState(
      stateType: json['stateType'] as String? ?? 'empty',
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}
