import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Thin end-to-end slice of the Core UI Foundation.
///
/// Proves the architectural pattern end-to-end:
///   ScaffoldMotion -> ScaffoldSurface -> ScaffoldTouchTarget ->
///   ScaffoldFocusOutline
///
/// The reduced-motion Switch drives [ScaffoldMotion.reducedMotion]; tapping the
/// surface requests focus so the focus ring appears on keyboard navigation or
/// screen-reader (accessibleNavigation) mode.
class TracerDemo extends StatefulWidget {
  const TracerDemo({super.key});

  @override
  State<TracerDemo> createState() => _TracerDemoState();
}

class _TracerDemoState extends State<TracerDemo> {
  bool _reducedMotion = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return Scaffold(
      appBar: AppBar(title: const Text('Tracer — Core UI Foundation')),
      body: ScaffoldMotion(
        reducedMotion: _reducedMotion,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Reduced motion'),
              subtitle: Text(
                'ScaffoldMotion.of(context).reducedMotion = $_reducedMotion',
              ),
              value: _reducedMotion,
              onChanged: (value) => setState(() => _reducedMotion = value),
            ),
            Padding(
              padding: EdgeInsets.all(dimens.space8),
              child: ScaffoldSurface(
                padding: EdgeInsets.all(dimens.space8),
                child: ScaffoldTouchTarget(
                  child: ScaffoldFocusOutline(
                    focusNode: _focusNode,
                    child: GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Focus me'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
