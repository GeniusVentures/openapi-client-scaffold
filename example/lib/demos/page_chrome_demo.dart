import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class PageChromeDemo extends StatelessWidget {
  const PageChromeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AppScreenView / DesktopBodyContainer')),
      body: AppScreenView(
        body: Center(
          child: DesktopBodyContainer(
            title: 'DesktopBodyContainer',
            subText: 'Page chrome used by desktop flows',
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Body content'),
            ),
          ),
        ),
        footer: const Padding(
          padding: EdgeInsets.all(8),
          child: Text('AppScreenView footer'),
        ),
      ),
    );
  }
}
