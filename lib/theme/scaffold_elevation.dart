import 'package:flutter/material.dart';

/// Elevation constants for frontend_scaffold surfaces, kept for compatibility.
///
/// Widgets read their shadows through `context.shadows` ([ScaffoldShadows]),
/// which host apps can override. `ScaffoldShadows.defaultShadows.card` equals
/// [card].
class ScaffoldElevation {
  ScaffoldElevation._();

  /// Shadow used under toasts and other transient elevated surfaces
  /// (black @ 35%).
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
