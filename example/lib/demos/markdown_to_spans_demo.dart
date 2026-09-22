// scaffoldMarkdownToSpans demo for Phase 9 Plan 05 (WIDG-32/33/34, D-03).
//
// Demonstrates the Markdown → typed-span mapper feeding
// ScaffoldStreamingRichText. Shows the D-03 support part working end-to-end
// with the citation pre-pass, plus a custom announce policy wired through
// the D-06 hook.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text_cubit.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/utils/markdown_to_spans.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';
import 'package:frontend_scaffold/utils/streaming_announce_policy.dart';

/// Sample Markdown exercising paragraph, heading, inline code, link, and
/// the citation pre-pass.
const String _kSampleMarkdown = '''
# Heading

A paragraph with **bold**, inline `code`, and a
[link](https://example.com) — plus a citation [^1].

[^1]: Source One | The body of the cited source.
''';

/// Demo showing [scaffoldMarkdownToSpans] feeding
/// [ScaffoldStreamingRichText].
class ScaffoldMarkdownToSpansDemo extends StatelessWidget {
  const ScaffoldMarkdownToSpansDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('scaffoldMarkdownToSpans')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Markdown input ---
            Text('Markdown input',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            TextField(
              controller: TextEditingController(text: _kSampleMarkdown),
              maxLines: null,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. Rendered spans (cubit seeded with the mapper output) ---
            Text('Rendered spans',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _SeededStreaming(),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Custom announce policy (D-06 hook) ---
            Text('Custom announce policy',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _CustomPolicyStreaming(),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Light palette ---
            Text('Light palette',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            Theme(
              data: ThemeData.light().copyWith(
                extensions: const <ThemeExtension<dynamic>>[
                  ScaffoldPalette.lightPalette,
                  ScaffoldDimens.defaultDimens,
                ],
              ),
              child: const _SeededStreaming(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Streaming rich text seeded with the mapper's output. The citation is
/// tappable — tapping expands the source slot below the paragraph.
class _SeededStreaming extends StatefulWidget {
  const _SeededStreaming();

  @override
  State<_SeededStreaming> createState() => _SeededStreamingState();
}

class _SeededStreamingState extends State<_SeededStreaming> {
  late final ScaffoldStreamingRichTextCubit _cubit =
      ScaffoldStreamingRichTextCubit()
        ..appendSpans(scaffoldMarkdownToSpans(_kSampleMarkdown))
        ..complete();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldStreamingRichText(cubit: _cubit);
  }
}

/// Demo announce policy — announces EVERY block with a `[Demo]` prefix to
/// prove the D-06 hook is genuinely injectable.
final class _DemoAnnouncePolicy extends ScaffoldStreamingAnnouncePolicy {
  const _DemoAnnouncePolicy();

  @override
  String? shouldAnnounce(
    List<ScaffoldRichSpan> previous,
    List<ScaffoldRichSpan> next,
  ) {
    if (next.length <= previous.length) {
      return null;
    }
    final ScaffoldRichSpan tail = next.last;
    final String tailText = switch (tail) {
      ScaffoldTextSpan(:final String text) => text,
      ScaffoldCodeInlineSpan(:final String code) => code,
      ScaffoldLinkSpan(:final String text) => text,
      ScaffoldCitationSpan(:final String marker) => marker,
    };
    if (tailText.isEmpty) {
      return null;
    }
    return '[Demo] $tailText';
  }
}

/// Streaming rich text wired to the custom announce policy.
class _CustomPolicyStreaming extends StatefulWidget {
  const _CustomPolicyStreaming();

  @override
  State<_CustomPolicyStreaming> createState() => _CustomPolicyStreamingState();
}

class _CustomPolicyStreamingState extends State<_CustomPolicyStreaming> {
  late final ScaffoldStreamingRichTextCubit _cubit =
      ScaffoldStreamingRichTextCubit()
        ..appendSpans(scaffoldMarkdownToSpans(_kSampleMarkdown))
        ..complete();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldStreamingRichText(
      cubit: _cubit,
      announcePolicy: const _DemoAnnouncePolicy(),
    );
  }
}
