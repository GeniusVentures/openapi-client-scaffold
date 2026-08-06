import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Demonstrates the ToastManager + the CR-02..04 lifecycle fixes.
///
/// Two counters track onClose invocations:
///  - manual: increments when the user taps the toast's close icon
///  - auto: increments when the auto-dismiss timer fires
///
/// Each counter is wired to its own showToast call so a mismatch between
/// the count shown and the number of toasts triggered reveals a double-fire
/// or missing-fire bug.
class ToastDemo extends StatefulWidget {
  const ToastDemo({super.key});

  @override
  State<ToastDemo> createState() => _ToastDemoState();
}

class _ToastDemoState extends State<ToastDemo> {
  int _manualCloseCount = 0;
  int _autoCloseCount = 0;
  int _manualShowCount = 0;
  int _autoShowCount = 0;

  void _showManual(ToastType type) {
    setState(() => _manualShowCount++);
    ToastManager().showToast(
      context: context,
      title: '${type.name} (manual)',
      message:
          'Tap the X to dismiss. onClose counter should increment by exactly 1.',
      type: type,
      // Long enough that the user can manually dismiss before auto fires.
      duration: const Duration(minutes: 5),
      onClose: () => setState(() => _manualCloseCount++),
    );
  }

  void _showAuto(ToastType type) {
    setState(() => _autoShowCount++);
    ToastManager().showToast(
      context: context,
      title: '${type.name} (auto)',
      message: 'Auto-dismiss in 2s. onClose counter should increment by 1.',
      type: type,
      duration: const Duration(seconds: 2),
      onClose: () => setState(() => _autoCloseCount++),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toast')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual: shown=$_manualShowCount closed=$_manualCloseCount'),
            Text('Auto:   shown=$_autoShowCount closed=$_autoCloseCount'),
            SizedBox(height: context.dimens.itemSpacing),
            const Text('Manual-dismiss toasts (5min duration; tap X):'),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _showManual(ToastType.success),
                  child: const Text('success'),
                ),
                ElevatedButton(
                  onPressed: () => _showManual(ToastType.error),
                  child: const Text('error'),
                ),
                ElevatedButton(
                  onPressed: () => _showManual(ToastType.warning),
                  child: const Text('warning'),
                ),
              ],
            ),
            SizedBox(height: context.dimens.itemSpacing),
            const Text('Auto-dismiss toasts (2s duration):'),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _showAuto(ToastType.success),
                  child: const Text('success'),
                ),
                ElevatedButton(
                  onPressed: () => _showAuto(ToastType.error),
                  child: const Text('error'),
                ),
                ElevatedButton(
                  onPressed: () => _showAuto(ToastType.warning),
                  child: const Text('warning'),
                ),
              ],
            ),
            SizedBox(height: context.dimens.itemSpacing),
            ElevatedButton(
              onPressed: () => ToastManager().dispose(),
              child: const Text('dispose all (CR-04 path)'),
            ),
          ],
        ),
      ),
    );
  }
}
