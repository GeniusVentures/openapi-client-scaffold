/// ScaffoldSearchBarCubit -- Cubit for ScaffoldSearchBar state management.
///
/// Generated from search_bar_cubit.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/search_bar_cubit.dart.jinja2
/// Generator version: 0.4.0
/// Persists state across reloads via hydrated_bloc; uses a stable
/// literal [storagePrefix] so minified builds retain hydrated state.
/// Requires HydratedBloc.storage initialized in the consuming app's
/// main(); see frontend/generated/widgets/README.md for the bootstrap
/// snippet.
library;

import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'scaffold_search_bar_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldSearchBar].
///
/// Owns the query text and the transient in-flight/error status of the
/// active search. The query is restored from hydrated storage on
/// construction; [hydrate] is the LAST constructor statement so the
/// initial emit always reflects the restored value.
///
/// The cubit never performs async work and never takes a build context --
/// the widget owns the async search and calls [failSearch] when it
/// fails; the widget's BlocConsumer listener fires the toast on the
/// ``errorMessage`` transition.
class ScaffoldSearchBarCubit extends Cubit<ScaffoldSearchBarState>
    with HydratedMixin {
  /// Creates a [ScaffoldSearchBarCubit].
  ///
  /// [instanceId] discriminates multi-instance persistence -- pass a
  /// unique value when two search bars share a screen.
  ScaffoldSearchBarCubit({this.instanceId = ''})
      : super(const ScaffoldSearchBarState()) {
    try {
      hydrate(
        onError: (error, stackTrace) => HydrationErrorBehavior.retain,
      );
    } on StorageNotFound {
      // HydratedBloc.storage not initialized (no bootstrap in main()) —
      // run in-memory only; the widget still works, it just won't persist.
    }
  }

  /// Optional discriminator for multi-instance persistence. Empty by default.
  final String instanceId;

  @override
  String get id => instanceId;

  @override
  String get storagePrefix => 'ScaffoldSearchBarCubit';

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
  ///
  /// Named `clearQuery` (not `clear`) so it does not collide with
  /// [HydratedMixin.clear], which returns `Future<void>` and wipes
  /// hydrated storage.
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

  /// Wipes hydrated storage and emits the default state (logout/reset flow).
  Future<void> reset() async {
    await clear();
    emit(const ScaffoldSearchBarState());
  }

  @override
  ScaffoldSearchBarState? fromJson(Map<String, dynamic> json) =>
      ScaffoldSearchBarState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ScaffoldSearchBarState state) =>
      state.toJson();
}
