/// ScaffoldCardCubit -- Cubit for ScaffoldCard state management.
///
/// Generated from card_cubit.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card_cubit.dart.jinja2
/// Generator version: 0.4.0
/// In-memory Cubit (flutter_bloc). State does not persist across app
/// restarts -- persistence is a consumer concern, not a scaffold one.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'scaffold_card_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldCard].
///
/// Owns the card's variant selection and last-action record. Plain in-memory
/// [Cubit] -- no hydration, so no global storage bootstrap is required.
class ScaffoldCardCubit extends Cubit<ScaffoldCardState> {
  /// Creates a [ScaffoldCardCubit].
  ///
  /// [initialVariant] seeds the variant.
  ScaffoldCardCubit({
    this.instanceId = '',
    this.initialVariant = 'elevated',
  }) : super(ScaffoldCardState(cardVariant: initialVariant));

  /// Reserved discriminator (kept for API compatibility; unused without
  /// persistence).
  final String instanceId;

  /// The variant used when no state exists yet.
  final String initialVariant;

  /// Selects the card variant (``'elevated'``, ``'outlined'``, or
  /// ``'filled'``).
  void selectVariant(String variant) {
    emit(state.copyWith(cardVariant: variant));
  }

  /// Records the label of the most recent action performed on the card.
  void recordAction(String action) {
    emit(state.copyWith(lastAction: action));
  }

  /// Resets to the seeded default state.
  void reset() {
    emit(ScaffoldCardState(cardVariant: initialVariant));
  }
}
