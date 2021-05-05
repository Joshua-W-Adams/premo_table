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

  RowState<SampleDataModel> _getRow(int pos, int id) {
    /// create data model
    SampleDataModel record = SampleDataModel.clone(dataTemplate[pos]);

    /// update id
    record.id = id.toString();

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
        _getRow(pos, i + 1),
      );
    }
    return data;
  }

  /// ******************************* Public API *******************************

  ///
  /// All test cases for external data updates
  ///

  void shuffledData() {
    List<RowState<SampleDataModel>> data = _getData();
    data.shuffle();
    _controller.sink.add(data);
  }

  void randomUpdate() {
    List<RowState<SampleDataModel>> data = _getData();
    int randomPosition = _rnd.nextInt(data.length - 1);
    data[randomPosition].rowModel!.name = getRandomString(5);
    _controller.sink.add(data);
  }

  void _multiUpdate(List<RowState<SampleDataModel>> data) {
    data[0].rowModel!.name = getRandomString(5);
    data[3].rowModel!.name = getRandomString(5);
    data[5].rowModel!.name = getRandomString(5);
    data[7].rowModel!.name = getRandomString(5);
  }

  void multiUpdate() {
    List<RowState<SampleDataModel>> data = _getData();
    _multiUpdate(data);
    _controller.sink.add(data);
  }

  void _multiAdd(List<RowState<SampleDataModel>> data) {
    data.insert(3, _getRow(0, data.length + 1));
    data.insert(data.length, _getRow(0, data.length + 1));
  }

  void multiAdd() {
    List<RowState<SampleDataModel>> data = _getData();
    _multiAdd(data);
    _controller.sink.add(data);
  }

  void _multiDelete(List<RowState<SampleDataModel>> data) {
    data.removeAt(0);
    data.removeAt(3);
    data.removeLast();
  }

  void multiDelete() {
    List<RowState<SampleDataModel>> data = _getData();
    _multiDelete(data);
    _controller.sink.add(data);
  }

  void multiUpdateAddDelete() {
    List<RowState<SampleDataModel>> data = _getData();
    _multiDelete(data);
    _multiAdd(data);
    _multiUpdate(data);
    _controller.sink.add(data);
  }

  void _duplicates(List<RowState<SampleDataModel>> data) {
    data.insert(0, _getRow(0, 1));
    data.insert(0, _getRow(0, 1));
  }

  void duplicates() {
    List<RowState<SampleDataModel>> data = _getData();
    _duplicates(data);
    _controller.sink.add(data);
  }

  void _excessOldData(List<RowState<SampleDataModel>> data) {
    data.removeLast();
    data.removeLast();
    data.removeLast();
  }

  void excessOldData() {
    List<RowState<SampleDataModel>> data = _getData();
    _excessOldData(data);
    _controller.sink.add(data);
  }

  void dispose() {
    _controller.close();
  }
}
