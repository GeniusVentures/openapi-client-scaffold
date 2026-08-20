/// ScaffoldStreamingRichText -- typed-span streaming rich-text atom.
///
/// Composes ScaffoldSurface + ScaffoldLiveRegion + optional cubit (D-02).
/// Typed-span rendering only — Markdown parsing lives in
/// lib/utils/markdown_to_spans.dart (D-03). Announce-policy hook per D-06.
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or app-specific theme dependency.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/utils/scaffold_rich_spans.dart';
import 'package:frontend_scaffold/utils/streaming_announce_policy.dart';

import 'scaffold_streaming_rich_text_cubit.dart';
import 'scaffold_streaming_rich_text_state.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Streaming rich-text atom rendering a typed span tree incrementally.
///
/// Renders [ScaffoldStreamingRichTextState.spans] via `Text.rich`, plus a
/// blinking cursor block at the tail while
/// [ScaffoldStreamingRichTextState.isStreaming] is true. Citation spans
/// render as tappable pills that toggle an expanded source slot inline.
/// An optional [actions] row renders below the body with
/// `dimens.space4` vertical separation. Announcements flow through a
/// dedicated [ScaffoldLiveRegion] child; the announce-policy hook
/// ([announcePolicy]) defaults to
/// [ScaffoldBlockBoundaryAnnouncePolicy] (D-06).
///
/// The cursor blinks at 530ms visible / 530ms hidden. Under
/// [ScaffoldMotion.reducedMotion], the cursor renders static (always
/// visible, no opacity animation). The cursor hides when the stream
/// completes.
class ScaffoldStreamingRichText extends StatefulWidget {
  /// Creates a [ScaffoldStreamingRichText].
  const ScaffoldStreamingRichText({
    this.instanceId = '',
    this.cubit,
    this.semanticLabel,
    this.cursorSemanticsLabel = 'Streaming response',
    this.actions,
    this.announcePolicy,
    this.onCitationToggled,
    super.key,
  });

  /// Optional instance discriminator forwarded to the internal cubit.
  final String instanceId;

  /// Optional consumer-supplied cubit. When null, the widget owns an
  /// internal one seeded from [instanceId].
  final ScaffoldStreamingRichTextCubit? cubit;

  /// Outer Semantics label for the whole atom. Live-region duty is
  /// delegated to a dedicated [ScaffoldLiveRegion] child.
  final String? semanticLabel;

  /// Accessible label attached to the streaming-cursor glyph.
  final String cursorSemanticsLabel;

  /// Optional response-action slot row rendered below the body.
  final List<Widget>? actions;

  /// Optional announce-policy hook (D-06). When null, the widget uses
  /// [ScaffoldBlockBoundaryAnnouncePolicy] with its default 300ms debounce.
  final ScaffoldStreamingAnnouncePolicy? announcePolicy;

  /// Fired alongside the cubit's citation toggle so consumers can mirror
  /// expansion state externally.
  final ValueChanged<String>? onCitationToggled;

  @override
  State<ScaffoldStreamingRichText> createState() =>
      _ScaffoldStreamingRichTextState();
}

class _ScaffoldStreamingRichTextState extends State<ScaffoldStreamingRichText>
    with SingleTickerProviderStateMixin {
  late ScaffoldStreamingRichTextCubit _cubit;
  late bool _ownsCubit;
  late AnimationController _cursorController;

  List<ScaffoldRichSpan> _previousSpans = const <ScaffoldRichSpan>[];
  String? _lastAnnouncedText;
  DateTime? _lastAnnounceAt;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit = widget.cubit ??
        ScaffoldStreamingRichTextCubit(instanceId: widget.instanceId);
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1060),
    )..repeat();
  }

  @override
  void didUpdateWidget(ScaffoldStreamingRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool seedChanged = widget.instanceId != oldWidget.instanceId;
    if (widget.cubit != oldWidget.cubit || (_ownsCubit && seedChanged)) {
      if (_ownsCubit) {
        _cubit.close();
      }
      _ownsCubit = widget.cubit == null;
      _cubit = widget.cubit ??
          ScaffoldStreamingRichTextCubit(instanceId: widget.instanceId);
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScaffoldStreamingRichTextCubit>.value(
      value: _cubit,
      child: BlocBuilder<ScaffoldStreamingRichTextCubit,
          ScaffoldStreamingRichTextState>(
        builder: (context, state) {
          // --- Announce check (before building children) ---
          final ScaffoldStreamingAnnouncePolicy policy =
              widget.announcePolicy ??
                  const ScaffoldBlockBoundaryAnnouncePolicy();
          final String? next =
              policy.shouldAnnounce(_previousSpans, state.spans);
          final Duration policyDebounce =
              (policy is ScaffoldBlockBoundaryAnnouncePolicy)
                  ? policy.debounce
                  : Duration.zero;
          if (next != null &&
              (_lastAnnounceAt == null ||
                  DateTime.now().difference(_lastAnnounceAt!) >=
                      policyDebounce)) {
            _lastAnnouncedText = next;
            _lastAnnounceAt = DateTime.now();
          }

          final palette = context.palette;
          final dimens = context.dimens;
          final textTheme = Theme.of(context).textTheme;
          final bool reducedMotion =
              ScaffoldMotion.of(context).reducedMotion;

          // Cursor controller lifecycle: run only while streaming and
          // motion is allowed; otherwise pin/hide per reduced-motion or
          // stream-complete.
          if (reducedMotion || !state.isStreaming) {
            if (_cursorController.isAnimating) {
              _cursorController.stop();
            }
          } else if (!_cursorController.isAnimating) {
            _cursorController.repeat();
          }

          // Empty state: no spans and no actions -> zero-size.
          if (state.spans.isEmpty &&
              (widget.actions == null || widget.actions!.isEmpty)) {
            // Still record the boundary before returning.
            _previousSpans = state.spans;
            return const SizedBox.shrink();
          }

          // --- Build the typed span tree ---
          int citationOrdinal = 0;
          final List<InlineSpan> rendered = <InlineSpan>[
            for (final ScaffoldRichSpan span in state.spans)
              switch (span) {
                ScaffoldTextSpan(:final String text) => TextSpan(
                    text: text,
                    style: span.styleOverride ?? textTheme.bodyMedium,
                  ),
                ScaffoldCodeInlineSpan(:final String code) => TextSpan(
                    text: code,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ScaffoldLinkSpan(:final String text) => TextSpan(
                    text: text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.lightGreenPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ScaffoldCitationSpan() => WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _buildCitationPill(
                      context,
                      span,
                      citationOrdinal++,
                      palette,
                      dimens,
                      textTheme,
                    ),
                  ),
              },
          ];

          // --- Streaming cursor glyph ---
          final double cursorHeight = textTheme.bodyMedium?.fontSize != null
              // 1.4 = M3 body-default line-height multiplier.
              ? textTheme.bodyMedium!.fontSize! * 1.4
              : 20.0;
          final Widget cursorGlyph = state.isStreaming
              ? AnimatedBuilder(
                  animation: _cursorController,
                  builder: (context, _) {
                    final double opacity = reducedMotion
                        ? 1.0
                        : (_cursorController.value < 0.5 ? 1.0 : 0.0);
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        width: dimens.focusRingWidth,
                        height: cursorHeight,
                        color: palette.lightGreenPrimary,
                      ),
                    );
                  },
                )
              : const SizedBox.shrink();

          // --- Body row: text + cursor at tail ---
          final Widget bodyRow = Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: Text.rich(
                  TextSpan(children: rendered),
                ),
              ),
              if (state.isStreaming) ...<Widget>[
                SizedBox(width: dimens.space2),
                Semantics(
                  label: widget.cursorSemanticsLabel,
                  liveRegion: false,
                  child: cursorGlyph,
                ),
              ],
            ],
          );

          // --- Expanded citation slots ---
          final List<Widget> expandedSlots = <Widget>[];
          for (final ScaffoldRichSpan span in state.spans) {
            if (span is ScaffoldCitationSpan &&
                state.expandedCitations.contains(span.id)) {
              expandedSlots.add(
                AnimatedSize(
                  duration: reducedMotion
                      ? Duration.zero
                      : ScaffoldMotionDurations.medium,
                  curve: ScaffoldMotionCurves.standard,
                  child: Padding(
                    padding: EdgeInsets.only(top: dimens.space8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.deepBlueCardColor,
                        border: Border.all(color: palette.borderSubtle),
                        borderRadius:
                            BorderRadius.circular(dimens.radiusMd),
                      ),
                      padding: EdgeInsets.all(dimens.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(span.title, style: textTheme.titleSmall),
                          SizedBox(height: dimens.space2),
                          Text(span.body, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // --- Response-action row ---
          Widget? actionRow;
          if (widget.actions != null && widget.actions!.isNotEmpty) {
            actionRow = Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < widget.actions!.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: dimens.space4),
                  widget.actions![i],
                ],
              ],
            );
          }

          // --- Assemble the column ---
          final List<Widget> columnChildren = <Widget>[
            bodyRow,
            ...expandedSlots,
            if (actionRow != null) ...<Widget>[
              SizedBox(height: dimens.space4),
              actionRow,
            ],
            ScaffoldLiveRegion(
              value: _lastAnnouncedText,
              child: const SizedBox.shrink(),
            ),
          ];

          // Record boundary for the next announce diff.
          _previousSpans = state.spans;

          return Semantics(
            label: widget.semanticLabel,
            liveRegion: false,
            child: ScaffoldSurface(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(dimens.radiusMd),
              padding: EdgeInsets.all(dimens.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: columnChildren,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCitationPill(
    BuildContext context,
    ScaffoldCitationSpan span,
    int index,
    palette,
    dimens,
    TextTheme textTheme,
  ) {
    return Semantics(
      button: true,
      label: 'Citation ${index + 1}',
      child: ScaffoldPressable(
        onPressed: () {
          _cubit.toggleCitation(span.id);
          widget.onCitationToggled?.call(span.id);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dimens.space2),
          decoration: BoxDecoration(
            color: palette.grayPrimary,
            borderRadius: BorderRadius.circular(dimens.radiusPill),
          ),
          child: Text(
            span.marker,
            style: textTheme.labelMedium
                ?.copyWith(color: palette.lightGreenPrimary),
          ),
        ),
      ),
    );
  }
}
