import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_date.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_duration.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_money.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_number.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_percentage.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_time.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

const TextStyle _callerStyle = TextStyle(
  fontSize: 31,
  color: Color(0xFF123456),
  fontFeatures: [FontFeature.slashedZero()],
);

final Map<String, Widget Function(TextStyle?)> _variants = {
  'number': (s) => ScaffoldFormattedValueNumber(value: 1234, style: s),
  'money': (s) => ScaffoldFormattedValueMoney(value: 42.5, style: s),
  'percentage': (s) => ScaffoldFormattedValuePercentage(value: 0.4, style: s),
  'date': (s) => ScaffoldFormattedValueDate(value: DateTime(2026, 8, 11), style: s),
  'time': (s) => ScaffoldFormattedValueTime(value: DateTime(2026, 8, 11, 9, 5), style: s),
  'duration': (s) =>
      ScaffoldFormattedValueDuration(value: const Duration(minutes: 5), style: s),
};

Future<void> _pumpMidnight(
  WidgetTester tester,
  Brightness brightness,
  Widget child,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: midnightTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  for (final MapEntry<String, Widget Function(TextStyle?)> variant
      in _variants.entries) {
    group('${variant.key} style', () {
      testWidgets('default theme keeps bodyLarge when no style is given', (
        tester,
      ) async {
        await _pump(tester, variant.value(null));
        final BuildContext context = tester.element(find.byType(Text));
        final Text text = tester.widget<Text>(find.byType(Text));
        expect(identical(text.style, Theme.of(context).textTheme.bodyLarge), isTrue);
      });

      testWidgets('default theme keeps the caller style as given', (
        tester,
      ) async {
        await _pump(tester, variant.value(_callerStyle));
        final Text text = tester.widget<Text>(find.byType(Text));
        expect(identical(text.style, _callerStyle), isTrue);
      });

      for (final Brightness brightness in Brightness.values) {
        testWidgets('midnight $brightness adds tabular figures', (
          tester,
        ) async {
          await _pumpMidnight(tester, brightness, variant.value(null));
          final Text text = tester.widget<Text>(find.byType(Text));
          expect(text.style?.fontFeatures, const [FontFeature.tabularFigures()]);
        });

        testWidgets('midnight $brightness keeps the caller size and color', (
          tester,
        ) async {
          await _pumpMidnight(tester, brightness, variant.value(_callerStyle));
          final Text text = tester.widget<Text>(find.byType(Text));
          expect(text.style?.fontSize, 31);
          expect(text.style?.color, const Color(0xFF123456));
          expect(text.style?.fontFeatures, const [FontFeature.tabularFigures()]);
        });
      }
    });
  }

  testWidgets('number formats with group separators in bodyLarge', (
    tester,
  ) async {
    await _pump(tester, const ScaffoldFormattedValueNumber(value: 1234));

    final Text text = tester.widget<Text>(find.byType(Text));
    expect(text.data, '1,234');
    final BuildContext context = tester.element(
      find.byType(ScaffoldFormattedValueNumber),
    );
    expect(text.style, Theme.of(context).textTheme.bodyLarge);
  });

  testWidgets('money formats currency symbol and decimals', (tester) async {
    await _pump(
      tester,
      const ScaffoldFormattedValueMoney(value: 42.5, currencySymbol: '\$'),
    );

    expect(find.text(r'$42.50'), findsOneWidget);
  });

  testWidgets('percentage multiplies by 100 and appends %', (tester) async {
    await _pump(tester, const ScaffoldFormattedValuePercentage(value: 0.425));

    expect(find.text('42.5%'), findsOneWidget);
  });

  testWidgets('date renders a locale-aware date', (tester) async {
    await _pump(
      tester,
      ScaffoldFormattedValueDate(value: DateTime(2026, 8, 11)),
    );

    expect(find.text('Aug 11, 2026'), findsOneWidget);
  });

  testWidgets('duration renders H:MM:SS and M:SS depending on magnitude', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldFormattedValueDuration(
        value: Duration(hours: 1, minutes: 23, seconds: 45),
      ),
    );
    expect(find.text('1:23:45'), findsOneWidget);

    await _pump(
      tester,
      const ScaffoldFormattedValueDuration(
        value: Duration(minutes: 5, seconds: 7),
      ),
    );
    expect(find.text('5:07'), findsOneWidget);
  });

  testWidgets('duration formats negative values with a leading sign', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldFormattedValueDuration(
        value: Duration(hours: -1, minutes: -30),
      ),
    );
    expect(find.text('-1:30:00'), findsOneWidget);
  });

  testWidgets('null value renders nullPlaceholder', (tester) async {
    await _pump(tester, const ScaffoldFormattedValueNumber(value: null));

    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('long number renders with ellipsis and maxLines 1', (
    tester,
  ) async {
    await _pump(
      tester,
      const ScaffoldFormattedValueNumber(value: 1234567890),
    );

    final Text text = tester.widget<Text>(find.byType(Text));
    expect(text.data, '1,234,567,890');
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
