part of premo_table;

/// fully describes the current state of a cell
class CellState<T> {
  /// current value assigned to cell
  T value;

  /// selection details
  bool selected;
  bool rowSelected;
  bool colSelected;

  /// hover details
  bool hovered;
  bool rowHovered;
  bool colHovered;

  /// checked details
  bool rowChecked;

  /// if there is an aysnc request on the cell in operation
  bool requestInProgress;

  /// whether or not the cell request executed correctly
  bool? requestSucceeded;

  /// whether the latest update came from the server or not
  bool serverUpdate;

  CellState({
    required this.value,
    this.selected = false,
    this.rowSelected = false,
    this.colSelected = false,
    this.hovered = false,
    this.rowHovered = false,
    this.colHovered = false,
    this.rowChecked = false,
    this.requestInProgress = false,
    this.requestSucceeded,
    this.serverUpdate = false,
  });
}

/// All business logic for a [Cell]
class CellBloc<T> {
  /// initial value to be set in the [CellState]
  final T initialValue;

  /// callback function to fire everytime the cells value changes
  final Future<void>? onChange;

  /// cache of cell state
  CellState<T> state;
  StreamController<CellState<T>> _controller = StreamController();

  CellBloc({
    required this.initialValue,
    this.onChange,

    /// create initial state
  }) : this.state = CellState<T>(value: initialValue) {
    /// add state to stream
    _controller.sink.add(state);
  }

  Stream<CellState<T>> get stream {
    return _controller.stream;
  }

  bool _hasValueChanged(T? newValue) {
    if (state.value != newValue) {
      return true;
    }
    return false;
  }

  void _processOnChange() {
    /// Prevent the user spamming multiple async change requests while one is
    /// in progress
    if (!state.requestInProgress) {
      /// update state
      state.requestInProgress = true;

      /// release new state on stream so ui can block further changes
      _controller.sink.add(state);

      /// perform onChange request
      onChange!.then((_) {
        /// case 1 - async request performed successfully
        /// update state
        state.requestInProgress = false;
        state.requestSucceeded = true;
        state.serverUpdate = false;

        /// release on stream
        _controller.sink.add(state);
      }).catchError((e) {
        /// case 1 - error in async request
        /// update state
        state.requestInProgress = false;
        state.requestSucceeded = false;
        state.serverUpdate = false;

        /// release on stream
        _controller.sink.add(state);
      });
    }

    /// pending result of request. Do nothing.
  }

  /// update the value in the [CellState]
  void updateCellValue(T newValue) {
    /// check that the newValue is different from the current value in the state
    if (_hasValueChanged(newValue)) {
      /// set new value
      state.value = newValue;

      if (onChange != null) {
        /// case 1 - onChange callback provided
        _processOnChange();
      } else {
        /// case 2 - otherwise
        /// release on stream
        _controller.sink.add(state);
      }
    }
  }

  void serverUpdateDetected(T serverValue) {
    /// check if new value from server differes from existing value in state
    if (_hasValueChanged(serverValue)) {
      state.value = serverValue;
      state.serverUpdate = true;

      /// release on stream
      _controller.sink.add(state);

      /// only fire server change animations once! ... don't refire when table
      /// is sorted or filtered after a server change has been recieved.
      state.serverUpdate = false;
    }

    /// do nothing, value unchanged
  }

  void setSelected(bool selected) {
    state.selected = selected;
    _controller.sink.add(state);
  }

  void setRowSelected(bool rowSelected) {
    state.rowSelected = rowSelected;
    _controller.sink.add(state);
  }

  void setColSelected(bool colSelected) {
    state.colSelected = colSelected;
    _controller.sink.add(state);
  }

  void setRowChecked(bool checked) {
    state.rowChecked = checked;
    _controller.sink.add(state);
  }

  void setHovered(bool hovered) {
    state.hovered = hovered;
    _controller.sink.add(state);
  }

  void setRowHovered(bool hovered) {
    state.rowHovered = hovered;
    _controller.sink.add(state);
  }

  void setColHovered(bool hovered) {
    state.colHovered = hovered;
    _controller.sink.add(state);
  }

  void dispose() {
    _controller.close();
  }
}
