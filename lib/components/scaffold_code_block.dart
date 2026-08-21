/// ScaffoldCodeBlock — M3 code display atom.
///
/// Composes [ScaffoldSurface] + [ScaffoldOverflowFade] + [ScaffoldPressable]
/// (copy). D-04: syntax highlighting via DI — accepts pre-highlighted spans
/// AND/OR a `syntaxHighlighter` callback; the atom never tokenizes raw text
/// itself (that lives in `lib/utils/light_syntax_tokenizer.dart`, D-08
/// isolated).
///
/// Consumes `Theme.of(context)` via `context.palette` / `context.dimens`
/// only — no hardcoded colors or dims. Every animation reads
/// `ScaffoldMotion.of(context).reducedMotion` and substitutes a zero-duration
/// fallback.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_overflow_fade.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Approximate monospace glyph advance width at the code body's monospace
/// size (`bodyMedium`, ~0.6 × fontSize). Used to compute the line-number
/// gutter width from the digit count of the largest line number. Documented
/// as an approximation — glyph metrics vary by font.
const double _kMonospaceGlyphWidth = 8.5;

/// Opacity of the transient "new line" highlight background (12%).
const double _kNewLineHighlightOpacity = 0.12;

/// A single highlighted token — text plus an optional color override.
///
/// When [color] is null the atom renders the span in
/// `palette.textPrimary` (the default code-body color).
final class ScaffoldCodeSpan {
  /// Creates a span.
  const ScaffoldCodeSpan({required this.text, this.color});

  /// Span text (no trailing newline).
  final String text;

  /// Optional color override; null falls back to `palette.textPrimary`.
  final Color? color;
}

/// A single line of code. [rawText] is the source-of-truth string used by
/// the copy action; [spans] is the optional pre-highlighted rendering.
///
/// When both are provided, the atom renders [spans] but copies [rawText].
final class ScaffoldCodeLine {
  /// Creates a line.
  const ScaffoldCodeLine({required this.rawText, this.spans});

  /// Raw source string (used by copy and as the fallback rendered text).
  final String rawText;

  /// Optional pre-highlighted span list. When null the atom renders
  /// [rawText] in `palette.textPrimary` (or via the consumer-supplied
  /// `syntaxHighlighter` if one was provided to the widget).
  final List<ScaffoldCodeSpan>? spans;
}

/// Syntax highlighter callback (D-04 DI hook). Consumers transform raw text
/// into a span list at the widget boundary; the atom never tokenizes.
typedef ScaffoldCodeHighlighter = List<ScaffoldCodeSpan> Function(
  String rawText,
);

/// Code display atom.
///
/// Renders consumer-supplied code lines (optionally pre-highlighted spans,
/// D-04) inside a header + gutter + body layout, with horizontal scrolling +
/// right-edge overflow fade, streamed line insertion, copy-to-clipboard with
/// transient confirmation, and full reduced-motion gating.
class ScaffoldCodeBlock extends StatefulWidget {
  /// Creates a code block.
  const ScaffoldCodeBlock({
    super.key,
    this.lines = const <ScaffoldCodeLine>[],
    this.streamedLines,
    this.syntaxHighlighter,
    this.language,
    this.filename,
    this.copyTooltip = 'Copy',
    this.showLineNumbers = true,
    this.highlightNewLines = false,
    this.semanticLabel,
  });

  /// Initial lines rendered in the body.
  final List<ScaffoldCodeLine> lines;

  /// Optional stream of line-deltas appended at the end (D-04 / WIDG-38).
  final Stream<List<ScaffoldCodeLine>>? streamedLines;

  /// Optional consumer-supplied highlighter (D-04 DI hook). When provided
  /// AND a line's [ScaffoldCodeLine.spans] is null, the atom calls this
  /// at render time to derive spans. When a line already has spans, the
  /// highlighter is NOT called for that line.
  final ScaffoldCodeHighlighter? syntaxHighlighter;

  /// Optional language tag rendered in the header (`labelMedium`).
  final String? language;

  /// Optional filename rendered in the header (`titleSmall`).
  final String? filename;

  /// Tooltip / semantics label for the copy button.
  final String copyTooltip;

  /// When true, the line-number gutter is rendered.
  final bool showLineNumbers;

  /// Consumer opt-in for a transient 500ms highlight on newly-streamed
  /// lines. Disabled under reduced motion.
  final bool highlightNewLines;

  /// Accessible name announced for the outer code block. When null, the
  /// atom builds `'Code block${language != null ? " ($language)" : ""}'`.
  final String? semanticLabel;

  @override
  State<ScaffoldCodeBlock> createState() => _ScaffoldCodeBlockState();
}

class _ScaffoldCodeBlockState extends State<ScaffoldCodeBlock> {
  bool _isCopied = false;
  Timer? _copiedTimer;
  StreamSubscription<List<ScaffoldCodeLine>>? _streamSubscription;
  final List<ScaffoldCodeLine> _streamedLines = <ScaffoldCodeLine>[];
  final Set<int> _recentlyAddedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(ScaffoldCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streamedLines != oldWidget.streamedLines) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _subscribeToStream();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _subscribeToStream() {
    final Stream<List<ScaffoldCodeLine>>? stream = widget.streamedLines;
    if (stream == null) {
      return;
    }
    _streamSubscription = stream.listen(_onStreamedDelta);
  }

  void _onStreamedDelta(List<ScaffoldCodeLine> delta) {
    if (delta.isEmpty || !mounted) {
      return;
    }
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;
    final int start = widget.lines.length + _streamedLines.length;
    setState(() {
      _streamedLines.addAll(delta);
      if (widget.highlightNewLines && !reducedMotion) {
        for (int i = 0; i < delta.length; i++) {
          _recentlyAddedIndices.add(start + i);
        }
      }
    });
    if (widget.highlightNewLines && !reducedMotion) {
      // Remove the highlight after ScaffoldMotionDurations.long so the line
      // fades back to the default background. A natural fade-out via removal
      // is acceptable per the plan — no explicit reverse animation.
      Timer(ScaffoldMotionDurations.long, () {
        if (!mounted) {
          return;
        }
        setState(() {
          for (int i = 0; i < delta.length; i++) {
            _recentlyAddedIndices.remove(start + i);
          }
        });
      });
    }
  }

  void _onCopy(bool reducedMotion) {
    final List<ScaffoldCodeLine> allLines = <ScaffoldCodeLine>[
      ...widget.lines,
      ..._streamedLines,
    ];
    final String combined =
        allLines.map((ScaffoldCodeLine l) => l.rawText).join('\n');
    Clipboard.setData(ClipboardData(text: combined));
    setState(() => _isCopied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(
      reducedMotion ? Duration.zero : ScaffoldMotionDurations.medium,
      () {
        if (mounted) {
          setState(() => _isCopied = false);
        }
      },
    );
  }

  List<InlineSpan> _buildSpans(ScaffoldCodeLine line, TextStyle codeTextStyle) {
    if (line.spans != null) {
      return line.spans!
          .map(
            (ScaffoldCodeSpan span) => TextSpan(
              text: span.text,
              style: span.color != null
                  ? codeTextStyle.copyWith(color: span.color)
                  : codeTextStyle,
            ),
          )
          .toList(growable: false);
    }
    final ScaffoldCodeHighlighter? highlighter = widget.syntaxHighlighter;
    if (highlighter != null) {
      return highlighter(line.rawText)
          .map(
            (ScaffoldCodeSpan span) => TextSpan(
              text: span.text,
              style: span.color != null
                  ? codeTextStyle.copyWith(color: span.color)
                  : codeTextStyle,
            ),
          )
          .toList(growable: false);
    }
    return <InlineSpan>[TextSpan(text: line.rawText, style: codeTextStyle)];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool reducedMotion = ScaffoldMotion.of(context).reducedMotion;

    final List<ScaffoldCodeLine> allLines = <ScaffoldCodeLine>[
      ...widget.lines,
      ..._streamedLines,
    ];

    final TextStyle codeTextStyle =
        (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      height: 1.5,
      color: palette.textPrimary,
    );

    // Gutter shares the code body's exact font metrics (family, size, and
    // line height) so line numbers stay vertically aligned with their code
    // lines; only the color differs.
    final TextStyle gutterTextStyle =
        codeTextStyle.copyWith(color: palette.textSecondary);

    // Gutter width scales with the digit count of the largest line number so
    // longer files get a wider gutter.
    final double gutterWidth =
        '${allLines.length}'.length * _kMonospaceGlyphWidth + dimens.space2;

    final String outerLabel = widget.semanticLabel ??
        'Code block${widget.language != null ? " (${widget.language})" : ""}';

    return Semantics(
      label: outerLabel,
      child: ScaffoldSurface(
        color: palette.deepBlueCardColor,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
        border: Border.all(color: palette.borderSubtle, width: 1),
        padding: EdgeInsets.all(dimens.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(
              palette: palette,
              dimens: dimens,
              textTheme: textTheme,
              reducedMotion: reducedMotion,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: dimens.space4),
              child: Divider(height: 1, color: palette.borderSubtle),
            ),
            if (allLines.isEmpty)
              const SizedBox.shrink()
            else
              _buildBody(
                allLines: allLines,
                palette: palette,
                dimens: dimens,
                reducedMotion: reducedMotion,
                gutterTextStyle: gutterTextStyle,
                codeTextStyle: codeTextStyle,
                gutterWidth: gutterWidth,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required dynamic palette,
    required dynamic dimens,
    required TextTheme textTheme,
    required bool reducedMotion,
  }) {
    final List<Widget> children = <Widget>[
      Text(
        widget.language ?? '',
        style: textTheme.labelMedium?.copyWith(color: palette.textSecondary),
      ),
    ];
    if (widget.filename != null) {
      children.add(SizedBox(width: dimens.space4));
      children.add(
        Expanded(
          child: Text(
            widget.filename!,
            style: textTheme.titleSmall?.copyWith(color: palette.textPrimary),
          ),
        ),
      );
    } else {
      children.add(const Spacer());
    }
    children.add(
      ScaffoldPressable(
        semanticLabel: widget.copyTooltip,
        onPressed: () => _onCopy(reducedMotion),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedSwitcher(
              duration: reducedMotion
                  ? Duration.zero
                  : ScaffoldMotionDurations.medium,
              child: Icon(
                _isCopied ? Icons.check : Icons.copy,
                key: ValueKey<bool>(_isCopied),
                size: 20,
                color: _isCopied
                    ? palette.statusSuccess
                    : palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
    return Row(children: children);
  }

  Widget _buildBody({
    required List<ScaffoldCodeLine> allLines,
    required dynamic palette,
    required dynamic dimens,
    required bool reducedMotion,
    required TextStyle gutterTextStyle,
    required TextStyle codeTextStyle,
    required double gutterWidth,
  }) {
    final List<Widget> rowChildren = <Widget>[];
    if (widget.showLineNumbers) {
      rowChildren.add(
        ExcludeSemantics(
          child: SizedBox(
            width: gutterWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < allLines.length; i++)
                  Text('${i + 1}', style: gutterTextStyle),
              ],
            ),
          ),
        ),
      );
      rowChildren.add(SizedBox(width: dimens.space4));
    }
    rowChildren.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < allLines.length; i++)
            _buildLineRow(
              index: i,
              line: allLines[i],
              palette: palette,
              reducedMotion: reducedMotion,
              codeTextStyle: codeTextStyle,
              isStreamed: i >= widget.lines.length,
            ),
        ],
      ),
    );

    return ScaffoldOverflowFade(
      fadeDirection: FadeDirection.right,
      fadeExtent: 24.0,
      backgroundColor: palette.deepBlueCardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rowChildren,
        ),
      ),
    );
  }

  Widget _buildLineRow({
    required int index,
    required ScaffoldCodeLine line,
    required dynamic palette,
    required bool reducedMotion,
    required TextStyle codeTextStyle,
    required bool isStreamed,
  }) {
    Widget row;
    if (line.rawText.isEmpty && line.spans == null) {
      // Preserve line height on empty lines by rendering a single space.
      row = Text(' ', style: codeTextStyle);
    } else {
      row = Text.rich(
        TextSpan(
          style: codeTextStyle,
          children: _buildSpans(line, codeTextStyle),
        ),
      );
    }

    if (widget.highlightNewLines && _recentlyAddedIndices.contains(index)) {
      row = Container(
        color: palette.statusWarningText
            .withValues(alpha: _kNewLineHighlightOpacity),
        child: row,
      );
    }

    if (isStreamed) {
      row = AnimatedOpacity(
        // Key ensures Flutter treats this as a new widget on insertion so
        // AnimatedOpacity runs its 0 -> 1 transition once.
        key: ValueKey<int>(index),
        opacity: 1.0,
        duration:
            reducedMotion ? Duration.zero : ScaffoldMotionDurations.short,
        curve: ScaffoldMotionCurves.decelerate,
        child: row,
      );
    }

    return row;
  }
}
