/// ScaffoldSearchBarCubit -- Cubit for ScaffoldSearchBar state management.
///
/// Generated from search_bar_cubit.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/search_bar_cubit.dart.jinja2
/// Generator version: 0.4.0
/// In-memory Cubit (flutter_bloc). State does not persist across app
/// restarts -- persistence is a consumer concern, not a scaffold one.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'scaffold_search_bar_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldSearchBar].
///
/// Owns the query text and the transient in-flight/error status of the
/// active search. Plain in-memory [Cubit] -- no hydration, so no global
/// storage bootstrap is required.
///
/// The cubit never performs async work and never takes a build context --
/// the widget owns the async search and calls [failSearch] when it
/// fails; the widget's BlocConsumer listener fires the toast on the
/// ``errorMessage`` transition.
class ScaffoldSearchBarCubit extends Cubit<ScaffoldSearchBarState> {
  /// Creates a [ScaffoldSearchBarCubit].
  ScaffoldSearchBarCubit({this.instanceId = ''})
      : super(const ScaffoldSearchBarState());

  /// Reserved discriminator (kept for API compatibility; unused without
  /// persistence).
  final String instanceId;

  /// Updates the current query text and marks the search as in flight.
  void updateQuery(String query) {
    emit(
      state.copyWith(
        query: query,
        isSearching: true,
      ),
    );
  }

  /// Clears the query and any active error.
  void clearQuery() {
    emit(const ScaffoldSearchBarState());
  }

  /// Records that the user selected the result with the given [id],
  /// ending the in-flight search.
  void selectResult(String id) {
    emit(state.copyWith(isSearching: false));
  }

  /// Records a failed search with the given [message]. This is the ONLY
  /// transition that sets ``errorMessage`` non-null -- the widget's
  /// BlocConsumer listener fires the search-failed toast here.
  void failSearch(String message) {
    emit(
      state.copyWith(
        isSearching: false,
        errorMessage: message,
      ),
    );
  }

  /// Resets to the default state.
  void reset() {
    emit(const ScaffoldSearchBarState());
  }
}
