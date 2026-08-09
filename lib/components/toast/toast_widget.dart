import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/toast/toast_manager.dart';
import 'package:frontend_scaffold/theme/scaffold_elevation.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// How much room a toast is allowed to take, chosen by what it has to say.
///
/// [compact] is a receipt — "Link copied", after the user tapped copy. They
/// already know; a bordered card with a bold title and a close button shouts
/// it back at them. [card] is an alert the user did not ask for and may need
/// to act on, so it earns the title, the dismiss affordance and the longer
/// read.
enum ToastDensity { compact, card }

/// A toast, in one of two densities.
///
/// Painted straight into the root `Overlay`, so it floats above any page
/// content and must read correctly over anything — hence the opaque
/// [ScaffoldPalette.surfaceElevated] fill rather than a translucent scrim.
///
/// The status colour is carried by the leading icon only — title and message
/// stay on the neutral [ScaffoldPalette.textPrimary]/
/// [ScaffoldPalette.textSecondary] ladder, so the toast never depends on a
/// status colour for legibility.
class ToastWidget extends StatelessWidget {
  final String message;

  /// Null selects [ToastDensity.compact]. A title is what makes a toast an
  /// alert rather than a confirmation.
  final String? title;
  final ToastType type;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
    this.title,
  });

  ToastDensity get density =>
      title == null ? ToastDensity.compact : ToastDensity.card;

  Color _accent(ScaffoldPalette palette) {
    switch (type) {
      case ToastType.success:
        return palette.statusSuccess;
      case ToastType.error:
        return palette.statusError;
      case ToastType.warning:
        return palette.statusWarningText;
    }
  }

  IconData _icon() {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline_outlined;
      case ToastType.error:
        return Icons.error_outline_outlined;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
    }
  }

  /// What a screen reader is handed. An error interrupts; a confirmation
  /// waits its turn — `assertive` vs `polite` is the whole reason
  /// [Semantics.liveRegion] is not enough on its own.
  String get semanticLabel => title == null ? message : '$title. $message';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = _accent(palette);

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      // A toast is inserted straight into the root Overlay, which has no
      // Material ancestor. Without this, Text falls back to the debug style —
      // reddish with a yellow double underline — because `decoration` is
      // inherited from the ambient DefaultTextStyle and the text styles
      // only set colour and size. It also gives the dismiss IconButton
      // something to paint its ink into. `transparency` so the Container
      // below stays the only thing painting a surface.
      child: Material(
        type: MaterialType.transparency,
        child: density == ToastDensity.compact
            ? _Compact(
                accent: accent,
                icon: _icon(),
                message: message,
                palette: palette,
              )
            : _Card(
                accent: accent,
                icon: _icon(),
                title: title!,
                message: message,
                onDismiss: onDismiss,
                palette: palette,
              ),
      ),
    );
  }
}

/// The receipt: one line, sized to its own content, no dismiss affordance —
/// it is gone in about two seconds and nothing is lost if it is missed.
class _Compact extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String message;
  final ScaffoldPalette palette;

  const _Compact({
    required this.accent,
    required this.icon,
    required this.message,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space8,
        vertical: dimens.space3,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        border: Border.all(color: palette.borderSubtle),
        borderRadius: BorderRadius.circular(dimens.radiusPill),
        boxShadow: ScaffoldElevation.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          SizedBox(width: dimens.space3),
          Flexible(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: palette.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The alert: a leading status edge instead of a full ring, so the colour
/// still identifies the kind without the container shouting.
class _Card extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final ScaffoldPalette palette;

  const _Card({
    required this.accent,
    required this.icon,
    required this.title,
    required this.message,
    required this.onDismiss,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return Container(
      padding: EdgeInsets.all(dimens.space6),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        border: Border.all(color: palette.borderSubtle),
        borderRadius: BorderRadius.circular(dimens.radiusMd),
        boxShadow: ScaffoldElevation.card,
      ),
      // Two rows, not two columns. The icon and the title are one statement -
      // what happened - so they share a line; the message is explanation and
      // gets the full width under it. Side by side, a 20px icon sat against a
      // two-line column with dead space beneath it, and the message lost ~32px
      // of width it needs more on a phone than the indent was buying.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // The icon is the only thing carrying the status. No leading
              // edge: two coloured objects saying the same thing is one too
              // many, and the glyph distinguishes the three kinds by shape
              // rather than by colour, which is what keeps 1.4.1 satisfied.
              Icon(icon, color: accent, size: 20),
              SizedBox(width: dimens.space3),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _DismissButton(onDismiss: onDismiss, palette: palette),
            ],
          ),
          SizedBox(height: dimens.space2),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  final ScaffoldPalette palette;

  const _DismissButton({required this.onDismiss, required this.palette});

  @override
  Widget build(BuildContext context) {
    // 44pt, matching the accessibility floor for a tap target. The swipe is
    // the primary dismissal on a phone — the top of the screen is out of
    // thumb reach — but this has to be reachable too.
    //
    // The 18px glyph therefore sits ~13px inside its own box and ~25px from
    // the card edge. Pulling it flush would need a negative margin, which
    // Container turns into a Padding and asserts on — the target keeps its
    // size instead.
    return IconButton(
      onPressed: onDismiss,
      icon: const Icon(Icons.close),
      iconSize: 18,
      color: palette.textSecondary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      tooltip: 'Dismiss',
    );
  }
}
