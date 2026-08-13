import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_date.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_money.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_number.dart';
import 'package:frontend_scaffold/components/scaffold_formatted_value_percentage.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
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
