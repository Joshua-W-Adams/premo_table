import 'package:flutter/material.dart';

class SampleDataTable extends StatefulWidget {
  const SampleDataTable({Key? key}) : super(key: key);

  @override
  _SampleDataTableState createState() => _SampleDataTableState();
}

/// This is the private State class that goes with SampleDataTable.
class _SampleDataTableState extends State<SampleDataTable> {
  static const int numItems = 20;
  List<bool> selected = List<bool>.generate(numItems, (int index) => false);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text('0'),
                ),
                DataColumn(
                  label: Text('1'),
                ),
                DataColumn(
                  label: Text('2'),
                ),
                DataColumn(
                  label: Text('3'),
                ),
                DataColumn(
                  label: Text('4'),
                ),
                DataColumn(
                  label: Text('5'),
                ),
                DataColumn(
                  label: Text('6'),
                ),
                DataColumn(
                  label: Text('7'),
                ),
                DataColumn(
                  label: Text('8'),
                ),
                DataColumn(
                  label: Text('9'),
                ),
              ],
              rows: List<DataRow>.generate(
                numItems,
                (int index) => DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    // All rows will have the same selected color.
                    if (states.contains(MaterialState.selected))
                      return Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.08);
                    // Even rows will have a grey color.
                    if (index.isEven) {
                      return Colors.grey.withOpacity(0.3);
                    }
                    return null; // Use default value for other states and odd rows.
                  }),
                  cells: <DataCell>[
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                    DataCell(Text('Row $index')),
                  ],
                  selected: selected[index],
                  onSelectChanged: (bool? value) {
                    setState(() {
                      selected[index] = value!;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
