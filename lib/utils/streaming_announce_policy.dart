/// Announce-policy hook for ScaffoldStreamingRichText (D-06).
///
/// Default = block-boundary, debounced 300ms; never per-token. The widget
/// calls [ScaffoldStreamingAnnouncePolicy.shouldAnnounce] on every span-tree
/// update; the policy returns the plain-text to pass to
/// [ScaffoldLiveRegion], or null to skip the update.
library;

import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

// ---------------------------------------------------------------------------
// Policy abstraction
// ---------------------------------------------------------------------------

/// Announce-policy hook for [ScaffoldStreamingRichText] (D-06).
///
/// The atom calls [shouldAnnounce] on every span-tree update; the policy
/// returns the plain-text to pass to [ScaffoldLiveRegion] (or null to skip
/// this update). Policies MUST NOT reread the whole answer per token — the
/// default implementation announces at block boundaries (paragraph, code
/// block, heading) and debounces 300ms.
///
/// Policies are pure/stateless. Cadence (debounce window) is enforced by
/// the widget, which reads the policy's debounce via
/// [ScaffoldBlockBoundaryAnnouncePolicy.debounce] when the policy is the
/// default implementation, and applies no debounce to custom policies.
abstract class ScaffoldStreamingAnnouncePolicy {
  /// Creates a [ScaffoldStreamingAnnouncePolicy].
  const ScaffoldStreamingAnnouncePolicy();

  /// Returns the plain-text block to announce, or null when this update
  /// does not cross an announcement boundary.
  String? shouldAnnounce(
    List<ScaffoldRichSpan> previous,
    List<ScaffoldRichSpan> next,
  );
}

// ---------------------------------------------------------------------------
// Default block-boundary policy
// ---------------------------------------------------------------------------

/// Default block-boundary announce policy (D-06 default).
///
/// Announces the plain-text of the newest block-level span when a block
/// boundary is crossed: a new span appears at the tail of [next] whose
/// plain-text ends with a newline, OR whose runtime type differs from the
/// previous tail's runtime type. Otherwise returns null.
///
/// The policy itself is stateless — debounce cadence is enforced by the
/// consuming widget using [debounce] as the window.
final class ScaffoldBlockBoundaryAnnouncePolicy
    extends ScaffoldStreamingAnnouncePolicy {
  /// Creates a [ScaffoldBlockBoundaryAnnouncePolicy] with the given
  /// [debounce] window (default 300ms).
  const ScaffoldBlockBoundaryAnnouncePolicy({
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Minimum interval between announcements. The widget enforces this
  /// window; the policy does not own a timer.
  final Duration debounce;

  @override
  String? shouldAnnounce(
    List<ScaffoldRichSpan> previous,
    List<ScaffoldRichSpan> next,
  ) {
    if (next.length <= previous.length) {
      return null;
    }
    final ScaffoldRichSpan tail = next.last;
    final String tailText = _plainTextOf(tail);
    final bool endsBlock = tailText.endsWith('\n') ||
        (previous.isNotEmpty &&
            tail.runtimeType != previous.last.runtimeType);
    if (!endsBlock) {
      return null;
    }
    // Announce the newly-completed block's full plain text, not just the tail
    // span. markdown_to_spans emits the '\n\n' boundary as a SEPARATE trailing
    // span after the paragraph content, so returning only the tail would
    // surface whitespace instead of the actual paragraph (D-06 a11y).
    final StringBuffer buffer = StringBuffer();
    for (int i = previous.length; i < next.length; i++) {
      buffer.write(_plainTextOf(next[i]));
    }
    return buffer.toString();
  }
}

// ---------------------------------------------------------------------------
// Plain-text extraction
// ---------------------------------------------------------------------------

String _plainTextOf(ScaffoldRichSpan span) {
  return switch (span) {
    ScaffoldTextSpan(:final String text) => text,
    ScaffoldCodeInlineSpan(:final String code) => code,
    ScaffoldLinkSpan(:final String text) => text,
    ScaffoldCitationSpan(:final String marker) => marker,
  };
}
