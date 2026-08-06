import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class BottomDrawerDemo extends StatelessWidget {
  const BottomDrawerDemo({super.key});

  void _open(BuildContext context, {required String title}) {
    ResponsiveDrawer.show<void>(
      context: context,
      title: title,
      children: [
        SlidingDrawerButton(
          label: 'First item',
          icon: Icons.star,
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SlidingDrawerButton(
          label: 'Second item',
          icon: Icons.settings,
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SlidingDrawerButton(
          label: 'Third item (no icon)',
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      footer: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BottomDrawer / ResponsiveDrawer')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ResponsiveDrawer picks modal bottom sheet on narrow screens '
              'and a right-side dialog on wide screens. Resize the window '
              'to see the switch (breakpoint: 800px).',
            ),
            SizedBox(height: context.dimens.itemSpacing),
            ElevatedButton(
              onPressed: () => _open(context, title: 'Drawer demo'),
              child: const Text('Open ResponsiveDrawer'),
            ),
          ],
        ),
      ),
    );
  }
}
