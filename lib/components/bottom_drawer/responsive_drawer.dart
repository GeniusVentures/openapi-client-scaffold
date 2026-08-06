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

    final Future<T?> future = isDesktop
        ? showDialog<T>(
            context: context,
            barrierColor: Colors.black87,
            builder: (context) {
              return Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: context.palette.deepBlueTertiary,
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
            },
          )
        : showModalBottomSheet<T>(
            backgroundColor: context.palette.deepBlueTertiary,
            enableDrag: false,
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
