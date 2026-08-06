import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class AnimationsDemo extends StatefulWidget {
  const AnimationsDemo({super.key});

  @override
  State<AnimationsDemo> createState() => _AnimationsDemoState();
}

class _AnimationsDemoState extends State<AnimationsDemo> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animations')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Both animations auto-run once on mount. The replay '
                'button rekeys the widgets to re-trigger.'),
            SizedBox(height: context.dimens.itemSpacing),
            Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CheckmarkAnimation(key: ValueKey(_tick)),
                    ),
                    const Text('CheckmarkAnimation'),
                  ],
                ),
                SizedBox(width: context.dimens.itemSpacing * 2),
                Column(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: XAnimation(key: ValueKey(_tick)),
                    ),
                    const Text('XAnimation'),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.dimens.itemSpacing),
            ElevatedButton(
              onPressed: () => setState(() => _tick++),
              child: const Text('Replay'),
            ),
          ],
        ),
      ),
    );
  }
}
