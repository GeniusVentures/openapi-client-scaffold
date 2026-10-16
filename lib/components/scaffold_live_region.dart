import 'package:flutter/material.dart';

/// Zero-size screen-reader announcement region.
///
/// Wraps [Semantics] with `liveRegion: true` so assistive technologies
/// announce when [label] or [value] change. Renders [child] (or a zero-size
/// box when no child is supplied) without adding any visual content. Atoms
/// that report changing values (formatted values, numeric inputs, status
/// indicators) wrap their output in this to follow the toast announcement
/// pattern.
class ScaffoldLiveRegion extends StatelessWidget {
  const ScaffoldLiveRegion({super.key, this.label, this.value, this.child});

  /// Accessible label announced when it changes.
  final String? label;

  /// Accessible value announced when it changes.
  final String? value;

  /// Optional content rendered beneath the live region.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      value: value,
      // Do NOT merge descendants into this node. The default (merge) hides
      // the child's own Semantics labels — when a labelled region wraps an
      // interactive subtree (e.g. the chart scrubber's 'Chart scrubber' +
      // 'Chart' labels), the merged node swallows them and a11y consumers
      // (and tests) can no longer find the child's labels.
      explicitChildNodes: true,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
