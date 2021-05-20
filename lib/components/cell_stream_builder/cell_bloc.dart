part of premo_table;

/// fully describes the current state of a cell
class CellBlocState<T> {
  /// current value assigned to cell
  T value;

  /// visibility of the cell
  bool visible;

  /// selection details
  bool selected;
  bool rowSelected;
  bool colSelected;

  /// hover details
  bool hovered;
  bool rowHovered;
  bool colHovered;

  /// checked details
  bool? rowChecked;

  /// sort details
  bool? columnSorted;

  /// filter details
  bool columnFiltered;

  /// if there is an aysnc request on the cell in operation
  bool requestInProgress;

  /// whether or not the cell request executed correctly
  bool? requestSucceeded;

  /// what the latest update from the server was
  ChangeTypes? changeType;

  CellBlocState({
    required this.value,
    this.visible = true,
    this.selected = false,
    this.rowSelected = false,
    this.colSelected = false,
    this.hovered = false,
    this.rowHovered = false,
    this.colHovered = false,
    this.rowChecked,
    this.columnSorted,
    this.columnFiltered = false,
    this.requestInProgress = false,
    this.requestSucceeded,
    this.changeType,
  });

  bool stateChanged(CellBlocState newState) {
    return !(this.value == newState.value &&
        this.visible == newState.visible &&
        this.selected == newState.selected &&
        this.rowSelected == newState.rowSelected &&
        this.colSelected == newState.colSelected &&
        this.hovered == newState.hovered &&
        this.rowHovered == newState.rowHovered &&
        this.colHovered == newState.colHovered &&
        this.rowChecked == newState.rowChecked &&
        this.columnSorted == newState.columnSorted &&
        this.requestInProgress == newState.requestInProgress &&
        this.requestSucceeded == newState.requestSucceeded &&
        this.changeType == newState.changeType);
  }

  CellBlocState.clone(CellBlocState a)
      : this(
          value: a.value,
          visible: a.visible,
          selected: a.selected,
          rowSelected: a.rowSelected,
          colSelected: a.colSelected,
          hovered: a.hovered,
          rowHovered: a.rowHovered,
          colHovered: a.colHovered,
          rowChecked: a.rowChecked,
          columnSorted: a.columnSorted,
          columnFiltered: a.columnFiltered,
          requestInProgress: a.requestInProgress,
          requestSucceeded: a.requestSucceeded,
          changeType: a.changeType,
        );
}

/// All business logic for a [Cell]
class CellBloc<T> {
  /// initial value to be set in the [CellBlocState]
  final CellBlocState<T> initialState;

  /// cache of cell state
  CellBlocState<T> state;
  StreamController<CellBlocState<T>> _controller = StreamController();

  CellBloc({
    required this.initialState,

    /// create initial state
  }) : this.state = initialState {
    /// add state to stream
    _controller.sink.add(state);
  }

  Stream<CellBlocState<T>> get stream {
    return _controller.stream;
  }

  void setState(CellBlocState<T> state) {
    if (this.state.stateChanged(state)) {
      this.state = state;
      _controller.sink.add(this.state);
    }
  }

  void setValue(T value) {
    if (state.value != value) {
      state.value = value;
      _controller.sink.add(state);
    }
  }

  void setVisible(bool visible) {
    if (state.visible != visible) {
      state.visible = visible;
      _controller.sink.add(state);
    }
  }

  void _clearAnimationState() {
    /// clear changeType state to prevent server animations running
    state.changeType = null;
    state.requestSucceeded = null;
  }

  void setSelected(bool selected) {
    _clearAnimationState();
    if (state.selected != selected) {
      state.selected = selected;
      _controller.sink.add(state);
    }
  }

  void setRowSelected(bool rowSelected) {
    _clearAnimationState();
    if (state.rowSelected != rowSelected) {
      state.rowSelected = rowSelected;

      _controller.sink.add(state);
    }
  }

  void setColSelected(bool colSelected) {
    _clearAnimationState();
    if (state.colSelected != colSelected) {
      state.colSelected = colSelected;

      _controller.sink.add(state);
    }
  }

  void _checkSelectionStatus() {
    /// never rebuild a selected cell on the hover event to prevent an
    /// unnecessary cell rebuild and the user loosing current edits in the
    /// selected cell.
    if (state.selected != true) {
      _controller.sink.add(state);
    }
  }

  void setHovered(bool hovered) {
    _clearAnimationState();
    if (state.hovered != hovered) {
      state.hovered = hovered;
      _checkSelectionStatus();
    }
  }

  void setRowHovered(bool rowHovered) {
    _clearAnimationState();
    if (state.rowHovered != rowHovered) {
      state.rowHovered = rowHovered;
      _checkSelectionStatus();
    }
  }

  void setColHovered(bool colHovered) {
    _clearAnimationState();
    if (state.colHovered != colHovered) {
      state.colHovered = colHovered;
      _checkSelectionStatus();
    }
  }

  void setRowChecked(bool? rowChecked) {
    _clearAnimationState();
    if (state.rowChecked != rowChecked) {
      state.rowChecked = rowChecked;
      _checkSelectionStatus();
    }
  }

  void setColumnSorted(bool? columnSorted) {
    if (state.columnSorted != columnSorted) {
      state.columnSorted = columnSorted;
      _controller.sink.add(state);
    }
  }

  void setColumnFiltered(bool columnFiltered) {
    if (state.columnFiltered != columnFiltered) {
      state.columnFiltered = columnFiltered;
      _controller.sink.add(state);
    }
  }

  void setRequestInProgress(bool requestInProgress) {
    if (state.requestInProgress != requestInProgress) {
      state.requestInProgress = requestInProgress;
      _controller.sink.add(state);
    }
  }

  void setRequestSucceeded(bool requestSucceeded) {
    if (state.requestSucceeded != requestSucceeded) {
      state.requestSucceeded = requestSucceeded;
      _controller.sink.add(state);
    }
  }

  void setRequestDetails(bool requestInProgress, bool requestSucceeded) {
    if (state.requestInProgress != requestInProgress ||
        state.requestSucceeded != requestSucceeded) {
      state.requestSucceeded = requestSucceeded;
      state.requestInProgress = requestInProgress;
      _controller.sink.add(state);
    }
  }

  void setChangeType(ChangeTypes? changeType) {
    if (state.changeType != changeType) {
      state.changeType = changeType;
      _controller.sink.add(state);
    }
  }

  void dispose() {
    _controller.close();
  }
}
