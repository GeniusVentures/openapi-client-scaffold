/// ScaffoldStreamingRichTextCubit -- Cubit for ScaffoldStreamingRichText
/// state management.
///
/// In-memory Cubit (flutter_bloc). State does not persist across app
/// restarts -- persistence is a consumer concern, not a scaffold one.
/// Consumes typed spans from lib/utils/scaffold_rich_spans.dart; streaming
/// input contract D-02 (optional consumer-supplied cubit).
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

import 'scaffold_streaming_rich_text_state.dart';

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit for [ScaffoldStreamingRichText].
///
/// Owns the appended span tree, the streaming-active flag, and the set of
/// expanded citations. Plain in-memory [Cubit] -- no hydration, so no
/// global storage bootstrap is required.
class ScaffoldStreamingRichTextCubit
    extends Cubit<ScaffoldStreamingRichTextState> {
  /// Creates a [ScaffoldStreamingRichTextCubit].
  ScaffoldStreamingRichTextCubit({
    this.instanceId = '',
  }) : super(const ScaffoldStreamingRichTextState());

  /// Reserved discriminator (kept for API compatibility; unused by the
  /// in-memory cubit).
  final String instanceId;

  /// Appends [delta] spans to the end of the current span tree.
  void appendSpans(List<ScaffoldRichSpan> delta) {
    emit(
      state.copyWith(
        spans: <ScaffoldRichSpan>[...state.spans, ...delta],
      ),
    );
  }

  /// Marks the stream complete; the streaming cursor hides on next rebuild.
  void complete() {
    emit(state.copyWith(isStreaming: false));
  }

  /// Toggles [id] in [ScaffoldStreamingRichTextState.expandedCitations]:
  /// adds it when absent, removes it when present.
  void toggleCitation(String id) {
    final Set<String> next = <String>{...state.expandedCitations};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    emit(state.copyWith(expandedCitations: next));
  }

  /// Resets to the initial empty streaming state.
  void reset() {
    emit(const ScaffoldStreamingRichTextState());
  }
}
