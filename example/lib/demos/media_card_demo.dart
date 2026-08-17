// MediaCard demo for Phase 7 (WIDG-29).
//
// Shows MediaCard in 16:9, 9:16, and 1:1 aspect ratios. The 16:9 section
// populates all three typed badge slots and a two-item metadataRow to
// demonstrate the D-01 / D-02 contracts.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Width of the narrow (9:16) and square (1:1) demo cards, in logical
/// pixels. Keeps the demo section compact on desktop while wide enough for
/// the metadata row to be legible.
const double _kDemoCardWidth = 180;

/// Demo showing [MediaCard] in 16:9 / 9:16 / 1:1 with badge and
/// metadataRow compositions.
class MediaCardDemo extends StatelessWidget {
  const MediaCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('MediaCard')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 16:9 — full composition: badges + metadata row ---
            Text('16:9 — badges + metadataRow',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const MediaCard(
              aspectRatio: 16 / 9,
              topLeftBadge: ScaffoldBadge(
                variant: BadgeVariant.text,
                text: 'LIVE',
              ),
              topRightBadge: ScaffoldBadge(
                variant: BadgeVariant.text,
                text: 'NEW',
              ),
              bottomRightBadge: ScaffoldBadge(
                variant: BadgeVariant.text,
                text: 'HD',
              ),
              metadataRow: <Widget>[
                // MediaCard wraps each child in Flexible — do NOT add
                // Expanded/Flexible here. Just declare ellipsis on the Text.
                Text(
                  'A very long creator-channel-name-that-ellipsizes',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text('12:34'),
              ],
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 9:16 — narrow width to keep the demo section compact ---
            Text('9:16 — tall card',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            const SizedBox(
              width: _kDemoCardWidth,
              child: MediaCard(
                aspectRatio: 9 / 16,
                metadataRow: <Widget>[Text('Shorts')],
              ),
            ),

            SizedBox(height: dimens.itemSpacing),

            // --- 1:1 — square card, pressable ---
            Text('1:1 — square + onTap',
                style: TextStyle(color: palette.textPrimary)),
            SizedBox(height: dimens.space8),
            SizedBox(
              width: _kDemoCardWidth,
              child: MediaCard(
                aspectRatio: 1.0,
                onTap: () {},
                metadataRow: const <Widget>[Text('Album')],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
