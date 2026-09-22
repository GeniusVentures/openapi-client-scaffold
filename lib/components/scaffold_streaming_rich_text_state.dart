/// ScaffoldStreamingRichTextState -- Immutable state for the
/// ScaffoldStreamingRichText streaming-text atom.
///
/// Plain Dart state class consumed by ScaffoldStreamingRichTextCubit.
/// In-memory only -- no hydration or persistence.
library;

import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Immutable state for [ScaffoldStreamingRichText].
///
/// Holds the typed span tree appended so far, the streaming-active flag,
/// and the set of citation ids whose source slots are currently expanded.
/// New instances are produced exclusively via [copyWith]; the cubit emits
/// them to drive widget rebuilds.
class ScaffoldStreamingRichTextState {
  /// Creates a [ScaffoldStreamingRichTextState] with the given values.
  const ScaffoldStreamingRichTextState({
    this.spans = const <ScaffoldRichSpan>[],
    this.isStreaming = true,
    this.expandedCitations = const <String>{},
  });

  /// The typed span tree appended so far, in append order.
  final List<ScaffoldRichSpan> spans;

  /// When true, the streaming cursor renders at the tail of the span tree.
  /// Defaults to true; the cubit flips it to false on `complete()`.
  final bool isStreaming;

  /// Citation ids whose expanded source slots are currently visible.
  final Set<String> expandedCitations;

  /// Sentinel for [copyWith] marking an omitted optional field.
  static const Object _unset = Object();

  /// Returns a copy of this state with the given fields replaced.
  ///
  /// [expandedCitations] may be reset to ``null`` (interpreted as the
  /// empty set) by passing ``null`` explicitly.
  ScaffoldStreamingRichTextState copyWith({
    List<ScaffoldRichSpan>? spans,
    bool? isStreaming,
    Object? expandedCitations = _unset,
  }) {
    return ScaffoldStreamingRichTextState(
      spans: spans ?? this.spans,
      isStreaming: isStreaming ?? this.isStreaming,
      expandedCitations: expandedCitations == _unset
          ? this.expandedCitations
          : (expandedCitations as Set<String>?) ?? const <String>{},
    );
  }
}
