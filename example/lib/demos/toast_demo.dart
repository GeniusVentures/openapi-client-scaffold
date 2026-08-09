import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Demonstrates the two toast densities and the CR-02..04 lifecycle fixes.
///
/// Density is chosen by whether a title is supplied:
///  - compact (no title): a receipt — "Link copied". Auto-dismiss only.
///  - card (title): an alert — titled, 44pt dismiss button, longer read.
///
/// Two counters track onClose invocations:
///  - manual: increments when the user taps the card's close button
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

  /// Card density, long duration so the user dismisses it by hand — the
  /// onClose counter must increment by exactly 1 (CR-03: no double-fire
  /// from a stale auto-dismiss timer).
  void _showManualCard(ToastType type) {
    setState(() => _manualShowCount++);
    showToast(
      context,
      'Tap the X to dismiss. onClose counter should increment by exactly 1.',
      title: '${type.name} (manual)',
      type: type,
      // Long enough that the user can manually dismiss before auto fires.
      duration: const Duration(minutes: 5),
      onClose: () => setState(() => _manualCloseCount++),
    );
  }

  /// Compact density, short duration — the timer fires onClose exactly once
  /// (CR-02: timer is bound to the toast's element, cancelled on teardown).
  void _showAutoCompact(String message) {
    setState(() => _autoShowCount++);
    showToast(
      context,
      message,
      duration: const Duration(seconds: 2),
      onClose: () => setState(() => _autoCloseCount++),
    );
  }

  /// Card density, short duration.
  void _showAutoCard(ToastType type) {
    setState(() => _autoShowCount++);
    showToast(
      context,
      'Auto-dismiss in 2s. onClose counter should increment by 1.',
      title: '${type.name} (auto)',
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
        child: ListView(
          children: [
            Text('Manual: shown=$_manualShowCount closed=$_manualCloseCount'),
            Text('Auto:   shown=$_autoShowCount closed=$_autoCloseCount'),
            SizedBox(height: context.dimens.itemSpacing),
            const Text('Compact receipts (no title; auto-dismiss only):'),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _showAutoCompact('Link copied'),
                  child: const Text('Link copied'),
                ),
                ElevatedButton(
                  onPressed: () => _showAutoCompact('Address saved'),
                  child: const Text('Address saved'),
                ),
                ElevatedButton(
                  onPressed: () => _showAutoCompact('Transaction submitted'),
                  child: const Text('Transaction submitted'),
                ),
              ],
            ),
            SizedBox(height: context.dimens.itemSpacing),
            const Text('Card alerts, manual-dismiss (5min duration; tap X):'),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _showManualCard(ToastType.success),
                  child: const Text('success'),
                ),
                ElevatedButton(
                  onPressed: () => _showManualCard(ToastType.error),
                  child: const Text('error'),
                ),
                ElevatedButton(
                  onPressed: () => _showManualCard(ToastType.warning),
                  child: const Text('warning'),
                ),
              ],
            ),
            SizedBox(height: context.dimens.itemSpacing),
            const Text('Card alerts, auto-dismiss (2s duration):'),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _showAutoCard(ToastType.success),
                  child: const Text('success'),
                ),
                ElevatedButton(
                  onPressed: () => _showAutoCard(ToastType.error),
                  child: const Text('error'),
                ),
                ElevatedButton(
                  onPressed: () => _showAutoCard(ToastType.warning),
                  child: const Text('warning'),
                ),
              ],
            ),
            SizedBox(height: context.dimens.itemSpacing),
            ElevatedButton(
              onPressed: () => ToastManager.instance.disposeAll(),
              child: const Text('dispose all (CR-04 path)'),
            ),
          ],
        ),
      ),
    );
  }
}
