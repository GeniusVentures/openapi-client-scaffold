// WalletConnectSheet demo (Phase 7 — Media & Integration Widgets).
//
// Exercises both presentation states of WalletConnectSheet:
//   - disconnected: QR placeholder via a consumer-supplied qrBuilder (D-05)
//     plus an optional Connect CTA wired to a stub callback.
//   - connected:    wallet address (truncated via TextOverflow.ellipsis),
//     a network chip (ScaffoldBadge text variant), and a Disconnect footer
//     button that pops the sheet.
//
// To wire into the example app, add an entry to example/lib/main.dart's
// HomePage list:
//
//   _DemoTile(
//     title: 'WalletConnectSheet',
//     subtitle: 'Reown session sheet — disconnected + connected states',
//     builder: (_) => const WalletConnectSheetDemo(),
//   ),
//
// and `import 'demos/wallet_connect_sheet_demo.dart';` at the top of main.dart.
import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/wallet_connect_sheet.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Demo that triggers the WalletConnectSheet in disconnected and connected
/// states.
class WalletConnectSheetDemo extends StatelessWidget {
  const WalletConnectSheetDemo({super.key});

  void _showDisconnected(BuildContext context) {
    WalletConnectSheet.show<void>(
      context: context,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:demo@2?relay-protocol=irn&symKey=demo',
      qrBuilder: (BuildContext ctx, String uri) => Container(
        width: 200,
        height: 200,
        color: Colors.black12,
        child: Center(
          child: Text(
            'QR placeholder\n$uri',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      onConnect: () => Navigator.of(context).pop(),
    );
  }

  void _showConnected(BuildContext context) {
    WalletConnectSheet.show<void>(
      context: context,
      sessionState: WalletConnectSessionState.connected,
      address: '0xABCDEF1234567890abcdef1234567890ABCDEF12',
      networkName: 'Ethereum',
      onDisconnect: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WalletConnectSheet')),
      body: Padding(
        padding: EdgeInsets.all(context.dimens.itemSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WalletConnectSheet presents a Reown WalletConnect session '
              'state inside a ResponsiveDrawer. Disconnected shows a '
              'consumer-supplied QR builder; connected shows the address, '
              'network chip, and a Disconnect action.',
            ),
            SizedBox(height: context.dimens.itemSpacing),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDisconnected(context),
                    child: const Text('Show disconnected sheet'),
                  ),
                ),
                SizedBox(width: context.dimens.itemSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showConnected(context),
                    child: const Text('Show connected sheet'),
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
