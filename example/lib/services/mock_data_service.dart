import 'dart:async';
import 'package:example/models/sample_data_model.dart';
import 'dart:math';
import 'package:rxdart/rxdart.dart';

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
  BehaviorSubject<List<SampleDataModel>> _controller = BehaviorSubject();

  Stream<List<SampleDataModel>> get stream {
    return _controller.stream;
  }

  MockDataService() {
    /// add data to stream so listeners update
    List<SampleDataModel> rowStates = _getData();
    _controller.sink.add(rowStates);
  }

  List<SampleDataModel> dataTemplate = [
    SampleDataModel(
      id: '1.0',
      parentId: null,
      name: 'Josh',
      age: 33,
      enabled: true,
      dateOfBirth: DateTime(1988, 2, 1),
      city: 'Perth',
      salary: 100,
    ),
    SampleDataModel(
      id: '2.0',
      parentId: '1.0',
      name: 'Rachel',
      age: 28,
      enabled: false,
      dateOfBirth: DateTime(1995, 4, 28),
      city: 'Melbourne',
      salary: 200,
    ),
    SampleDataModel(
      id: '3.0',
      parentId: '2.0',
      name: 'Shannon',
      age: 36,
      enabled: false,
      dateOfBirth: DateTime(1985, 9, 30),
      city: 'Sydney',
      salary: 300,
    ),
    SampleDataModel(
      id: '4.0',
      parentId: null,
      name: 'Robin',
      age: 62,
      enabled: false,
      dateOfBirth: DateTime(1958, 2, 12),
      city: 'Darwin',
      salary: 400,
    ),
    SampleDataModel(
      id: '5.0',
      parentId: '4.0',
      name: 'Bill',
      age: 65,
      enabled: true,
      dateOfBirth: DateTime(1953, 6, 20),
      city: 'Brisbane',
      salary: 500,
    ),
    SampleDataModel(
      id: '6.0',
      parentId: '5.0',
      name: 'Jessie',
      age: 90,
      enabled: true,
      dateOfBirth: DateTime(1930, 6, 12),
      city: 'Adelaide',
      salary: 600,
    ),
    SampleDataModel(
      id: '7.0',
      parentId: null,
      name: 'Peter',
      age: 33,
      enabled: true,
      dateOfBirth: DateTime(1988, 2, 4),
      city: 'Darwin',
      salary: 700,
    ),
    SampleDataModel(
      id: '8.0',
      parentId: '7.0',
      name: 'Jas',
      age: 33,
      enabled: false,
      dateOfBirth: DateTime(1988, 7, 15),
      city: 'Darwin',
      salary: 800,
    ),
    SampleDataModel(
      id: '9.0',
      parentId: '8.0',
      name: 'Craig',
      age: 33,
      enabled: false,
      dateOfBirth: DateTime(1988, 12, 25),
      city: 'Adelaide',
      salary: 900,
    ),
    SampleDataModel(
      id: '10.0',
      parentId: null,
      name: 'George',
      age: 33,
      enabled: true,
      dateOfBirth: DateTime(1988, 8, 26),
      city: 'Perth',
      salary: 1000,
    ),
  ];

  SampleDataModel _getRow({
    required int templateIndex,
    required double newId,
  }) {
    /// create data model
    SampleDataModel record = SampleDataModel.clone(dataTemplate[templateIndex]);

    /// update id
    /// To string as fixed used to enforce ids with one decimal place. As
    /// toString has difference behaviour on the web and mobile platforms. On
    /// web trailing 0s are stripped.
    record.id = newId.toStringAsFixed(1);

    /// create row to load into table
    return record;
  }

  List<SampleDataModel> _getData({int rowCount = 10}) {
    List<SampleDataModel> data = [];
    for (var i = 0; i < rowCount; i++) {
      int pos = i % 10;
      data.add(
        _getRow(templateIndex: pos, newId: i + 1),
      );
    }
    return data;
  }

  void _releaseTestCase(Function(List<SampleDataModel> data) changes) {
    /// create a new dataset
    List<SampleDataModel> data = _getData();

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
      data[0].name = getRandomString(5);
    });
  }

  void updateMiddle() {
    _releaseTestCase((data) {
      data[3].name = getRandomString(5);
    });
  }

  void updateLast() {
    _releaseTestCase((data) {
      data[data.length - 1].name = getRandomString(5);
    });
  }

  void multiUpdate() {
    _releaseTestCase((data) {
      data[0].name = getRandomString(5);
      data[3].name = getRandomString(5);
      data[data.length - 1].name = getRandomString(5);
    });
  }

  void randomUpdate() {
    _releaseTestCase((data) {
      int randomPosition = _rnd.nextInt(data.length - 1);
      data[randomPosition].name = getRandomString(5);
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
      /// add at extents
      data.insert(0, _getRow(templateIndex: 0, newId: 0));
      data.insert(3, _getRow(templateIndex: 0, newId: 3.5));
      data.add(_getRow(templateIndex: 0, newId: data.length + 1));

      /// update extents
      data[0].name = getRandomString(5);
      data[3].name = getRandomString(5);
      data[data.length - 1].name = getRandomString(5);

      /// remove a row
      data.removeAt(3);
    });
  }

  Future<void> releaseClone({
    required List<SampleDataModel> data,
    Function(List<SampleDataModel> clone)? changes,
  }) {
    /// clone the data array
    List<SampleDataModel> clone = data.map((e) {
      return SampleDataModel.clone(e);
    }).toList();

    /// execute changes on the cloned array
    changes?.call(clone);

    /// release on data stream after simulated server delay
    return Future.delayed(Duration(milliseconds: 2000), () {
      /// release on stream
      _controller.sink.add(clone);
    });
  }

  Future<void> update(List<SampleDataModel> data) {
    return releaseClone(data: data).then((_) {
      /// resolve update future 500ms after cloned stream event
      return Future.delayed(Duration(milliseconds: 500), () {});
    });
  }

  Future<void> add() {
    return Future.delayed(Duration(milliseconds: 2000), () {
      addLast();
    }).then((_) {
      /// resolve update future 500ms after cloned stream event
      return Future.delayed(Duration(milliseconds: 500), () {});
    });
  }

  Future<void> delete(
    List<SampleDataModel> deletes,
    List<SampleDataModel> data,
  ) {
    return releaseClone(
      data: data,
      changes: (clone) {
        for (var i = 0; i < clone.length; i++) {
          for (var d = 0; d < deletes.length; d++) {
            if (clone[i].id == deletes[d].id) {
              clone.remove(clone[i]);
            }
          }
        }
      },
    ).then((_) {
      /// resolve update future 500ms after cloned stream event
      return Future.delayed(Duration(milliseconds: 500), () {});
    });
  }

  void dispose() {
    _controller.close();
  }
}
