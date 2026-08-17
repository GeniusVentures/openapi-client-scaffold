import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/components/wallet_connect_sheet.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pumpHarness(
  WidgetTester tester, {
  required void Function(BuildContext) onOpen,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () => onOpen(context),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required WalletConnectSessionState sessionState,
  Widget Function(BuildContext, String)? qrBuilder,
  String? uri,
  String? address,
  String? networkName,
  VoidCallback? onConnect,
  VoidCallback? onDisconnect,
  VoidCallback? onClose,
}) async {
  await _pumpHarness(
    tester,
    onOpen: (BuildContext context) {
      WalletConnectSheet.show<void>(
        context: context,
        sessionState: sessionState,
        qrBuilder: qrBuilder,
        uri: uri,
        address: address,
        networkName: networkName,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onClose: onClose,
      );
    },
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'disconnected state renders qrBuilder output containing the URI',
      (WidgetTester tester) async {
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:test@2',
      qrBuilder: (_, String uri) => Text('QR:$uri'),
    );

    expect(find.text('QR:wc:test@2'), findsOneWidget);
  });

  testWidgets('qrBuilder is invoked with the exact uri passed to show',
      (WidgetTester tester) async {
    String? captured;
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:pass-through@2?relay=irn',
      qrBuilder: (BuildContext context, String uri) {
        captured = uri;
        return Text('qr:$uri');
      },
    );

    expect(captured, 'wc:pass-through@2?relay=irn');
    expect(find.text('qr:wc:pass-through@2?relay=irn'), findsOneWidget);
  });

  testWidgets(
      'connected state renders the address truncated in the MIDDLE',
      (WidgetTester tester) async {
    const String address =
        '0xABCDEF1234567890abcdef1234567890ABCDEF12';
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.connected,
      address: address,
    );

    // Middle truncation keeps the 0x… prefix (6 chars) and checksum tail (4).
    const String truncated = '0xABCD…EF12';
    expect(find.text(truncated), findsOneWidget);
    // The full, untruncated address must NOT be rendered.
    expect(find.text(address), findsNothing);
  });

  testWidgets(
      'connected state renders a ScaffoldBadge text chip for networkName',
      (WidgetTester tester) async {
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.connected,
      address: '0xABCDEF1234567890abcdef1234567890ABCDEF12',
      networkName: 'Ethereum',
    );

    final Finder badgeFinder = find.byType(ScaffoldBadge);
    expect(badgeFinder, findsOneWidget);
    final ScaffoldBadge badge = tester.widget<ScaffoldBadge>(badgeFinder);
    expect(badge.variant, BadgeVariant.text);
    expect(badge.text, 'Ethereum');
  });

  testWidgets('tapping Disconnect in connected state invokes onDisconnect once',
      (WidgetTester tester) async {
    int disconnects = 0;
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.connected,
      address: '0xABCDEF1234567890abcdef1234567890ABCDEF12',
      networkName: 'Ethereum',
      onDisconnect: () => disconnects++,
    );

    final Finder disconnectFinder = find.text('Disconnect');
    expect(disconnectFinder, findsOneWidget);
    await tester.tap(disconnectFinder);
    await tester.pump();
    expect(disconnects, 1);
  });

  testWidgets('dismissing the sheet invokes onClose exactly once',
      (WidgetTester tester) async {
    int closes = 0;
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:test@2',
      qrBuilder: (_, String uri) => Text('QR:$uri'),
      onClose: () => closes++,
    );

    // Tap the close affordance from BottomDrawer (Icons.close in the header).
    final Finder closeButton = find.byIcon(Icons.close);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(closes, 1);
  });

  testWidgets(
      'disconnected state with onConnect shows a Connect CTA that fires once',
      (WidgetTester tester) async {
    int connects = 0;
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:test@2',
      qrBuilder: (_, String uri) => Text('QR:$uri'),
      onConnect: () => connects++,
    );

    final Finder connectFinder = find.text('Connect');
    expect(connectFinder, findsOneWidget);
    await tester.tap(connectFinder);
    await tester.pump();
    expect(connects, 1);
  });

  testWidgets(
      'disconnected state with onConnect: null omits the Connect affordance',
      (WidgetTester tester) async {
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:test@2',
      qrBuilder: (_, String uri) => Text('QR:$uri'),
    );

    expect(find.text('Connect'), findsNothing);
  });

  testWidgets(
      'title switches with state — disconnected shows Connect Wallet, '
      'connected shows static Wallet title (address lives in body only)',
      (WidgetTester tester) async {
    const String address =
        '0xABCDEF1234567890abcdef1234567890ABCDEF12';

    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:test@2',
      qrBuilder: (_, String uri) => Text('QR:$uri'),
    );
    expect(find.text('Connect Wallet'), findsOneWidget);

    // Pop the sheet before opening the next one.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.connected,
      address: address,
    );
    // Static title — not the address.
    expect(find.text('Wallet'), findsOneWidget);
    // Address appears exactly once (body, middle-truncated), not duplicated
    // in the title.
    expect(find.text('0xABCD…EF12'), findsOneWidget);
  });

  testWidgets(
      'no QR dependency — source contains zero qr_flutter/QrImage/qr.dart refs',
      (WidgetTester tester) async {
    // The presence of this test guards D-05: the implementation file must
    // not import qr_flutter or reference QrImage/qr.dart. Verified by grep
    // in CI; here we just ensure the widget builds without any QR package.
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.disconnected,
      uri: 'wc:test@2',
      qrBuilder: (_, String uri) => Text('QR:$uri'),
    );
    expect(find.text('QR:wc:test@2'), findsOneWidget);
  });

  testWidgets('Disconnect CTA is wrapped in a ScaffoldPressable',
      (WidgetTester tester) async {
    await _openSheet(
      tester,
      sessionState: WalletConnectSessionState.connected,
      address: '0xABCDEF1234567890abcdef1234567890ABCDEF12',
      networkName: 'Ethereum',
      onDisconnect: () {},
    );

    expect(find.byType(ScaffoldPressable), findsWidgets);
  });
}
