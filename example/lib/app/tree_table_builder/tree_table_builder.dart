import 'package:flutter/material.dart';
import 'package:premo_table/premo_table.dart';
import 'package:treebuilder/treebuilder.dart';

class TreeTableBuilder<T extends IUniqueParentChildRow>
    extends StatelessWidget {
  final TableBloc<T> tableBloc;

  TreeTableBuilder({
    required this.tableBloc,
  });

  @override
  Widget build(BuildContext context) {
    /// properties to standardise colours across table instance
    ThemeData _theme = Theme.of(context);

    /// generate instance of table
    return TreeTable<T>(
      tableBloc: tableBloc,
      columnBackgroundColor: _theme.primaryColor,
      columnTextStyle: _theme.primaryTextTheme.bodyText1,
      columnWidthBuilder: (col) {
        List<double> widths = [125, 125, 200, 125, 125, 125, 125, 125];
        return widths[col];
      },
      columnReadOnlyBuilder: (col) {
        List<bool> readOnly = [
          true,
          true,
          false,
          false,
          false,
          false,
          false,
          false
        ];
        return readOnly[col];
      },
      columnHorizontalAlignmentBuilder: (_, col) {
        List<Alignment> alignments = [
          Alignment.center,
          Alignment.center,
          Alignment.centerLeft,
          Alignment.center,
          Alignment.center,
          Alignment.center,
          Alignment.center,
          Alignment.center,
        ];
        return alignments[col];
      },
      columnTypeBuilder: (col) {
        List<CellTypes> types = [
          CellTypes.text,
          CellTypes.text,
          CellTypes.text,
          CellTypes.number,
          CellTypes.cellswitch,
          CellTypes.date,
          CellTypes.dropdown,
          CellTypes.currency,
        ];
        return types[col];
      },
      columnDropdownBuilder: (item, col) {
        List<List<String>?> dropdowns = [
          null,
          null,
          null,
          null,
          null,
          null,
          ['Perth', 'Melbourne', 'Sydney', 'Darwin', 'Brisbane', 'Adelaide'],
          null,
        ];
        return dropdowns[col];
      },
      // cellTextStyleBuilder: (item, row, col) {
      //   /// return some TextStyle override if necessary
      //   return null;
      // },
      // columnValidators: [null, null, null],
      // cellWidgetBuilder: (item, row, col) {
      /// replace entire widget in a specific cell
      // return Widget;
      // },
    );
  }
}
