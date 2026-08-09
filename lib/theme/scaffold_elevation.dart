import 'package:flutter/material.dart';

/// Elevation tokens for frontend_scaffold surfaces. Dark-mode defaults;
/// host apps that need appearance-aware shadows can substitute their own
/// values.
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
