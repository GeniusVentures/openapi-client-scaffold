/// ScaffoldSearchBarState -- Immutable state for the ScaffoldSearchBar search bar.
///
/// Generated from search_bar_state.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/search_bar_state.dart.jinja2
/// Generator version: 0.4.0
/// Plain Dart state class consumed by ScaffoldSearchBarCubit.
/// ``query`` is persisted via hydrated_bloc. ``isSearching`` and
/// ``errorMessage`` are TRANSIENT: they exist on the class (the widget's
/// BlocConsumer listener reads ``errorMessage`` to fire the
/// search-failed toast) but are excluded from ``toJson``/``fromJson``.
/// The cubit's literal ``storagePrefix`` keeps the hydration key stable
/// across minified builds.
library;

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Immutable state for [ScaffoldSearchBar].
///
/// Holds the current query text and the transient in-flight/error
/// status of the active search. New instances are produced exclusively
/// via [copyWith]; the cubit emits them to drive widget rebuilds.
class ScaffoldSearchBarState {
  /// Creates a [ScaffoldSearchBarState] with the given values.
  const ScaffoldSearchBarState({
    this.query = '',
    this.isSearching = false,
    this.errorMessage,
  });

  /// The current query text.
  ///
  /// Defaults to the empty string.
  final String query;

  /// Whether a search is currently in flight.
  ///
  /// TRANSIENT -- never persisted.
  final bool isSearching;

  /// Message describing the most recent search failure, or ``null``
  /// when there is no active error. The widget's BlocConsumer listener
  /// fires the search-failed toast on the transition to a non-null
  /// value.
  ///
  /// TRANSIENT -- never persisted.
  final String? errorMessage;

  /// Returns a copy of this state with the given fields replaced.
  ScaffoldSearchBarState copyWith({
    String? query,
    bool? isSearching,
    String? errorMessage,
  }) {
    return ScaffoldSearchBarState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Serializes this state to a JSON map for hydrated_bloc persistence.
  ///
  /// Transient fields (``isSearching``, ``errorMessage``) are excluded.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'query': query,
      };

  /// Deserializes a [ScaffoldSearchBarState] from hydrated JSON.
  ///
  /// Uses defensive casts throughout -- hydrated JSON can be hand-edited
  /// on native targets, so every field falls back to its default when
  /// missing or of the wrong type. Transient fields always deserialize
  /// to their defaults.
  factory ScaffoldSearchBarState.fromJson(Map<String, dynamic> json) {
    return ScaffoldSearchBarState(
      query: json['query'] as String? ?? '',
    );
  }
}
