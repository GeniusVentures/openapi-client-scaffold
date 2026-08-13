/// ScaffoldCard -- M3 card with configurable variant and content slots.
///
/// Generated from card.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card.dart.jinja2
/// Generator version: 0.4.0
/// Composes ScaffoldSurface + ScaffoldPressable for elevated, outlined, or
/// filled variants with optional header, body, and actions slots.
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
/// Consumes ScaffoldCardCubit (hydrated_bloc).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';


import 'scaffold_card_cubit.dart';
import 'scaffold_card_state.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// A Material 3 card with configurable variant and content slots.
///
/// The variant selects the surface treatment: elevated (ScaffoldSurface
/// elevation 4 + palette.deepBlueCardColor), outlined (elevation 0 + 1px
/// palette.borderSubtle border), or filled (elevation 0 +
/// palette.surfaceElevated). It is owned by the cubit state
/// ([ScaffoldCardState.cardVariant]) so a hydrated selection
/// survives reloads; the [variant] parameter seeds that state.
///
/// [header], [body], and [actions] are optional [Widget] slots passed
/// by the caller. When a slot is null, it is omitted from the layout.
/// When [onTap] is non-null the card is wrapped in a [ScaffoldPressable];
/// when [disabled] is true a [ScaffoldDisabledOverlay] blocks interaction.
class ScaffoldCard extends StatelessWidget {
  /// Creates a [ScaffoldCard].
  const ScaffoldCard({
    this.instanceId = '',
    this.variant = 'elevated',
    this.header,
    this.body,
    this.actions,
    this.onTap,
    this.disabled = false,
    super.key,
  });

  /// Multi-instance hydration discriminator forwarded to the Cubit.
  ///
  /// Hydrated cubits sharing a [storagePrefix] disambiguate by this id;
  /// leave empty for a single (default) instance.
  final String instanceId;

  /// Initial card variant: 'elevated', 'outlined', or 'filled'.
  final String variant;

  /// Optional header widget (e.g. title row, subtitle, leading icon).
  final Widget? header;

  /// Optional body widget (e.g. text content, image, form fields).
  final Widget? body;

  /// Optional actions widget (e.g. a [Row] of buttons).
  final Widget? actions;

  /// When non-null, wraps the card in a [ScaffoldPressable].
  final VoidCallback? onTap;

  /// When true, blocks interaction via [ScaffoldDisabledOverlay].
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScaffoldCardCubit>(
      create: (_) => ScaffoldCardCubit(
        instanceId: instanceId,
        initialVariant: variant,
      ),
      child: BlocBuilder<ScaffoldCardCubit, ScaffoldCardState>(
        builder: (context, state) {
          final palette = context.palette;
          final dimens = context.dimens;
          final textTheme = Theme.of(context).textTheme;

          final BorderRadiusGeometry radius =
              BorderRadius.circular(dimens.borderRadiusCard);

          // Build the card interior — header / body / actions slots.
          final List<Widget> slotChildren = <Widget>[];

          // --- Header slot ---
          if (header != null) {
            slotChildren.add(header!);
            if (body != null || actions != null) {
              slotChildren.add(SizedBox(height: dimens.space8));
            }
          }

          // --- Body slot ---
          if (body != null) {
            slotChildren.add(body!);
            if (actions != null) {
              slotChildren.add(SizedBox(height: dimens.space8));
            }
          }

          // --- Actions slot ---
          if (actions != null) {
            slotChildren.add(
              Align(
                alignment: Alignment.centerRight,
                child: actions!,
              ),
            );
          }

          // Fallback: empty card renders a minimum-height placeholder.
          if (slotChildren.isEmpty) {
            slotChildren.add(
              SizedBox(
                height: dimens.minTouchTarget,
                child: Center(
                  child: Text(
                    'No content',
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }

          final Widget cardChild = Padding(
            padding: EdgeInsets.all(dimens.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: slotChildren,
            ),
          );

          // --- Select variant (state-driven; hydrated selection wins) ---
          final Widget surface;
          switch (state.cardVariant) {
            case 'outlined':
              surface = ScaffoldSurface(
                color: Colors.transparent,
                border: Border.all(color: palette.borderSubtle, width: 1),
                elevation: 0,
                borderRadius: radius,
                child: cardChild,
              );
              break;
            case 'filled':
              surface = ScaffoldSurface(
                color: palette.surfaceElevated,
                elevation: 0,
                borderRadius: radius,
                child: cardChild,
              );
              break;
            case 'elevated':
            default:
              // Elevated cards use a subtle elevation of 4 dp.
              surface = ScaffoldSurface(
                color: palette.deepBlueCardColor,
                elevation: 4,
                borderRadius: radius,
                child: cardChild,
              );
              break;
          }

          if (onTap != null) {
            return ScaffoldPressable(
              onPressed: onTap,
              disabled: disabled,
              child: surface,
            );
          }
          if (disabled) {
            return ScaffoldDisabledOverlay(disabled: true, child: surface);
          }
          return surface;
        },
      ),
    );
  }
}
