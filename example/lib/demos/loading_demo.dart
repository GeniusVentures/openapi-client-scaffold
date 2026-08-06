import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class LoadingDemo extends StatelessWidget {
  const LoadingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default palette dots:'),
            SizedBox(height: context.dimens.itemSpacing),
            const Loading(text: 'Loading default'),
            SizedBox(height: context.dimens.itemSpacing * 2),
            const Text('Custom dot colors:'),
            SizedBox(height: context.dimens.itemSpacing),
            const Loading(
              text: 'Loading custom',
              leftDotColor: Colors.purple,
              rightDotColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}
