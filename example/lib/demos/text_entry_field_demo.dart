import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

class TextEntryFieldDemo extends StatefulWidget {
  const TextEntryFieldDemo({super.key});

  @override
  State<TextEntryFieldDemo> createState() => _TextEntryFieldDemoState();
}

class _TextEntryFieldDemoState extends State<TextEntryFieldDemo> {
  late final TextEditingController _nameController;
  late final TextEditingController _obscuredController;
  String _nameEcho = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _obscuredController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _obscuredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TextEntryFieldWidget')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (innerContext) => TextEntryFieldWidget(
                logic: TextFormFieldLogic(
                  innerContext,
                  controller: _nameController,
                  hintText: 'Enter a name',
                  onChanged: (value) => setState(() => _nameEcho = value),
                ),
              ),
            ),
            SizedBox(height: context.dimens.itemSpacing),
            Builder(
              builder: (innerContext) => TextEntryFieldWidget(
                logic: TextFormFieldLogic(
                  innerContext,
                  controller: _obscuredController,
                  hintText: 'Password (obscured)',
                  obscureText: true,
                ),
              ),
            ),
            SizedBox(height: context.dimens.itemSpacing),
            Text('Echo: $_nameEcho'),
          ],
        ),
      ),
    );
  }
}
