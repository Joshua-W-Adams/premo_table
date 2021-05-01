import 'package:example/app/sample_data_table/sample_data_table.dart';
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
    /// generate data service that provide stream of mocked server data
    MockDataService mockDataService = MockDataService();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Column(
          children: [
            TestCases(
              mockDataService: mockDataService,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  Widget child;
                  if (index == 0) {
                    child = PremoTableBuilder(
                      mockDataService: mockDataService,
                    );
                  } else if (index == 1) {
                    child = SampleDataTable();
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
          ],
        ),
      ),
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
        name: 'multi update',
        test: mockDataService.multiUpdate,
      ),
    );
    testCases.add(
      TextCase(
        name: 'multi add',
        test: mockDataService.multiAdd,
      ),
    );
    testCases.add(
      TextCase(
        name: 'multi delete',
        test: mockDataService.multiDelete,
      ),
    );
    testCases.add(
      TextCase(
        name: 'multi u a d',
        test: mockDataService.multiUpdateAddDelete,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
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
    );
  }
}
