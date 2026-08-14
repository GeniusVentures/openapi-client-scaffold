import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_scroll_edge_indicator.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ScrollController controller,
  required double contentHeight,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(
        body: SizedBox(
          height: 400,
          width: 400,
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                controller: controller,
                child: SizedBox(height: contentHeight, width: double.infinity),
              ),
              Positioned.fill(
                child: ScaffoldScrollEdgeIndicator(
                  scrollController: controller,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

double _opacityOf(WidgetTester tester, String key) {
  return tester.widget<AnimatedOpacity>(find.byKey(Key(key))).opacity;
}

void main() {
  testWidgets('shows end edge line at offset 0 when content overflows', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller, contentHeight: 2000);
    await tester.pump();

    // Exercise the scroll listener, then return to the start offset.
    controller.jumpTo(100);
    await tester.pump();
    controller.jumpTo(0);
    await tester.pump();

    expect(_opacityOf(tester, 'scroll_edge_end'), 1.0);
    expect(_opacityOf(tester, 'scroll_edge_start'), 0.0);
  });

  testWidgets('hides both edge lines when content fits', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller, contentHeight: 100);
    await tester.pump();

    controller.jumpTo(0);
    await tester.pump();

    expect(_opacityOf(tester, 'scroll_edge_end'), 0.0);
    expect(_opacityOf(tester, 'scroll_edge_start'), 0.0);
  });

  testWidgets('re-attaches the listener when scrollController changes', (
    tester,
  ) async {
    final controllerA = ScrollController();
    final controllerB = ScrollController();
    addTearDown(controllerA.dispose);
    addTearDown(controllerB.dispose);

    Widget harness(ScrollController controller, double contentHeight) {
      return MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 400,
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  controller: controller,
                  child: SizedBox(
                    height: contentHeight,
                    width: double.infinity,
                  ),
                ),
                Positioned.fill(
                  child: ScaffoldScrollEdgeIndicator(
                    scrollController: controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(harness(controllerA, 100));
    await tester.pump();
    expect(_opacityOf(tester, 'scroll_edge_end'), 0.0);

    // Swap in a controller whose content overflows. Exercising B must drive
    // the indicator — proving the listener was re-attached to the new
    // controller (not left dangling on the old one).
    await tester.pumpWidget(harness(controllerB, 2000));
    await tester.pump();

    controllerB.jumpTo(1600);
    await tester.pump();
    expect(_opacityOf(tester, 'scroll_edge_end'), 0.0);
    expect(_opacityOf(tester, 'scroll_edge_start'), 1.0);

    controllerB.jumpTo(0);
    await tester.pump();
    expect(_opacityOf(tester, 'scroll_edge_end'), 1.0);
    expect(_opacityOf(tester, 'scroll_edge_start'), 0.0);
  });
}
