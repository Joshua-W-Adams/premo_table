import 'package:flutter/material.dart';
import 'package:premo_table/premo_table.dart';
import 'package:example/models/sample_data_model.dart';
import 'package:example/services/mock_data_service.dart';

class PremoTableBuilder extends StatefulWidget {
  final MockDataService mockDataService;

  PremoTableBuilder({
    required this.mockDataService,
  });

  @override
  _PremoTableBuilderState createState() => _PremoTableBuilderState();
}

class _PremoTableBuilderState extends State<PremoTableBuilder> {
  TableBloc<SampleDataModel>? _tableBloc;

  @override
  void initState() {
    super.initState();

    /// create BLoC
    _tableBloc = TableBloc(
      inputStream: widget.mockDataService.stream,
      columnNames: ['Id', 'Name', 'Age', 'Enabled', 'DOB', 'City', 'Salary'],
      cellValueBuilder: (rowModel, columnIndex) {
        /// rowModels can be null if the location being generated in the user
        /// interface is a deleted row.
        if (columnIndex == 0) {
          return rowModel?.id;
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
        } else if (columnIndex == 6) {
          return rowModel?.salary.toString();
        }
      },

      /// sort to applied to all input data before it is released on the table
      /// bloc stream
      defaultSortCompare: (a, b) {
        return a.id.compareTo(b.id);
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
          //   int id = int.parse(rowModel.id);
          //   int filterValue = int.parse(value);
          //   return id < filterValue;
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
  }

  @override
  void dispose() {
    _tableBloc!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// properties to standardise colours across table instance
    ThemeData _theme = Theme.of(context);

    /// interference with gesture detector in cell.
    // GestureDetector(
    //   onTap: () {
    //     _tableBloc.clearSelection();
    //     _tableBloc.clearHover();
    //   },

    /// generate instance of table
    return Column(
      children: [
        /// Table header
        TableActions(
          onUndo: () {},
          onRedo: () {},
          onAdd: () {},
          onDelete: () {},
        ),
        SizedBox(height: 16.0),
        Expanded(
          child: PremoTable<SampleDataModel>(
            tableBloc: _tableBloc!,
            columnBackgroundColor: _theme.primaryColor,
            columnTextStyle: _theme.primaryTextTheme.bodyText1,
            columnWidthBuilder: (col) {
              List<double> widths = [125, 200, 125, 125, 125, 125, 125];
              return widths[col];
            },
            columnReadOnlyBuilder: (col) {
              List<bool> readOnly = [
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
            columnHorizontalAlignmentBuilder: (_, __, col) {
              List<Alignment> alignments = [
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
                CellTypes.number,
                CellTypes.cellswitch,
                CellTypes.date,
                CellTypes.dropdown,
                CellTypes.currency,
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
                ],
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
          ),
        ),
      ],
    );
  }
}
