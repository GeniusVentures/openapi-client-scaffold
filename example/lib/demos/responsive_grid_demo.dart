import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class ResponsiveGridDemo extends StatelessWidget {
  const ResponsiveGridDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ResponsiveGrid')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Column count: <750w → 1, <1000w → 2, <1400w → 3, else 4. '
              'Resize the window to watch it adapt.',
            ),
            SizedBox(height: context.dimens.itemSpacing),
            ResponsiveGrid(
              children: [
                for (int i = 1; i <= 8; i++)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: context.palette.deepBlueCardColor,
                      borderRadius: BorderRadius.circular(
                        context.dimens.borderRadiusCard,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('Card $i'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
