import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/toast/toast_manager.dart';
import 'package:frontend_scaffold/components/toast/toast_widget.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Pumps a host whose button raises a toast, at [size] with [topInset] of
/// safe area — the two inputs the placement is derived from.
///
/// Registers [scaffoldThemeExtensions] on the host's [ThemeData] so
/// `context.palette` / `context.dimens` resolve without a host-app override.
Future<BuildContext> _pumpHost(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double topInset = 47,
}) async {
  late BuildContext captured;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: EdgeInsets.only(top: topInset),
      ),
      child: MaterialApp(
        theme: ThemeData(extensions: scaffoldThemeExtensions),
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  tearDown(() => ToastManager.instance.disposeAll());

  group('density is chosen by whether there is a title', () {
    testWidgets('no title gives a compact pill with no dismiss button', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      showToast(context, 'Link copied');
      await tester.pump();

      expect(find.text('Link copied'), findsOneWidget);
      // The compact density is a receipt: it carries no close affordance,
      // because nothing is lost if it is missed.
      expect(find.byTooltip('Dismiss'), findsNothing);

      final toast = tester.widget<ToastWidget>(find.byType(ToastWidget));
      expect(toast.density, ToastDensity.compact);
    });

    testWidgets('a title gives the card, with a 44pt dismiss target', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      showToast(
        context,
        'Please try again.',
        title: 'Verification failed',
        type: ToastType.error,
      );
      await tester.pump();

      final toast = tester.widget<ToastWidget>(find.byType(ToastWidget));
      expect(toast.density, ToastDensity.card);

      expect(find.byTooltip('Dismiss'), findsOneWidget);
      final button = tester.getSize(find.byType(IconButton));
      // Phase 25 set 44pt as the floor for a tap target; the toast's close
      // button was ~28 before this.
      expect(button.width, greaterThanOrEqualTo(44));
      expect(button.height, greaterThanOrEqualTo(44));
    });
  });

  testWidgets('a screen reader is handed both halves of an alert', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    showToast(
      context,
      'Please try again.',
      title: 'Verification failed',
      type: ToastType.error,
    );
    await tester.pump();

    final toast = tester.widget<ToastWidget>(find.byType(ToastWidget));
    expect(toast.semanticLabel, 'Verification failed. Please try again.');

    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(ToastWidget),
            matching: find.byType(Semantics),
          )
          .first,
    );
    // Without liveRegion the toast is never announced at all — which for
    // "Verification failed" is the whole notification going missing.
    expect(semantics.properties.liveRegion, isTrue);
  });

  testWidgets('toast text carries no inherited debug underline', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    showToast(
      context,
      'Please try again.',
      title: 'Verification failed',
      type: ToastType.error,
    );
    await tester.pump();

    // The overlay has no Material ancestor of its own. Without one, Text
    // inherits Flutter's fallback DefaultTextStyle — reddish, with a yellow
    // double underline — because the typography tokens set colour and size
    // but not `decoration`. It showed up on the first desktop walk.
    for (final text in <String>['Verification failed', 'Please try again.']) {
      final rich = tester.widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );
      expect(
        rich.text.style?.decoration ?? TextDecoration.none,
        TextDecoration.none,
        reason: '"$text" picked up the no-Material fallback decoration',
      );
    }
  });

  testWidgets('the top offset is derived from the safe area, not a literal', (
    tester,
  ) async {
    // 47 and 20 stand in for a notched and an un-notched phone. The old code
    // hard-coded `top: 100` for both.
    for (final inset in <double>[47, 20]) {
      final context = await _pumpHost(tester, topInset: inset);
      showToast(context, 'Link copied');
      await tester.pump();

      final positioned = tester.widget<Positioned>(
        find
            .ancestor(
              of: find.byType(ToastWidget),
              matching: find.byType(Positioned),
            )
            .first,
      );
      // padding.top + mobile header (60) + space4 (8).
      expect(positioned.top, inset + 68);

      ToastManager.instance.disposeAll();
      await tester.pump(const Duration(milliseconds: 400));
    }
  });

  testWidgets('the stack caps at three and evicts the oldest', (tester) async {
    final context = await _pumpHost(tester);
    for (var i = 1; i <= 5; i++) {
      showToast(context, 'Toast $i');
      await tester.pump();
    }

    // Was uncapped: the sixth used to sit off the bottom of the screen.
    expect(ToastManager.instance.visibleCount, 3);
    expect(find.text('Toast 1'), findsNothing);
    expect(find.text('Toast 5'), findsOneWidget);
  });

  testWidgets('a torn-down tree leaves no timer running', (tester) async {
    final context = await _pumpHost(tester);
    showToast(context, 'Link copied');
    await tester.pump();
    expect(ToastManager.instance.visibleCount, 1);

    // Replacing the tree disposes the overlay. If the auto-dismiss timer were
    // held by the manager rather than the State it would outlive this and the
    // test would fail with a pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(ToastManager.instance.visibleCount, 0);
  });

  // ---------------------------------------------------------------------------
  // CR-02..04 regression tests — upstream's suite lacks these. They pin the
  // lifecycle fixes from scaffold commit 7fc42ed that the redesign's structure
  // now covers but does not independently test-lock.
  // ---------------------------------------------------------------------------

  testWidgets(
    'manual dismiss fires onClose exactly once (no timer double-fire)',
    (tester) async {
      // CR-03: pre-fix, the auto-dismiss Timer was not cancelled on manual
      // close, so onClose fired twice — once from the tap, once from the
      // timer up to 5s later.
      final context = await _pumpHost(tester);
      var closeCount = 0;
      showToast(
        context,
        'Please try again.',
        title: 'Verification failed',
        type: ToastType.error,
        onClose: () => closeCount++,
      );
      await tester.pump();

      // Tap the Dismiss button — first fire.
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(closeCount, 1);

      // Pump past the card's 5s auto-dismiss duration. If the timer were
      // still pending, it would fire onClose a second time here.
      await tester.pump(const Duration(seconds: 6));
      expect(
        closeCount,
        1,
        reason: 'onClose fired twice — auto-dismiss timer was not cancelled',
      );
    },
  );

  testWidgets('dispose with in-flight toast does not crash', (tester) async {
    // CR-02 + CR-04: pre-fix, disposing the tree while a toast was animating
    // in (or before the first frame) leaked the OverlayEntry and crashed on
    // "A dismissed AnimationController was used".
    final context = await _pumpHost(tester);
    showToast(context, 'Link copied');
    // Deliberately do NOT pump — the toast's controller has not forwarded yet.

    // Tearing down the tree synchronously must not throw.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(ToastManager.instance.visibleCount, 0);
  });

  testWidgets('entry is removed after reverse animation completes', (
    tester,
  ) async {
    // CR-02: _dismiss removes the toast from the manager's list synchronously,
    // then removes the OverlayEntry after the reverse animation finishes. If
    // the "reverse().then(remove)" path broke, the widget would linger in the
    // tree after visibleCount reached 0.
    final context = await _pumpHost(tester);
    showToast(
      context,
      'Please try again.',
      title: 'Verification failed',
      type: ToastType.error,
    );
    await tester.pump();
    expect(ToastManager.instance.visibleCount, 1);
    expect(find.byType(ToastWidget), findsOneWidget);

    // Manual dismiss — list mutation is synchronous.
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    expect(ToastManager.instance.visibleCount, 0);

    // After the 300ms reverse animation completes, the OverlayEntry must be
    // gone from the tree — no lingering widget.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ToastWidget), findsNothing);
  });
}
