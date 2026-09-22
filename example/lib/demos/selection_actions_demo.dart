// ScaffoldSelectionActions demo for Phase 9 Plan 04 (WIDG-39, D-05).
//
// Demonstrates wrapping selectable text, the toolbar appearing on
// selection, the Plan 05 ScaffoldSelectionCopyAction wired into the
// toolbarBuilder slot, placement override (above/below), empty toolbar
// builders, reduced-motion gating, light-palette rendering, and a live
// toolbarAlignment (left/center/right) toggle.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_chip.dart';
import 'package:frontend_scaffold/components/scaffold_motion.dart';
import 'package:frontend_scaffold/components/scaffold_selection_actions.dart';
import 'package:frontend_scaffold/components/scaffold_selection_copy_action.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

const String _kSampleParagraph =
    'Select any portion of this text to see the floating toolbar. '
    'The toolbar is anchored to the active selection and can render any '
    'widget supplied by the consumer.';

/// Demo for [ScaffoldSelectionActions] (WIDG-39).
class ScaffoldSelectionActionsDemo extends StatelessWidget {
  const ScaffoldSelectionActionsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldSelectionActions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Default (auto placement) ---
            Text('Default (auto placement)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldSelectionActions(
              toolbarBuilder:
                  (BuildContext ctx, TextSelection sel, String plainText) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScaffoldSelectionCopyAction(selectedText: plainText),
                    ScaffoldChip(
                      label: 'Share',
                      icon: Icons.share,
                      onPressed: () {},
                    ),
                  ],
                );
              },
              child: const Text(_kSampleParagraph),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 2. Placement override (below) ---
            Text('Placement override (below)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldSelectionActions(
              toolbarPlacement: ScaffoldToolbarPlacement.below,
              toolbarBuilder:
                  (BuildContext ctx, TextSelection sel, String plainText) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScaffoldSelectionCopyAction(selectedText: plainText),
                  ],
                );
              },
              child: const Text(_kSampleParagraph),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 3. Selection reported ---
            Text('Selection reported',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _SelectionReporter(),

            SizedBox(height: dimens.itemSpacing),

            // --- 4. Empty toolbar builder ---
            Text('Empty toolbar builder',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldSelectionActions(
              toolbarBuilder:
                  (BuildContext ctx, TextSelection sel, String plainText) {
                return const SizedBox.shrink();
              },
              child: const Text(_kSampleParagraph),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 5. Reduced motion ---
            Text('Reduced motion',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldMotion(
              reducedMotion: true,
              child: ScaffoldSelectionActions(
                toolbarBuilder:
                    (BuildContext ctx, TextSelection sel, String plainText) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ScaffoldSelectionCopyAction(selectedText: plainText),
                    ],
                  );
                },
                child: const Text(_kSampleParagraph),
              ),
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
              child: Builder(
                builder: (BuildContext context) {
                  return ScaffoldSelectionActions(
                    toolbarBuilder: (BuildContext ctx, TextSelection sel,
                        String plainText) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ScaffoldSelectionCopyAction(
                              selectedText: plainText),
                        ],
                      );
                    },
                    child: const Text(_kSampleParagraph),
                  );
                },
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 7. Toolbar alignment toggle ---
            Text('Toolbar alignment (left / center / right / first / last)',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _AlignmentToggle(),
          ],
        ),
      ),
    );
  }
}

/// Live toolbar-alignment toggle — flips [ScaffoldToolbarAlignment] between
/// left / center / right (selection bounding box) and first / last (selection
/// order) so the anchor change is visible on the next selection without
/// restarting the demo.
class _AlignmentToggle extends StatefulWidget {
  const _AlignmentToggle();

  @override
  State<_AlignmentToggle> createState() => _AlignmentToggleState();
}

class _AlignmentToggleState extends State<_AlignmentToggle> {
  ScaffoldToolbarAlignment _alignment = ScaffoldToolbarAlignment.last;

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<ScaffoldToolbarAlignment>(
          segments: const <ButtonSegment<ScaffoldToolbarAlignment>>[
            ButtonSegment<ScaffoldToolbarAlignment>(
              value: ScaffoldToolbarAlignment.left,
              label: Text('Left'),
            ),
            ButtonSegment<ScaffoldToolbarAlignment>(
              value: ScaffoldToolbarAlignment.center,
              label: Text('Center'),
            ),
            ButtonSegment<ScaffoldToolbarAlignment>(
              value: ScaffoldToolbarAlignment.right,
              label: Text('Right'),
            ),
            ButtonSegment<ScaffoldToolbarAlignment>(
              value: ScaffoldToolbarAlignment.first,
              label: Text('First'),
            ),
            ButtonSegment<ScaffoldToolbarAlignment>(
              value: ScaffoldToolbarAlignment.last,
              label: Text('Last'),
            ),
          ],
          selected: <ScaffoldToolbarAlignment>{_alignment},
          onSelectionChanged: (Set<ScaffoldToolbarAlignment> chosen) {
            setState(() => _alignment = chosen.first);
          },
        ),
        SizedBox(height: dimens.space8),
        ScaffoldSelectionActions(
          toolbarAlignment: _alignment,
          toolbarBuilder:
              (BuildContext ctx, TextSelection sel, String plainText) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ScaffoldSelectionCopyAction(selectedText: plainText),
              ],
            );
          },
          child: const Text(_kSampleParagraph),
        ),
      ],
    );
  }
}

/// Selection reporter — mirrors the active selection into a label below
/// the wrapped text and renders the selection length inside the toolbar.
class _SelectionReporter extends StatefulWidget {
  const _SelectionReporter();

  @override
  State<_SelectionReporter> createState() => _SelectionReporterState();
}

class _SelectionReporterState extends State<_SelectionReporter> {
  String _lastSelected = '';

  @override
  Widget build(BuildContext context) {
    final ScaffoldDimens dimens = context.dimens;
    final ScaffoldPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ScaffoldSelectionActions(
          onSelectionChanged: (TextSelection selection, String plainText) {
            setState(() => _lastSelected = plainText);
          },
          toolbarBuilder:
              (BuildContext ctx, TextSelection selection, String plainText) {
            final int length = plainText.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('$length chars'),
                SizedBox(width: dimens.space4),
                ScaffoldSelectionCopyAction(selectedText: plainText),
              ],
            );
          },
          child: const Text(_kSampleParagraph),
        ),
        SizedBox(height: dimens.space8),
        Text(
          'Last selection: $_lastSelected',
          style: TextStyle(color: palette.textSecondary),
        ),
      ],
    );
  }
}
