import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class StringButtonDemo extends StatefulWidget {
  const StringButtonDemo({super.key});

  @override
  State<StringButtonDemo> createState() => _StringButtonDemoState();
}

class _StringButtonDemoState extends State<StringButtonDemo> {
  String _buffer = '';

  void _append(String value) {
    setState(() => _buffer = _buffer + value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StringButton')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buffer: $_buffer',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: context.dimens.itemSpacing),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final digit in ['1', '2', '3', '4', '5', '6'])
                  StringButton(
                    value: digit,
                    onPressed: _append,
                    color: context.palette.deepBlueCardColor,
                  ),
                StringButton(
                  value: 'CLR',
                  onPressed: (_) => setState(() => _buffer = ''),
                  color: context.palette.deepBlueCardColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
