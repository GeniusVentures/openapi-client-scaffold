import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/components/bottom_drawer/bottom_drawer.dart';

class ResponsiveDrawer {
  static const double _desktopBreakpoint = 800;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    Widget? footer,
    VoidCallback? onClose,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;
    final colorRoles = context.colorRoles;
    final edge = colorRoles.surfaceEdge;

    final Future<T?> future = isDesktop
        ? showDialog<T>(
            context: context,
            barrierColor: colorRoles.scrim ?? Colors.black87,
            builder: (context) {
              return ResponsiveDrawerPanel(
                title: title,
                footer: footer,
                children: children,
              );
            },
          )
        : showModalBottomSheet<T>(
            backgroundColor: context.palette.deepBlueTertiary,
            barrierColor: colorRoles.scrim,
            enableDrag: false,
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: RoundedRectangleBorder(
              side: edge == null ? BorderSide.none : BorderSide(color: edge),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.shapes.sheetRadius ?? 16),
              ),
            ),
            builder: (context) {
              return BottomDrawer(
                title: title,
                footer: footer,
                children: children,
              );
            },
          );

    return future.whenComplete(() {
      if (onClose != null) {
        onClose();
      }
    });
  }
}

/// The desktop side panel ResponsiveDrawer.show opens; usable on its own.
class ResponsiveDrawerPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? footer;

  const ResponsiveDrawerPanel({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final radius = context.shapes.sheetRadius;
    final edge = context.colorRoles.surfaceEdge;
    final styled = radius != null || edge != null;
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: context.palette.deepBlueTertiary,
        shape: styled
            ? RoundedRectangleBorder(
                side: edge == null ? BorderSide.none : BorderSide(color: edge),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(radius ?? 0),
                ),
              )
            : null,
        clipBehavior: styled ? Clip.antiAlias : Clip.none,
        child: SizedBox(
          width: 400,
          height: double.infinity,
          child: BottomDrawer(
            title: title,
            footer: footer,
            children: children,
          ),
        ),
      ),
    );
  }
}
