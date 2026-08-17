import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// Hand-written test-double item mirroring the placeholder `{{ data_type_name }}`
/// class emitted by `templates/components/data_table.dart.jinja2`.
class _SampleItem {
  const _SampleItem({this.name});

  final Object? name;
}

/// Hand-written test-double column config mirroring the POST-CHANGE
/// `DataColumnConfig` shape from `templates/components/data_table.dart.jinja2`
/// (after the WIDG-43 extension that adds the optional `cellBuilder` field).
class _DataColumnConfig {
  const _DataColumnConfig({
    required this.label,
    required this.accessor,
    this.sortable = true,
    this.cellBuilder,
  });

  final String label;
  final String accessor;
  final bool sortable;

  /// Optional custom cell renderer. When non-null, the cell renders
  /// `cellBuilder(context, item)` inside the default `DataCell`.
  final Widget Function(BuildContext context, _SampleItem item)? cellBuilder;
}

/// Host widget that mirrors the post-change template render path exactly:
/// branch on `cellBuilder` presence; fall back to `Text(item.accessor?.toString() ?? '')`.
class _CellHost extends StatelessWidget {
  const _CellHost({required this.config, required this.item});

  final _DataColumnConfig config;
  final _SampleItem item;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: <DataColumn>[DataColumn(label: Text(config.label))],
      rows: <DataRow>[
        DataRow(
          cells: <DataCell>[
            DataCell(
              config.cellBuilder != null
                  ? Builder(
                      builder: (BuildContext ctx) =>
                          config.cellBuilder!(ctx, item),
                    )
                  : Text(item.name?.toString() ?? ''),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: scaffoldThemeExtensions),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'when cellBuilder is null, renders the string-fallback Text(item.name)',
    (tester) async {
      const _DataColumnConfig config = _DataColumnConfig(
        label: 'Name',
        accessor: 'name',
      );
      const _SampleItem item = _SampleItem(name: 'Alice');

      await _pump(tester, const _CellHost(config: config, item: item));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.byKey(const Key('custom-cell')), findsNothing);
    },
  );

  testWidgets(
    'when cellBuilder is non-null, renders the custom widget and NOT the string fallback',
    (tester) async {
      const _DataColumnConfig config = _DataColumnConfig(
        label: 'Name',
        accessor: 'name',
        cellBuilder: _buildCustomCell,
      );
      const _SampleItem item = _SampleItem(name: 'Alice');

      await _pump(tester, const _CellHost(config: config, item: item));

      expect(find.byKey(const Key('custom-cell')), findsOneWidget);
      // The string-fallback Text for the cell must NOT render. The header
      // "Name" label is expected — only the row's fallback text is excluded.
      expect(find.text('Alice'), findsNothing);
    },
  );

  testWidgets(
    'custom builder is invoked with the same BuildContext and item the template supplies',
    (tester) async {
      BuildContext? capturedContext;
      _SampleItem? capturedItem;

      Widget builder(BuildContext context, _SampleItem item) {
        capturedContext = context;
        capturedItem = item;
        return Container(key: const Key('custom-cell'));
      }

      final _DataColumnConfig config = _DataColumnConfig(
        label: 'Name',
        accessor: 'name',
        sortable: true,
        cellBuilder: builder,
      );
      const _SampleItem item = _SampleItem(name: 'Alice');

      await _pump(tester, _CellHost(config: config, item: item));

      expect(capturedContext, isNotNull);
      expect(capturedItem, same(item));
      // Exercise the `sortable` field on the test double to mirror the
      // template's DataColumnConfig surface (sort is driven by accessor).
      expect(config.sortable, isTrue);
    },
  );
}

Widget _buildCustomCell(BuildContext context, _SampleItem item) {
  return Container(key: const Key('custom-cell'));
}
