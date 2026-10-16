import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class BottomDrawerDemo extends StatelessWidget {
  const BottomDrawerDemo({super.key});

  static const String drawerTitle = 'Drawer demo';

  static List<Widget> drawerItems(BuildContext context) {
    final Color color = context.palette.textPrimary;
    return [
      SlidingDrawerButton(
        label: 'First item',
        icon: Icons.star,
        color: color,
        onPressed: () => Navigator.of(context).pop(),
      ),
      SlidingDrawerButton(
        label: 'Second item',
        icon: Icons.settings,
        color: color,
        onPressed: () => Navigator.of(context).pop(),
      ),
      SlidingDrawerButton(
        label: 'Third item (no icon)',
        color: color,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  static Widget drawerFooter(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Close'),
    );
  }

  void _open(BuildContext context) {
    ResponsiveDrawer.show<void>(
      context: context,
      title: drawerTitle,
      children: drawerItems(context),
      footer: drawerFooter(context),
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
            Text(
              'ResponsiveDrawer picks modal bottom sheet on narrow screens '
              'and a right-side dialog on wide screens. Resize the window '
              'to see the switch (breakpoint: 800px).',
              style: TextStyle(color: context.palette.textPrimary),
            ),
            SizedBox(height: context.dimens.itemSpacing),
            ElevatedButton(
              onPressed: () => _open(context),
              child: const Text('Open ResponsiveDrawer'),
            ),
          ],
        ),
      ),
    );
  }
}
