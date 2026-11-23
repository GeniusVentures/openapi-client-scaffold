// Demo for ScaffoldStreamingRichText (WIDG-32..34). Shows typed-span
// rendering, streaming cursor, citation expansion, action slots,
// reduced-motion, and light-palette rendering.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_chip.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_copy_button.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text.dart';
import 'package:frontend_scaffold/components/scaffold_streaming_rich_text_cubit.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';

/// Full response text used by the response-action copy button.
const String _kFullResponseText =
    'The widget renders a typed span tree. Spans arrive incrementally. '
    'Citations expand inline [1]. Inline `code` renders monospace.';

/// Demo for [ScaffoldStreamingRichText] (WIDG-32/33/34).
class ScaffoldStreamingRichTextDemo extends StatelessWidget {
  const ScaffoldStreamingRichTextDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldStreamingRichText')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Default (static spans) ---
            Text('Default (static spans)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _StaticExample(),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. Streaming (simulated) ---
            Text('Streaming (simulated)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _StreamingExample(),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Citation toggle ---
            Text('Citation toggle',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _CitationExample(),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Response actions ---
            Text('Response actions',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _ResponseActionsExample(),

            SizedBox(height: dimens.itemSpacing),

            // --- 5. Reduced motion ---
            Text('Reduced motion',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const ScaffoldMotion(
              reducedMotion: true,
              child: _StreamingExample(),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 6. Light palette ---
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
              child: const _StaticExample(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static example — cubit pre-seeded with paragraph + citation + inline code.
class _StaticExample extends StatefulWidget {
  const _StaticExample();

  @override
  State<_StaticExample> createState() => _StaticExampleState();
}

class _StaticExampleState extends State<_StaticExample> {
  late final ScaffoldStreamingRichTextCubit _cubit =
      ScaffoldStreamingRichTextCubit()
        ..appendSpans(const <ScaffoldRichSpan>[
          ScaffoldTextSpan(
            'The widget renders a typed span tree. Spans arrive '
            'incrementally. Citations expand inline ',
          ),
          ScaffoldCitationSpan(
            id: 'cite-1',
            marker: '[1]',
            title: 'Source One',
            body: 'The body of the cited source.',
          ),
          ScaffoldTextSpan('. Inline '),
          ScaffoldCodeInlineSpan('code'),
          ScaffoldTextSpan(' renders monospace.'),
        ])
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

/// Streaming example — appends one span every 80ms up to 30 spans, then
/// completes. Restart resets the cubit.
class _StreamingExample extends StatefulWidget {
  const _StreamingExample();

  @override
  State<_StreamingExample> createState() => _StreamingExampleState();
}

class _StreamingExampleState extends State<_StreamingExample> {
  static const int _kTotalSpans = 30;
  static const Duration _kSpanInterval = Duration(milliseconds: 80);

  late ScaffoldStreamingRichTextCubit _cubit;
  Timer? _timer;
  int _appended = 0;

  @override
  void initState() {
    super.initState();
    _cubit = ScaffoldStreamingRichTextCubit();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _appended = 0;
    _timer = Timer.periodic(_kSpanInterval, (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_appended >= _kTotalSpans) {
        t.cancel();
        _cubit.complete();
        return;
      }
      _appended += 1;
      _cubit.appendSpans(<ScaffoldRichSpan>[
        ScaffoldTextSpan('token$_appended '),
      ]);
    });
  }

  void _restart() {
    _timer?.cancel();
    _cubit.close();
    setState(() {
      _cubit = ScaffoldStreamingRichTextCubit();
    });
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ScaffoldStreamingRichText(cubit: _cubit),
        SizedBox(height: dimens.space8),
        TextButton(onPressed: _restart, child: const Text('Restart')),
      ],
    );
  }
}

/// Citation example — user taps the citation pill to expand the source slot.
class _CitationExample extends StatefulWidget {
  const _CitationExample();

  @override
  State<_CitationExample> createState() => _CitationExampleState();
}

class _CitationExampleState extends State<_CitationExample> {
  late final ScaffoldStreamingRichTextCubit _cubit =
      ScaffoldStreamingRichTextCubit()
        ..appendSpans(const <ScaffoldRichSpan>[
          ScaffoldTextSpan('Tap the citation to expand its source '),
          ScaffoldCitationSpan(
            id: 'cite-toggle-1',
            marker: '[1]',
            title: 'Citation Title',
            body: 'Citation source body. Tapping the pill toggles this '
                'slot open and closed inline.',
          ),
          ScaffoldTextSpan(' inline.'),
        ])
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

/// Response-actions example — action row wires the Plan 05
/// [ScaffoldStreamingCopyButton] as the copy action; Retry/Rate remain
/// [ScaffoldChip] placeholders.
class _ResponseActionsExample extends StatefulWidget {
  const _ResponseActionsExample();

  @override
  State<_ResponseActionsExample> createState() =>
      _ResponseActionsExampleState();
}

class _ResponseActionsExampleState extends State<_ResponseActionsExample> {
  late final ScaffoldStreamingRichTextCubit _cubit =
      ScaffoldStreamingRichTextCubit()
        ..appendSpans(const <ScaffoldRichSpan>[
          ScaffoldTextSpan(_kFullResponseText),
        ])
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
      actions: <Widget>[
        const ScaffoldStreamingCopyButton(
          textToCopy: _kFullResponseText,
          label: 'Copy',
        ),
        ScaffoldChip(label: 'Retry', icon: Icons.refresh, onPressed: () {}),
        ScaffoldChip(
          label: 'Rate',
          icon: Icons.thumb_up_outlined,
          onPressed: () {},
        ),
      ],
    );
  }
}
