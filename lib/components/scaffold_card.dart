/// ScaffoldCard -- M3 card with configurable variant and content slots.
///
/// Generated from card.dart.jinja2 -- do not edit by hand.
/// Source schema: templates/components/card.dart.jinja2
/// Generator version: 0.4.0
/// Composes ScaffoldSurface + ScaffoldPressable for elevated, outlined, or
/// filled variants with optional header, body, and actions slots.
/// Standalone widget consuming Theme.of(context) via context.palette/dimens;
/// no Riverpod or GeniusTheme dependency.
/// Consumes ScaffoldCardCubit (in-memory).
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
/// ([ScaffoldCardState.cardVariant]); the [variant] parameter
/// seeds that state.
///
/// [header], [body], and [actions] are optional [Widget] slots passed
/// by the caller. When a slot is null, it is omitted from the layout.
/// When [onTap] is non-null the card is wrapped in a [ScaffoldPressable];
/// when [disabled] is true a [ScaffoldDisabledOverlay] blocks interaction.
///
/// A parent can supply its own [cubit] to drive the card (e.g. to select a
/// variant live); when [cubit] is null the widget owns an internal cubit
/// seeded from [variant] and re-seeds it when [variant] or [instanceId]
/// change.
class ScaffoldCard extends StatefulWidget {
  /// Creates a [ScaffoldCard].
  const ScaffoldCard({
    this.instanceId = '',
    this.variant = 'elevated',
    this.header,
    this.body,
    this.actions,
    this.onTap,
    this.disabled = false,
    this.cubit,
    super.key,
  });

  /// Optional instance discriminator forwarded to the Cubit.
  ///
  /// Changing it re-seeds the internal cubit; leave empty for a single
  /// (default) instance.
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

  /// Optional cubit owned by the parent. When supplied, the parent drives the
  /// card's variant; when null, the widget owns an internal cubit seeded from
  /// [variant].
  final ScaffoldCardCubit? cubit;

  @override
  State<ScaffoldCard> createState() => _ScaffoldCardState();
}

class _ScaffoldCardState extends State<ScaffoldCard> {
  late ScaffoldCardCubit _cubit;
  late bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit = widget.cubit ??
        ScaffoldCardCubit(
          instanceId: widget.instanceId,
          initialVariant: widget.variant,
        );
  }

  @override
  void didUpdateWidget(ScaffoldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool seedChanged = widget.instanceId != oldWidget.instanceId ||
        widget.variant != oldWidget.variant;
    if (widget.cubit != oldWidget.cubit || (_ownsCubit && seedChanged)) {
      if (_ownsCubit) {
        _cubit.close();
      }
      _ownsCubit = widget.cubit == null;
      _cubit = widget.cubit ??
          ScaffoldCardCubit(
            instanceId: widget.instanceId,
            initialVariant: widget.variant,
          );
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScaffoldCardCubit>.value(
      value: _cubit,
      child: BlocBuilder<ScaffoldCardCubit, ScaffoldCardState>(
        builder: (context, state) {
          final palette = context.palette;
          final dimens = context.dimens;

          final BorderRadiusGeometry radius =
              BorderRadius.circular(dimens.borderRadiusCard);

          // Build the card interior — header / body / actions slots.
          final List<Widget> slotChildren = <Widget>[];

          // --- Header slot ---
          if (widget.header != null) {
            slotChildren.add(widget.header!);
            if (widget.body != null || widget.actions != null) {
              slotChildren.add(SizedBox(height: dimens.space8));
            }
          }

          // --- Body slot ---
          if (widget.body != null) {
            slotChildren.add(widget.body!);
            if (widget.actions != null) {
              slotChildren.add(SizedBox(height: dimens.space8));
            }
          }

          // --- Actions slot ---
          if (widget.actions != null) {
            slotChildren.add(
              Align(
                alignment: Alignment.centerRight,
                child: widget.actions!,
              ),
            );
          }

          // Fallback: empty card renders a minimum-height placeholder (no
          // hardcoded copy — consumer copy lives in the slots).
          if (slotChildren.isEmpty) {
            slotChildren.add(SizedBox(height: dimens.minTouchTarget));
          }

          final Widget cardChild = Padding(
            padding: EdgeInsets.all(dimens.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: slotChildren,
            ),
          );

          // --- Select variant (state-driven) ---
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

          if (widget.onTap != null) {
            return ScaffoldPressable(
              onPressed: widget.onTap,
              disabled: widget.disabled,
              child: surface,
            );
          }
          if (widget.disabled) {
            return ScaffoldDisabledOverlay(disabled: true, child: surface);
          }
          return surface;
        },
      ),
    );
  }
}
