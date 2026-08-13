/// ScaffoldCardState -- Immutable state for the ScaffoldCard card.
///
/// Generated from card_state.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card_state.dart.jinja2
/// Generator version: 0.4.0
/// Plain Dart state class consumed by ScaffoldCardCubit.
/// All fields are persisted via hydrated_bloc -- this component has no
/// transient fields. The cubit's literal ``storagePrefix`` keeps the
/// hydration key stable across minified builds.
library;

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Immutable state for [ScaffoldCard].
///
/// Holds the selected card variant and the label of the most recent
/// action. New instances are produced exclusively via [copyWith]; the
/// cubit emits them to drive widget rebuilds.
class ScaffoldCardState {
  /// Creates a [ScaffoldCardState] with the given values.
  const ScaffoldCardState({
    this.cardVariant = 'elevated',
    this.lastAction,
  });

  /// The M3 card variant: ``'elevated'``, ``'outlined'``, or ``'filled'``.
  ///
  /// Defaults to ``'elevated'``.
  final String cardVariant;

  /// Label of the most recent action recorded on the card, or ``null``
  /// if no action has been recorded yet.
  final String? lastAction;

  /// Returns a copy of this state with the given fields replaced.
  ScaffoldCardState copyWith({
    String? cardVariant,
    String? lastAction,
  }) {
    return ScaffoldCardState(
      cardVariant: cardVariant ?? this.cardVariant,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  /// Serializes this state to a JSON map for hydrated_bloc persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'cardVariant': cardVariant,
        if (lastAction != null) 'lastAction': lastAction,
      };

  /// Deserializes a [ScaffoldCardState] from hydrated JSON.
  ///
  /// Uses defensive casts throughout -- hydrated JSON can be hand-edited
  /// on native targets, so every field falls back to its default when
  /// missing or of the wrong type.
  factory ScaffoldCardState.fromJson(Map<String, dynamic> json) {
    return ScaffoldCardState(
      cardVariant: json['cardVariant'] as String? ?? 'elevated',
      lastAction: json['lastAction'] as String?,
    );
  }
}
