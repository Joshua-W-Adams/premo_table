import 'dart:async';
import 'package:example/models/sample_data_model.dart';
import 'package:premo_table/premo_table.dart';
import 'dart:math';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(
        _rnd.nextInt(_chars.length),
      ),
    ),
  );
}

class MockDataService {
  StreamController<List<RowState<SampleDataModel>>> _controller =
      StreamController();

  Stream<List<RowState<SampleDataModel>>> get stream {
    return _controller.stream;
  }

  MockDataService() {
    /// add data to stream so listeners update
    List<RowState<SampleDataModel>> rowStates = _getData();
    _controller.sink.add(rowStates);
  }

  List<SampleDataModel> dataTemplate = [
    SampleDataModel(
      id: '1',
      name: 'Josh',
      age: 33,
      enabled: true,
      dateOfBirth: DateTime(1988, 2, 1),
      city: 'Perth',
      salary: 100,
    ),
    SampleDataModel(
      id: '2',
      name: 'Rachel',
      age: 28,
      enabled: false,
      dateOfBirth: DateTime(1995, 4, 28),
      city: 'Melbourne',
      salary: 200,
    ),
    SampleDataModel(
      id: '3',
      name: 'Shannon',
      age: 36,
      enabled: false,
      dateOfBirth: DateTime(1985, 9, 30),
      city: 'Sydney',
      salary: 300,
    ),
    SampleDataModel(
      id: '4',
      name: 'Robin',
      age: 62,
      enabled: false,
      dateOfBirth: DateTime(1958, 2, 12),
      city: 'Darwin',
      salary: 400,
    ),
    SampleDataModel(
      id: '5',
      name: 'Bill',
      age: 65,
      enabled: true,
      dateOfBirth: DateTime(1953, 6, 20),
      city: 'Brisbane',
      salary: 500,
    ),
    SampleDataModel(
      id: '6',
      name: 'Jessie',
      age: 90,
      enabled: true,
      dateOfBirth: DateTime(1930, 6, 12),
      city: 'Adelaide',
      salary: 600,
    ),
    SampleDataModel(
      id: '7',
      name: 'Peter',
      age: 33,
      enabled: true,
      dateOfBirth: DateTime(1988, 2, 4),
      city: 'Darwin',
      salary: 700,
    ),
    SampleDataModel(
      id: '8',
      name: 'Jas',
      age: 33,
      enabled: false,
      dateOfBirth: DateTime(1988, 7, 15),
      city: 'Darwin',
      salary: 800,
    ),
    SampleDataModel(
      id: '9',
      name: 'Craig',
      age: 33,
      enabled: false,
      dateOfBirth: DateTime(1988, 12, 25),
      city: 'Adelaide',
      salary: 900,
    ),
    SampleDataModel(
      id: '10',
      name: 'George',
      age: 33,
      enabled: true,
      dateOfBirth: DateTime(1988, 8, 26),
      city: 'Perth',
      salary: 1000,
    ),
  ];

  RowState<SampleDataModel> _getRow({
    required int templateIndex,
    required double newId,
  }) {
    /// create data model
    SampleDataModel record = SampleDataModel.clone(dataTemplate[templateIndex]);

    /// update id
    record.id = newId.toString();

    /// create row to load into table
    return RowState<SampleDataModel>(
      rowModel: record,
      cellStates: Map<int, CellState>(),
    );
  }

  List<RowState<SampleDataModel>> _getData({int rowCount = 10}) {
    List<RowState<SampleDataModel>> data = [];
    for (var i = 0; i < rowCount; i++) {
      int pos = i % 10;
      data.add(
        _getRow(templateIndex: pos, newId: i + 1),
      );
    }
    return data;
  }

  void _releaseTestCase(
      Function(List<RowState<SampleDataModel>> data) changes) {
    /// create a new dataset
    List<RowState<SampleDataModel>> data = _getData();

    /// perform specific changes
    changes(data);

    /// release on stream
    _controller.sink.add(data);
  }

  /// ******************************* Public API *******************************

  ///
  /// All test cases for external data updates
  ///

  void addFirst() {
    _releaseTestCase((data) {
      data.insert(0, _getRow(templateIndex: 0, newId: 0));
    });
  }

  void addMiddle() {
    _releaseTestCase((data) {
      data.insert(3, _getRow(templateIndex: 0, newId: 3.5));
    });
  }

  void addLast() {
    _releaseTestCase((data) {
      data.add(_getRow(templateIndex: 0, newId: data.length + 1));
    });
  }

  void multiAdd() {
    _releaseTestCase((data) {
      data.insert(0, _getRow(templateIndex: 0, newId: 0));
      data.insert(3, _getRow(templateIndex: 0, newId: 3.5));
      data.add(_getRow(templateIndex: 0, newId: data.length + 1));
    });
  }

  void updateFirst() {
    _releaseTestCase((data) {
      data[0].rowModel!.name = getRandomString(5);
    });
  }

  void updateMiddle() {
    _releaseTestCase((data) {
      data[3].rowModel!.name = getRandomString(5);
    });
  }

  void updateLast() {
    _releaseTestCase((data) {
      data[data.length - 1].rowModel!.name = getRandomString(5);
    });
  }

  void multiUpdate() {
    _releaseTestCase((data) {
      data[0].rowModel!.name = getRandomString(5);
      data[3].rowModel!.name = getRandomString(5);
      data[data.length - 1].rowModel!.name = getRandomString(5);
    });
  }

  void randomUpdate() {
    _releaseTestCase((data) {
      int randomPosition = _rnd.nextInt(data.length - 1);
      data[randomPosition].rowModel!.name = getRandomString(5);
    });
  }

  void deleteFirst() {
    _releaseTestCase((data) {
      data.removeAt(0);
    });
  }

  void deleteMiddle() {
    _releaseTestCase((data) {
      data.removeAt(3);
    });
  }

  void deleteLast() {
    _releaseTestCase((data) {
      data.removeLast();
    });
  }

  void multiDelete() {
    _releaseTestCase((data) {
      data.removeAt(0);
      data.removeAt(3);
      data.removeLast();
    });
  }

  void duplicateFirst() {
    _releaseTestCase((data) {
      data.insert(0, _getRow(templateIndex: 0, newId: 1));
    });
  }

  void duplicateMiddle() {
    _releaseTestCase((data) {
      data.insert(3, _getRow(templateIndex: 3, newId: 4));
    });
  }

  void duplicateLast() {
    _releaseTestCase((data) {
      int lastIndex = data.length - 1;
      data.add(
        _getRow(templateIndex: lastIndex, newId: lastIndex.toDouble() + 1),
      );
    });
  }

  void multiDuplicate() {
    _releaseTestCase((data) {
      int lastIndex = data.length - 1;
      data.add(
        _getRow(templateIndex: lastIndex, newId: lastIndex.toDouble() + 1),
      );
      data.insert(0, _getRow(templateIndex: 0, newId: 1));
      data.insert(3, _getRow(templateIndex: 3, newId: 4));
    });
  }

  void shuffledData() {
    _releaseTestCase((data) {
      data.shuffle();
    });
  }

  void multiUpdateAddDelete() {
    _releaseTestCase((data) {
      /// duplicate extents
      int lastIndex = data.length - 1;
      data.add(
        _getRow(templateIndex: lastIndex, newId: lastIndex.toDouble() + 1),
      );
      data.insert(0, _getRow(templateIndex: 0, newId: 1));
      data.insert(3, _getRow(templateIndex: 3, newId: 4));

      /// add at extents
      data.insert(0, _getRow(templateIndex: 0, newId: 0));
      data.insert(3, _getRow(templateIndex: 0, newId: 3.5));
      data.add(_getRow(templateIndex: 0, newId: data.length + 1));

      /// update extents
      data[0].rowModel!.name = getRandomString(5);
      data[3].rowModel!.name = getRandomString(5);
      data[data.length - 1].rowModel!.name = getRandomString(5);

      /// remove a row
      data.removeAt(3);
    });
  }

  void dispose() {
    _controller.close();
  }
}
