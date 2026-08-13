/// ScaffoldCardCubit -- Cubit for ScaffoldCard state management.
///
/// Generated from card_cubit.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card_cubit.dart.jinja2
/// Generator version: 0.4.0
/// Persists state across reloads via hydrated_bloc; uses a stable
/// literal [storagePrefix] so minified builds retain hydrated state.
/// Requires HydratedBloc.storage initialized in the consuming app's
/// main(); see frontend/generated/widgets/README.md for the bootstrap
/// snippet.
library;

import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'scaffold_card_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldCard].
///
/// Owns the card's variant selection and last-action record. State is
/// restored from hydrated storage on construction; [hydrate] is the
/// LAST constructor statement so the initial emit always reflects the
/// restored value.
class ScaffoldCardCubit extends Cubit<ScaffoldCardState>
    with HydratedMixin {
  /// Creates a [ScaffoldCardCubit].
  ///
  /// [instanceId] discriminates multi-instance persistence -- pass a
  /// unique value when two instances of this cubit share a screen.
  /// [initialVariant] seeds the variant used when no hydrated state exists.
  ScaffoldCardCubit({
    this.instanceId = '',
    this.initialVariant = 'elevated',
  }) : super(ScaffoldCardState(cardVariant: initialVariant)) {
    hydrate(
      onError: (error, stackTrace) => HydrationErrorBehavior.retain,
    );
  }

  /// Optional discriminator for multi-instance persistence. Empty by default.
  final String instanceId;

  /// The variant used when no hydrated value exists.
  final String initialVariant;

  @override
  String get id => instanceId;

  @override
  String get storagePrefix => 'ScaffoldCardCubit';

  /// Selects the card variant (``'elevated'``, ``'outlined'``, or
  /// ``'filled'``).
  void selectVariant(String variant) {
    emit(state.copyWith(cardVariant: variant));
  }

  /// Records the label of the most recent action performed on the card.
  void recordAction(String action) {
    emit(state.copyWith(lastAction: action));
  }

  /// Wipes hydrated storage and emits the seeded default state.
  Future<void> reset() async {
    await clear();
    emit(ScaffoldCardState(cardVariant: initialVariant));
  }

  @override
  ScaffoldCardState? fromJson(Map<String, dynamic> json) =>
      ScaffoldCardState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ScaffoldCardState state) =>
      state.toJson();
}
