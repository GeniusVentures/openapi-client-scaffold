// ScaffoldComposer demo for Phase 8 (WIDG-42).
//
// Shows ScaffoldComposer in default / with-badges / with-actions /
// badges+actions / disabled compositions, plus an interactive submission
// log demonstrating the onSubmit(String) contract (D-07: the atom holds
// no submission logic — the consumer owns what happens with the string).
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_composer.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Demo showing [ScaffoldComposer] in its slot compositions plus an
/// interactive submission log.
class ScaffoldComposerDemo extends StatelessWidget {
  const ScaffoldComposerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('ScaffoldComposer')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Default — text entry only ---
            Text('Default', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldComposer(
              hintText: 'Type a message…',
              onSubmit: (String _) {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- With badges ---
            Text('With badges', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldComposer(
              hintText: 'Type a message…',
              badgeRow: const <Widget>[
                ScaffoldBadge(variant: BadgeVariant.text, text: 'Draft'),
                ScaffoldBadge(variant: BadgeVariant.count, count: 2),
              ],
              onSubmit: (String _) {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- With actions ---
            Text('With actions', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldComposer(
              hintText: 'Type a message…',
              actionRow: <Widget>[
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: () {}),
              ],
              onSubmit: (String _) {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- With badges and actions ---
            Text('With badges and actions',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldComposer(
              hintText: 'Type a message…',
              badgeRow: const <Widget>[
                ScaffoldBadge(variant: BadgeVariant.text, text: 'Draft'),
              ],
              actionRow: <Widget>[
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: () {}),
              ],
              onSubmit: (String _) {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- Disabled ---
            Text('Disabled', style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            ScaffoldComposer(
              hintText: 'Type a message…',
              disabled: true,
              onSubmit: (String _) {},
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- Submission log — interactive onSubmit demonstration ---
            Text('Submission log',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const _SubmissionLogComposer(),
          ],
        ),
      ),
    );
  }
}

/// Interactive section: a composer whose submissions are appended to a
/// scrolling log below it. Demonstrates D-07 — the atom emits the string
/// via onSubmit and clears itself; the consumer owns the submission list.
class _SubmissionLogComposer extends StatefulWidget {
  const _SubmissionLogComposer();

  @override
  State<_SubmissionLogComposer> createState() => _SubmissionLogComposerState();
}

class _SubmissionLogComposerState extends State<_SubmissionLogComposer> {
  final List<String> _submissions = <String>[];

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ScaffoldComposer(
          hintText: 'Type a message…',
          actionRow: <Widget>[
            IconButton(icon: const Icon(Icons.send), onPressed: () {}),
          ],
          onSubmit: (String value) {
            setState(() => _submissions.add(value));
          },
        ),
        SizedBox(height: dimens.space8),
        for (int i = 0; i < _submissions.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: dimens.space2),
            child: Text(
              '${i + 1}. ${_submissions[i]}',
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
      ],
    );
  }
}
