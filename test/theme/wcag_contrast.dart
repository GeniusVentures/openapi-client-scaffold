import 'package:flutter/painting.dart';

/// WCAG 1.4.3 minimum contrast for text.
const double kWcagText = 4.5;

/// WCAG 1.4.11 minimum contrast for non-text UI components and graphics.
const double kWcagNonText = 3.0;

/// Contrast ratio of [foreground] over [background]. A translucent foreground
/// is composited onto the background first. The background must be opaque.
double contrastRatio(Color foreground, Color background) {
  assert(
    background.a == 1.0,
    'background must be an opaque surface, got ${argbHex(background)}',
  );
  final composited = Color.alphaBlend(foreground, background);
  final a = composited.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

/// 8-digit ARGB hex, for failure messages.
String argbHex(Color color) =>
    '0x${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';
