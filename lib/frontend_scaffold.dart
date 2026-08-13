/// Frontend Scaffold — Shared scaffolding library.
///
/// Barrel export for generic bloc widgets,
/// theme primitives, and breakpoint utilities. Consumed by Flutter
/// apps via path/git dependency.
///
/// Theme tokens are exposed as Material 3 [ThemeExtension]s
/// ([ScaffoldPalette] and [ScaffoldDimens]). Host apps override them via
/// `ThemeData.extensions` (see [scaffoldThemeExtensions]); widgets fall back
/// to the default palette/dimens when no extension is registered.
library frontend_scaffold;

export 'components/action_button.dart';
export 'components/app_screen_view.dart';
export 'components/scaffold_animated_display_bounce.dart';
export 'components/scaffold_animated_display_fade.dart';
export 'components/scaffold_animated_display_pulse.dart';
export 'components/scaffold_animated_display_rotate.dart';
export 'components/scaffold_animated_display_scale.dart';
export 'components/scaffold_animated_display_shake.dart';
export 'components/scaffold_animated_display_slide.dart';
export 'components/scaffold_badge.dart';
export 'components/scaffold_color_swatch.dart';
export 'components/scaffold_disabled_overlay.dart';
export 'components/scaffold_drag_handle.dart';
export 'components/scaffold_focus_outline.dart';
export 'components/scaffold_formatted_value_date.dart';
export 'components/scaffold_formatted_value_duration.dart';
export 'components/scaffold_formatted_value_money.dart';
export 'components/scaffold_formatted_value_number.dart';
export 'components/scaffold_formatted_value_percentage.dart';
export 'components/scaffold_formatted_value_time.dart';
export 'components/scaffold_image_placeholder_empty.dart';
export 'components/scaffold_image_placeholder_failed.dart';
export 'components/scaffold_image_placeholder_loading.dart';
export 'components/scaffold_image_placeholder_missing.dart';
export 'components/scaffold_live_region.dart';
export 'components/scaffold_motion.dart';
export 'components/scaffold_overflow_fade.dart';
export 'components/scaffold_pressable.dart';
export 'components/scaffold_resize_handle.dart';
export 'components/scaffold_responsive_visibility.dart';
export 'components/scaffold_scroll_edge_indicator.dart';
export 'components/scaffold_selection_indicator_checkbox.dart';
export 'components/scaffold_selection_indicator_radio.dart';
export 'components/scaffold_selection_indicator_toggle.dart';
export 'components/scaffold_skeleton.dart';
export 'components/scaffold_status_indicator.dart';
export 'components/scaffold_surface.dart';
export 'components/scaffold_touch_target.dart';
export 'components/desktop_body_container.dart';
export 'components/responsive_grid.dart';
export 'components/sliding_drawer_button.dart';
export 'components/string_button.dart';
export 'components/text_entry_field_widget.dart';
export 'components/text_form_field_logic.dart';
export 'components/animation/checkmark_animation.dart';
export 'components/animation/x_animation.dart';
export 'components/bottom_drawer/bottom_drawer.dart';
export 'components/bottom_drawer/responsive_drawer.dart';
export 'components/loading/loading.dart';
export 'components/toast/toast_manager.dart';
export 'components/toast/toast_navigator_observer.dart';
export 'components/toast/toast_widget.dart';
export 'theme/scaffold_colors.dart';
export 'theme/scaffold_dimens.dart';
export 'theme/scaffold_elevation.dart';
export 'theme/scaffold_palette.dart';
export 'theme/scaffold_theme.dart';
export 'utils/breakpoints.dart';
