import 'package:example/app/sample_data_table/sample_data_table.dart';
import 'package:example/models/sample_data_model.dart';
import 'package:flutter/material.dart';
import 'package:premo_table/premo_table.dart';
import 'package:example/app/premo_table_builder/premo_table_builder.dart';
import 'package:example/services/mock_data_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// generate data service that provide stream of mocked server data
  MockDataService mockDataService = MockDataService();

  /// BloC for sample tables to be generated
  TableBloc<SampleDataModel>? _tableBloc;

  @override
  void initState() {
    super.initState();

    /// create BLoC
    _tableBloc = TableBloc(
      inputStream: mockDataService.stream,
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
    return Column(
      children: [
        Listener(
          /// deselection of table fired on all child widgets
          onPointerDown: (_) {
            _tableBloc!.deselect();
          },
          behavior: HitTestBehavior.opaque,
          child: TestCases(
            mockDataService: mockDataService,
          ),
        ),
        Expanded(
          child: GestureDetector(
            /// deselect fired on tapping padding
            onTap: () {
              _tableBloc!.deselect();
            },
            child: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) {
                Widget child;
                if (index == 0) {
                  child = Column(
                    children: [
                      /// Table header
                      TableActions(
                        onUndo: () {
                          _tableBloc!.deselect();
                        },
                        onRedo: () {
                          _tableBloc!.deselect();
                        },
                        onAdd: () {
                          _tableBloc!.deselect();
                        },
                        onDelete: () {
                          _tableBloc!.deselect();
                        },
                      ),
                      SizedBox(height: 16.0),
                      Expanded(
                        child: PremoTableBuilder<SampleDataModel>(
                          tableBloc: _tableBloc!,
                        ),
                      ),
                    ],
                  );
                } else if (index == 1) {
                  child = Listener(
                    onPointerDown: (_) {
                      _tableBloc!.deselect();
                    },
                    child: SampleDataTable(),
                  );
                } else {
                  child = Container();
                }
                return Container(
                  alignment: Alignment.center,
                  height: 500,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: child,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class TextCase {
  final String name;
  final void Function() test;

  TextCase({
    required this.name,
    required this.test,
  });
}

class TestCases extends StatelessWidget {
  final MockDataService mockDataService;

  TestCases({
    required this.mockDataService,
  });

  @override
  Widget build(BuildContext context) {
    List<TextCase> testCases = [];

    testCases.add(
      TextCase(
        name: 'addFirst',
        test: mockDataService.addFirst,
      ),
    );
    testCases.add(
      TextCase(
        name: 'addMiddle',
        test: mockDataService.addMiddle,
      ),
    );
    testCases.add(
      TextCase(
        name: 'addLast',
        test: mockDataService.addLast,
      ),
    );
    testCases.add(
      TextCase(
        name: 'multiAdd',
        test: mockDataService.multiAdd,
      ),
    );

    testCases.add(
      TextCase(
        name: 'updateFirst',
        test: mockDataService.updateFirst,
      ),
    );
    testCases.add(
      TextCase(
        name: 'updateMiddle',
        test: mockDataService.updateMiddle,
      ),
    );
    testCases.add(
      TextCase(
        name: 'updateLast',
        test: mockDataService.updateLast,
      ),
    );

    testCases.add(
      TextCase(
        name: 'multiUpdate',
        test: mockDataService.multiUpdate,
      ),
    );
    testCases.add(
      TextCase(
        name: 'randomUpdate',
        test: mockDataService.randomUpdate,
      ),
    );
    testCases.add(
      TextCase(
        name: 'deleteFirst',
        test: mockDataService.deleteFirst,
      ),
    );
    testCases.add(
      TextCase(
        name: 'deleteMiddle',
        test: mockDataService.deleteMiddle,
      ),
    );
    testCases.add(
      TextCase(
        name: 'deleteLast',
        test: mockDataService.deleteLast,
      ),
    );

    testCases.add(
      TextCase(
        name: 'multiDelete',
        test: mockDataService.multiDelete,
      ),
    );
    testCases.add(
      TextCase(
        name: 'duplicateFirst',
        test: mockDataService.duplicateFirst,
      ),
    );
    testCases.add(
      TextCase(
        name: 'duplicateMiddle',
        test: mockDataService.duplicateMiddle,
      ),
    );
    testCases.add(
      TextCase(
        name: 'duplicateLast',
        test: mockDataService.duplicateLast,
      ),
    );
    testCases.add(
      TextCase(
        name: 'multiDuplicate',
        test: mockDataService.multiDuplicate,
      ),
    );
    testCases.add(
      TextCase(
        name: 'shuffledData',
        test: mockDataService.shuffledData,
      ),
    );
    testCases.add(
      TextCase(
        name: 'multiUAD',
        test: mockDataService.multiUpdateAddDelete,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              runSpacing: 8.0,
              spacing: 16.0,
              children: List.generate(testCases.length, (index) {
                TextCase testCase = testCases[index];

                return ActionButton(
                  text: testCase.name,
                  icon: Icon(Icons.play_arrow),
                  onPressed: testCase.test,
                  width: 150.0,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
