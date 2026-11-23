// ScaffoldDisclosure demo for Phase 8 (WIDG-41).
//
// Exercises the four state variants: uncontrolled collapsed, uncontrolled
// expanded, highlightWhenExpanded, and fully controlled via a StatefulBuilder.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_disclosure.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Demo showing [ScaffoldDisclosure] in its four state variants.
class ScaffoldDisclosureDemo extends StatelessWidget {
  const ScaffoldDisclosureDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldDisclosure')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Uncontrolled (collapsed by default) ---
            Text(
              'Uncontrolled (collapsed by default)',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            ScaffoldDisclosure(
              title: 'What is the scaffold?',
              body: Text(
                'A shared widget library.',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. Uncontrolled (expanded by default) ---
            Text(
              'Uncontrolled (expanded by default)',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            ScaffoldDisclosure(
              title: 'What is the scaffold?',
              initiallyExpanded: true,
              body: Text(
                'A shared widget library.',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Highlight when expanded ---
            Text(
              'Highlight when expanded',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            ScaffoldDisclosure(
              title: 'Tap to see the chevron tint',
              highlightWhenExpanded: true,
              body: Text(
                'Chevron flips to the accent green while expanded.',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Controlled ---
            Text(
              'Controlled',
              style: TextStyle(color: palette.textPrimary),
            ),
            SizedBox(height: dimens.space8),
            const _ControlledDisclosure(),
          ],
        ),
      ),
    );
  }
}

/// Controlled disclosure owning its local expansion state.
///
/// Hoists the `expanded` boolean out of the build path so the parent truly
/// owns the truth — the disclosure only fires the callback.
class _ControlledDisclosure extends StatefulWidget {
  const _ControlledDisclosure();

  @override
  State<_ControlledDisclosure> createState() => _ControlledDisclosureState();
}

class _ControlledDisclosureState extends State<_ControlledDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ScaffoldDisclosure(
      title: 'Parent-owned state',
      expanded: _expanded,
      onExpandedChanged: (bool next) => setState(() => _expanded = next),
      body: Text(
        'Expansion truth lives in the parent — this row only '
        'fires the callback.',
        style: TextStyle(color: palette.textSecondary),
      ),
    );
  }
}
