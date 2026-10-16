/// ScaffoldComposer — M3 text-composition area with badge and action slots.
///
/// Composes [ScaffoldSurface] + [TextField] + consumer-supplied action/badge
/// slots. Holds NO submission logic — `onSubmit(String)` is the only output
/// (D-07). Standalone widget consuming Theme.of(context) via
/// context.palette/dimens; no framework-specific state dependencies.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_focus_outline.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// M3 text-composition area with badge and action slots.
///
/// Renders a [ScaffoldSurface] container (`palette.surfaceElevated` fill,
/// `palette.borderSubtle` 1px border, `dimens.radiusMd` corner radius)
/// holding three named rows in order: an optional badge/attachment row
/// ([badgeRow]), the text-entry row, and an optional action row
/// ([actionRow]) — separated by `dimens.space4` vertical gaps.
///
/// The composer holds NO submission logic: submitting the text field fires
/// [onSubmit] once with the entered string and clears the internal
/// controller. Attachments, badges, and send behavior are owned by the
/// consumer (D-07). The whole surface is wrapped in a
/// [ScaffoldFocusOutline] bound to the text field's [FocusNode]; when
/// [disabled] the surface is wrapped in a [ScaffoldDisabledOverlay] and the
/// text field is disabled.
class ScaffoldComposer extends StatefulWidget {
  const ScaffoldComposer({
    super.key,
    this.hintText,
    this.badgeRow,
    this.actionRow,
    this.onSubmit,
    this.disabled = false,
    this.maxLines,
    this.focusNode,
  });

  /// Hint text shown inside the text field (consumer-supplied).
  final String? hintText;

  /// Optional badge/attachment row rendered above the text field inside a
  /// `Wrap` with `dimens.space4` spacing.
  final List<Widget>? badgeRow;

  /// Optional action row rendered below the text field inside an end-aligned
  /// `Row` with `dimens.space4` separation between slots.
  final List<Widget>? actionRow;

  /// Fired once when the user submits the text field; the controller is
  /// cleared immediately after. The composer holds no submission logic.
  final ValueChanged<String>? onSubmit;

  /// When true, dims the whole composer and disables the text field.
  final bool disabled;

  /// Maximum lines for the text field (defaults to 1 via [TextField]).
  final int? maxLines;

  /// Optional focus node for the text field. When null an internal node is
  /// created. Supplying one lets the consumer drive focus (e.g. tap-to-focus
  /// on a wrapping surface, keyboard shortcuts) — the composer never requests
  /// focus itself (D-07: behavior is consumer-owned). A consumer-supplied
  /// node is owned and disposed by the consumer.
  final FocusNode? focusNode;

  @override
  State<ScaffoldComposer> createState() => _ScaffoldComposerState();
}

class _ScaffoldComposerState extends State<ScaffoldComposer> {
  /// Transient state only — submission truth lives in the consumer (D-03).
  late final TextEditingController _controller;
  late FocusNode _textFieldFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _textFieldFocusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(ScaffoldComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      // The consumer swapped the node. Dispose the previous node only if the
      // composer owned it, then follow the new node (or create an internal
      // one when the consumer cleared the override).
      if (oldWidget.focusNode == null) {
        _textFieldFocusNode.dispose();
      }
      _textFieldFocusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Only dispose the focus node when the composer created it; a
    // consumer-supplied node is owned and disposed by the consumer.
    if (widget.focusNode == null) {
      _textFieldFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final textTheme = Theme.of(context).textTheme;

    final Widget textField = TextField(
      controller: _controller,
      focusNode: _textFieldFocusNode,
      style: textTheme.bodyMedium,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: widget.hintText,
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        isDense: true,
      ),
      minLines: 1,
      maxLines: widget.maxLines ?? 1,
      enabled: !widget.disabled,
      onSubmitted: (String value) {
        widget.onSubmit?.call(value);
        _controller.clear();
      },
    );

    final List<Widget> rows = <Widget>[];

    final List<Widget>? badgeRow = widget.badgeRow;
    if (badgeRow != null && badgeRow.isNotEmpty) {
      rows.add(
        Wrap(
          spacing: dimens.space4,
          runSpacing: dimens.space4,
          children: badgeRow,
        ),
      );
    }

    if (rows.isNotEmpty) {
      rows.add(SizedBox(height: dimens.space4));
    }
    rows.add(textField);

    final List<Widget>? actionRow = widget.actionRow;
    if (actionRow != null && actionRow.isNotEmpty) {
      rows.add(SizedBox(height: dimens.space4));
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < actionRow.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: dimens.space4),
              actionRow[i],
            ],
          ],
        ),
      );
    }

    final Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );

    final Widget padded = Padding(
      padding: EdgeInsets.all(dimens.space8),
      child: column,
    );

    Widget surface = ScaffoldSurface(
      color: palette.surfaceElevated,
      borderRadius: BorderRadius.circular(dimens.radiusMd),
      border: Border.all(color: palette.borderSubtle, width: 1),
      child: padded,
    );

    surface = ScaffoldFocusOutline(
      focusNode: _textFieldFocusNode,
      borderRadius: BorderRadius.circular(dimens.radiusMd),
      child: surface,
    );

    if (widget.disabled) {
      surface = ScaffoldDisabledOverlay(disabled: true, child: surface);
    }

    return surface;
  }
}
