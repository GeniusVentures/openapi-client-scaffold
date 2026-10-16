import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class ActionButtonDemo extends StatelessWidget {
  const ActionButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ActionButton')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ActionButton needs bounded width — each is wrapped '
                'in a SizedBox to give the internal LayoutBuilder real '
                'constraints.',
                style: TextStyle(color: context.palette.textPrimary)),
            SizedBox(height: context.dimens.itemSpacing),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: ActionButton(
                    icon: Icons.add,
                    text: 'Enabled',
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: context.dimens.itemSpacing),
                const SizedBox(
                  width: 120,
                  child: ActionButton(
                    icon: Icons.block,
                    text: 'Disabled',
                    onPressed: null,
                  ),
                ),
                SizedBox(width: context.dimens.itemSpacing),
                SizedBox(
                  width: 120,
                  child: ActionButton(
                    icon: Icons.refresh,
                    text: 'Rotating',
                    onPressed: () {},
                    animation: ActionButtonAnimation.rotate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
