/// WalletConnectSheet — static show façade over ResponsiveDrawer for Reown
/// WalletConnect session state.
///
/// Presents three states:
///   - disconnected: consumer-supplied QR builder + optional Connect CTA
///   - connecting:   progress indicator + status text
///   - connected:    truncated wallet address + network chip + Disconnect CTA
///
/// D-05: the QR render is a consumer-supplied `qrBuilder` slot. Scaffold
/// gains NO QR dependency — third-party QR packages, custom painters, etc.
/// are the consumer's choice.
///
/// WIDG-31: session state is passed in externally; the sheet owns no Reown
/// session and never initiates one. The optional [onConnect] callback is
/// the consumer's hook to begin the Reown session.
///
/// The 800px desktop breakpoint is owned by ResponsiveDrawer — this file
/// never calls MediaQuery.
library;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/bottom_drawer/responsive_drawer.dart';
import 'package:frontend_scaffold/components/scaffold_badge.dart';
import 'package:frontend_scaffold/components/scaffold_pressable.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Session state for the WalletConnect sheet.
enum WalletConnectSessionState { disconnected, connecting, connected }

/// Static façade for presenting a Reown WalletConnect session sheet.
///
/// All inputs (session state, URI, address, network name, callbacks) are
/// caller-supplied. The sheet renders presentational UI only and does not
/// own, initiate, or persist any session state.
class WalletConnectSheet {
  const WalletConnectSheet._();

  /// Show the wallet-connect sheet.
  ///
  /// Delegates presentation to [ResponsiveDrawer.show] — desktop
  /// (>=800px) shows a right-anchored dialog, mobile shows a modal bottom
  /// sheet. The breakpoint is owned by ResponsiveDrawer.
  static Future<T?> show<T>({
    required BuildContext context,
    required WalletConnectSessionState sessionState,
    Widget Function(BuildContext context, String uri)? qrBuilder,
    String? uri,
    String? address,
    String? networkName,
    VoidCallback? onConnect,
    VoidCallback? onDisconnect,
    VoidCallback? onClose,
  }) {
    final String title = _titleFor(sessionState, address);
    final Widget? footer = _footerFor(sessionState, onDisconnect);

    // Build children lazily inside the modal route so they receive the
    // sheet's own BuildContext (not the caller's). This lets qrBuilder
    // call Navigator.of(sheetContext).pop() to dismiss the sheet, and
    // keeps Theme.of(sheetContext) reactive to theme changes while the
    // sheet is open.
    final List<Widget> children = <Widget>[
      Builder(
        builder: (BuildContext sheetContext) {
          final List<Widget> content = _childrenFor(
            sheetContext,
            sessionState: sessionState,
            qrBuilder: qrBuilder,
            uri: uri,
            address: address,
            networkName: networkName,
            onConnect: onConnect,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: content,
          );
        },
      ),
    ];

    return ResponsiveDrawer.show<T>(
      context: context,
      title: title,
      children: children,
      footer: footer,
      onClose: onClose,
    );
  }

  static String _titleFor(
    WalletConnectSessionState sessionState,
    String? address,
  ) {
    switch (sessionState) {
      case WalletConnectSessionState.disconnected:
      case WalletConnectSessionState.connecting:
        return 'Connect Wallet';
      case WalletConnectSessionState.connected:
        // Address is shown in the body; keep the title a static label so
        // the address is not duplicated visually.
        return 'Wallet';
    }
  }

  static List<Widget> _childrenFor(
    BuildContext context, {
    required WalletConnectSessionState sessionState,
    required Widget Function(BuildContext, String)? qrBuilder,
    required String? uri,
    required String? address,
    required String? networkName,
    required VoidCallback? onConnect,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final dimens = context.dimens;

    switch (sessionState) {
      case WalletConnectSessionState.disconnected:
        return <Widget>[
          if (qrBuilder != null && uri != null) qrBuilder(context, uri),
          if (onConnect != null)
            Padding(
              padding: EdgeInsets.only(top: dimens.space8),
              child: ScaffoldPressable(
                onPressed: onConnect,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimens.space8,
                    vertical: dimens.space4,
                  ),
                  child: Text(
                    'Connect',
                    style: textTheme.labelLarge?.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: dimens.space8),
            child: Text(
              'Scan the QR code with your wallet to connect.',
              style: textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ];
      case WalletConnectSessionState.connecting:
        return <Widget>[
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dimens.space12),
              child: const CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: dimens.space8),
            child: Text(
              'Awaiting wallet approval…',
              style: textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ];
      case WalletConnectSessionState.connected:
        return <Widget>[
          if (address != null)
            Text(
              // Wallet addresses are identified by BOTH their prefix (0x…)
              // and their checksum tail. End-ellipsis drops the tail, so
              // truncate in the middle instead: keep the leading and
              // trailing characters and elide the center.
              _truncateMiddle(address),
              maxLines: 1,
              style: textTheme.bodyLarge?.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          if (networkName != null)
            Padding(
              padding: EdgeInsets.only(top: dimens.space4),
              child: ScaffoldBadge(
                variant: BadgeVariant.text,
                text: networkName,
              ),
            ),
        ];
    }
  }

  /// Number of leading characters kept when middle-truncating an address.
  static const int _kAddressHeadLength = 6;

  /// Number of trailing characters kept when middle-truncating an address.
  static const int _kAddressTailLength = 4;

  /// Truncates [value] in the middle, keeping the leading
  /// [_kAddressHeadLength] and trailing [_kAddressTailLength] characters with
  /// a single-character ellipsis between them.
  ///
  /// Wallet addresses are long hex strings identified by both their `0x`
  /// prefix and their checksum tail. [TextOverflow.ellipsis] truncates at the
  /// END for LTR text, which drops the tail — so the connected-state address
  /// is pre-truncated in the middle instead. Short values (too short to
  /// truncate meaningfully) are returned unchanged.
  static String _truncateMiddle(String value) {
    const int kept = _kAddressHeadLength + _kAddressTailLength;
    // +1 for the ellipsis itself: only truncate when it actually shortens.
    if (value.length <= kept + 1) {
      return value;
    }
    return '${value.substring(0, _kAddressHeadLength)}'
        '…'
        '${value.substring(value.length - _kAddressTailLength)}';
  }

  static Widget? _footerFor(
    WalletConnectSessionState sessionState,
    VoidCallback? onDisconnect,
  ) {
    if (sessionState != WalletConnectSessionState.connected) {
      return null;
    }
    return Builder(
      builder: (BuildContext context) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        final dimens = context.dimens;
        return ScaffoldPressable(
          onPressed: onDisconnect,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space8,
              vertical: dimens.space6,
            ),
            child: Text(
              'Disconnect',
              style: textTheme.labelLarge?.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
