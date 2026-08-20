/// ScaffoldRichSpan -- typed span tree consumed by ScaffoldStreamingRichText.
///
/// D-03 typed span model for ScaffoldStreamingRichText; the atom never parses
/// Markdown (see utils/markdown_to_spans.dart). Pure data shapes only — no
/// behavior, no rendering logic.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Sealed span hierarchy
// ---------------------------------------------------------------------------

/// Base class for every span the [ScaffoldStreamingRichText] atom knows how
/// to render. Sealed so the atom's span-dispatch switch is exhaustive.
sealed class ScaffoldRichSpan {
  /// Creates a [ScaffoldRichSpan].
  const ScaffoldRichSpan();
}

/// Plain text run with an optional [TextStyle] override.
///
/// When [styleOverride] is null, the atom renders with
/// `Theme.of(context).textTheme.bodyMedium`.
final class ScaffoldTextSpan extends ScaffoldRichSpan {
  /// Creates a [ScaffoldTextSpan].
  const ScaffoldTextSpan(this.text, {this.styleOverride});

  /// The plain-text content of this run.
  final String text;

  /// Optional style override applied over `bodyMedium`.
  final TextStyle? styleOverride;
}

/// Inline citation marker (e.g. `[1]`) with an expandable source slot.
///
/// [id] is the stable key recorded in
/// `ScaffoldStreamingRichTextState.expandedCitations`. [marker] is the pill
/// text rendered inline. [title] and [body] populate the expanded source
/// card below the paragraph when the citation is toggled open.
final class ScaffoldCitationSpan extends ScaffoldRichSpan {
  /// Creates a [ScaffoldCitationSpan].
  const ScaffoldCitationSpan({
    required this.id,
    required this.marker,
    required this.title,
    required this.body,
  });

  /// Stable key identifying this citation across appends.
  final String id;

  /// Short marker text rendered inside the pill (e.g. `[1]`).
  final String marker;

  /// Source slot title rendered when the citation is expanded.
  final String title;

  /// Source slot body rendered when the citation is expanded.
  final String body;
}

/// Hyperlink text run. Rendered with the accent color + underline; no tap
/// handler is baked into the atom — consumers wire their own navigation.
final class ScaffoldLinkSpan extends ScaffoldRichSpan {
  /// Creates a [ScaffoldLinkSpan].
  const ScaffoldLinkSpan({required this.text, required this.uri});

  /// Visible link text.
  final String text;

  /// Target URI the consumer's tap handler navigates to.
  final Uri uri;
}

/// Inline code run rendered monospace. Overrides only `fontFamily`; size,
/// weight, and color stay inherited from the host text theme.
final class ScaffoldCodeInlineSpan extends ScaffoldRichSpan {
  /// Creates a [ScaffoldCodeInlineSpan].
  const ScaffoldCodeInlineSpan(this.code);

  /// The code content rendered in monospace.
  final String code;
}
