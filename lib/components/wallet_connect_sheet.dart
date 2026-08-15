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
    final List<Widget> children = _childrenFor(
      context,
      sessionState: sessionState,
      qrBuilder: qrBuilder,
      uri: uri,
      address: address,
      networkName: networkName,
      onConnect: onConnect,
    );
    final Widget? footer = _footerFor(sessionState, onDisconnect);

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
        return address ?? 'Wallet';
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

    switch (sessionState) {
      case WalletConnectSessionState.disconnected:
        return <Widget>[
          if (qrBuilder != null && uri != null) qrBuilder(context, uri),
          if (onConnect != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ScaffoldPressable(
                onPressed: onConnect,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
            padding: const EdgeInsets.only(top: 16),
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
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
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
              address,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: textTheme.bodyLarge?.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          if (networkName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScaffoldBadge(
                variant: BadgeVariant.text,
                text: networkName,
              ),
            ),
        ];
    }
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
        return ScaffoldPressable(
          onPressed: onDisconnect,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
