// ScaffoldTraceList demo for Phase 8 (WIDG-41).
//
// Exercises the three render variants: simple ordered items, items grouped
// under a groupHeader, and the empty-state shrink contract.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_trace_list.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Demo showing [ScaffoldTraceList] in its three render variants.
class ScaffoldTraceListDemo extends StatelessWidget {
  const ScaffoldTraceListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldTraceList')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Simple trace (ordered items, mixed status slots) ---
            Text(
              'Simple trace',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            const ScaffoldTraceList(
              items: <TraceItem>[
                TraceItem(
                  title: 'Step 1: Load',
                  body: Text('Loaded 42 items.'),
                ),
                TraceItem(
                  title: 'Step 2: Filter',
                  body: Text('Filtered to 7.'),
                  status: StatusVariant.success,
                ),
                TraceItem(
                  title: 'Step 3: Render',
                  body: Text('Rendered.'),
                  status: StatusVariant.info,
                ),
              ],
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. With group header ---
            Text(
              'With group header',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            const ScaffoldTraceList(
              groupHeader: 'Pipeline',
              items: <TraceItem>[
                TraceItem(
                  title: 'Stage A',
                  body: Text('Done.'),
                  status: StatusVariant.success,
                ),
                TraceItem(
                  title: 'Stage B',
                  body: Text('Pending.'),
                  status: StatusVariant.warning,
                ),
              ],
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Empty state (renders zero-size shrink) ---
            Text(
              'Empty state (renders zero height)',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            const ScaffoldTraceList(items: <TraceItem>[]),
          ],
        ),
      ),
    );
  }
}
