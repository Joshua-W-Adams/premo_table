import 'package:flutter/material.dart';
import 'package:premo_table/premo_table.dart';
import 'package:example/models/sample_data_model.dart';
import 'package:example/services/mock_data_service.dart';

class PremoTableBuilder extends StatelessWidget {
  final MockDataService mockDataService;

  PremoTableBuilder({
    required this.mockDataService,
  });

  @override
  Widget build(BuildContext context) {
    /// properties to standardise colours across table instance
    ThemeData _theme = Theme.of(context);

    /// create BLoC
    TableBloc<SampleDataModel> _tableBloc = TableBloc(
      inputStream: mockDataService.stream,
      columnNames: ['Id', 'Name', 'Age', 'Enabled', 'Date of Birth', 'City'],
      cellValueBuilder: (rowModel, columnIndex) {
        /// rowModels can be null if the location being generated in the user
        /// interface is a deleted row.
        if (columnIndex == 0) {
          return rowModel?.uid;
        } else if (columnIndex == 1) {
          return rowModel?.name;
        } else if (columnIndex == 2) {
          return rowModel?.age?.toString();
        } else if (columnIndex == 3) {
          return rowModel?.enabled.toString();
        } else if (columnIndex == 4) {
          return rowModel?.dateOfBirth.toString();
        } else if (columnIndex == 5) {
          return rowModel?.city;
        }
      },

      /// sort to applied to all input data before it is released on the table
      /// bloc stream
      defaultSortCompare: (a, b) {
        return a.uid.compareTo(b.uid);
      },

      /// sort function to run on each column
      sortCompare: (col, asc, a, b) {
        /// invert objects for asc and desc as applicable
        if (asc != true) {
          final SampleDataModel c = a;
          a = b;
          b = c;
        }

        /// convert objects to Maps. Enabling referencing of map positions.
        List aList = a.toMap().values.toList();
        List bList = b.toMap().values.toList();

        if (col == 3) {
          int valA = aList[col] == true ? 1 : 0;
          int valB = bList[col] == true ? 1 : 0;
          return valA.compareTo(valB);
        } else {
          /// comparator functon returns -1 = less, 0 = equal, 1 = greater than
          return aList[col].compareTo(bList[col]);
        }
      },

      /// filter function to run on each column
      onFilter: (rowModel, col, value) {
        if (value != '') {
          /// test less than filter
          // if (col == 0) {
          //   int uid = int.parse(rowModel.uid);
          //   int filterValue = int.parse(value);
          //   return uid < filterValue;
          // }

          /// convert objects to Maps. Enabling referencing of map positions.
          List itemList = rowModel.toMap().values.toList();

          return itemList[col]!.toString().contains(value);
        }

        return true;
      },

      // onUpdate: (item, col, value) async {
      //   /// store item details in model instance
      //   if (col == 0) {
      //     /// N/A - non editable column
      //   } else if (col == 1) {
      //     item.name = value;
      //   } else if (col == 2) {
      //     item.age = num.tryParse(value);
      //   } else if (col == 3) {
      //     item.enabled = (value.toLowerCase() == 'true');
      //   } else if (col == 4) {
      //     item.dateOfBirth = DateTime.parse(value);
      //   } else if (col == 5) {
      //     item.city = value;
      //   }
      //   return Future.delayed(Duration(milliseconds: 1000));
      // },
    );

    /// interference with gesture detector in cell.
    // GestureDetector(
    //   onTap: () {
    //     _tableBloc.clearSelection();
    //     _tableBloc.clearHover();
    //   },

    /// generate instance of table
    return Column(
      children: [
        /// title and actions
        TableHeader(
          title: Text('Sample Premo Table'),
          actions: TableActions(
            onUndo: () {},
            onRedo: () {},
            onAdd: () {},
            onDelete: () {},
          ),
        ),
        Expanded(
          child: PremoTable<SampleDataModel>(
            tableBloc: _tableBloc,
            columnBackgroundColor: _theme.accentColor.withOpacity(0.25),
            disabledCellColor: _theme.accentColor.withOpacity(0.25),
            highlightedCellColor: _theme.accentColor.withOpacity(0.5),
            highlightedCellBorderColor: _theme.accentColor,
            columnWidthBuilder: (col) {
              List<double> widths = [125, 200, 125, 125, 125, 125];
              return widths[col];
            },
            columnReadOnlyBuilder: (col) {
              List<bool> readOnly = [true, false, false, false, false, false];
              return readOnly[col];
            },
            columnAlignmentBuilder: (_, __, col) {
              List<TextAlign> alignments = [
                TextAlign.center,
                TextAlign.left,
                TextAlign.center,
                TextAlign.center,
                TextAlign.center,
                TextAlign.center
              ];
              return alignments[col];
            },
            columnTypeBuilder: (col) {
              List<CellTypes> types = [
                CellTypes.text,
                CellTypes.text,
                CellTypes.text,
                CellTypes.cellswitch,
                CellTypes.date,
                CellTypes.dropdown,
              ];
              return types[col];
            },
            columnDropdownBuilder: (item, row, col) {
              List<List<String>?> dropdowns = [
                null,
                null,
                null,
                null,
                null,
                [
                  'Perth',
                  'Melbourne',
                  'Sydney',
                  'Darwin',
                  'Brisbane',
                  'Adelaide'
                ]
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
            // rowKeyBuilder: (item, _) {
            //   /// Assign unique key for a row...
            //   /// prevents on change cell functions firing on removal of existing
            //   /// rows.
            //   return item.id;
            // },
          ),
        ),
      ],
    );
  }
}
