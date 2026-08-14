/// ScaffoldSearchBarState -- Immutable state for the ScaffoldSearchBar search bar.
///
/// Generated from search_bar_state.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/search_bar_state.dart.jinja2
/// Generator version: 0.4.0
/// Plain Dart state class consumed by ScaffoldSearchBarCubit.
/// In-memory only -- no hydration or persistence. The widget's BlocConsumer
/// listener reads ``errorMessage`` to fire the search-failed toast.
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

  /// Sentinel for [copyWith] marking an omitted optional field.
  static const Object _unset = Object();

  /// Returns a copy of this state with the given fields replaced.
  ///
  /// [errorMessage] may be reset to ``null`` by passing ``null`` explicitly.
  ScaffoldSearchBarState copyWith({
    String? query,
    bool? isSearching,
    Object? errorMessage = _unset,
  }) {
    return ScaffoldSearchBarState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
