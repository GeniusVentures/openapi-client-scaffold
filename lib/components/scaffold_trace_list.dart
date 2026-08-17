/// ScaffoldTraceList — M3 ordered trace of disclosure rows.
///
/// Renders an ordered `List<TraceItem>` as [ScaffoldDisclosure] rows with
/// [ScaffoldDimens.space8] vertical separation and an optional [groupHeader]
/// (`textTheme.titleSmall` with [ScaffoldDimens.space12] top padding). When
/// [TraceItem.status] is non-null, a [ScaffoldStatusIndicator] is composed
/// as a leading slot outside the disclosure title — keeping [ScaffoldDisclosure]
/// untouched. Renders [SizedBox.shrink] when [items] is empty. Consumes
/// `Theme.of(context)` via `context.palette` / `context.dimens` only — no
/// hardcoded colors or dims.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// A single trace item — domain-agnostic, one-way data in.
class TraceItem {
  /// Creates a trace item.
  const TraceItem({
    required this.title,
    required this.body,
    this.status,
    this.initiallyExpanded = false,
  });

  /// Item header text.
  final String title;

  /// Item body content (rendered inside the disclosure).
  final Widget body;

  /// Optional leading status indicator variant.
  final StatusVariant? status;

  /// Initial expansion state when the inner disclosure is uncontrolled.
  final bool initiallyExpanded;
}

/// Ordered trace of disclosure rows.
///
/// Pure render-only atom — no selection truth, no expansion truth. Each item
/// becomes a [ScaffoldDisclosure] with its own transient state.
class ScaffoldTraceList extends StatelessWidget {
  /// Creates a trace list.
  const ScaffoldTraceList({
    super.key,
    required this.items,
    this.groupHeader,
  });

  /// Ordered items rendered top-to-bottom.
  final List<TraceItem> items;

  /// Optional section header rendered above the items with `titleSmall`
  /// typography and [ScaffoldDimens.space12] top padding.
  final String? groupHeader;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> children = <Widget>[];
    if (groupHeader != null) {
      children
        ..add(Padding(
          padding: EdgeInsets.only(top: dimens.space12),
          child: Text(
            groupHeader!,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ))
        ..add(SizedBox(height: dimens.space8));
    }
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(SizedBox(height: dimens.space8));
      }
      children.add(_buildItem(context, items[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildItem(BuildContext context, TraceItem item) {
    final dimens = context.dimens;
    final Widget disclosure = ScaffoldDisclosure(
      title: item.title,
      body: item.body,
      initiallyExpanded: item.initiallyExpanded,
    );

    if (item.status == null) {
      return disclosure;
    }

    // Leading status slot — composed outside the disclosure title so
    // ScaffoldDisclosure stays untouched (UI-SPEC "Status slot" row).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ScaffoldStatusIndicator(status: item.status!, dotSize: 8),
        SizedBox(width: dimens.space4),
        Expanded(child: disclosure),
      ],
    );
  }
}
