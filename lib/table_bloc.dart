part of premo_table;

class TableBloc<T extends IUniqueIdentifier> {
  /// Each row provided to the table in the input stream is expected to be
  /// wrapped in a [RowState] class which allows the state of the user
  /// interaction to be persisted no matter where the row is displayed in the ui
  final Stream<List<RowState<T>>> inputStream;

  /// column ui elements (column headers and column cells) will be generated for
  /// each column name provided
  final List<String> columnNames;

  /// value to display in each cell of the user interface. col is the index of
  /// current column in the [columnNames] array
  final dynamic Function(T? rowModel, int columnIndex) cellValueBuilder;

  /// count of total rows to render in the user interface
  final int? rowsToRender;

  /// sort [compare] function to run when no sorts are applied to the current
  /// table. Enforces all external data events to be in the correct order. Can
  /// be left null if the assumption that all event data will be provided in
  /// the same order is always true.
  final int Function(T a, T b)? defaultSortCompare;

  /// sort [compare] function to run when the public api [sort] is called
  final int Function(int columnIndex, bool ascending, T a, T b)? sortCompare;

  /// filter function to run when the public api [filter] is called
  final bool Function(T rowModel, int columnIndex, String filterValue)?
      onFilter;

  /// update function to execute whenever a cell value is changed
  final Future<void> Function(T rowModel, int columnIndex, String newValue)?
      onUpdate;

  /// whether to release events when the cell, row or column selection changes
  final bool enableCellSelectionEvents;
  final bool enableRowSelectionEvents;
  final bool enableColumnSelectionEvents;

  /// whether to release events when the row or column header selection changes
  final bool enableRowHeaderSelectionEvents;
  final bool enableColumnHeaderSelectionEvents;

  /// whether to release events when the cell, row or column hover changes
  final bool enableCellHoverEvents;
  final bool enableRowHoverEvents;
  final bool enableColumnHoverEvents;

  /// whether to release events when the row or column header hover changes
  final bool enableRowHeaderHoverEvents;
  final bool enableColumnHeaderHoverEvents;

  /// whether to release events on streams when the row checked status changes
  final bool enableRowCheckedEvents;

  /// current state of table
  TableState<T>? tableState;

  /// store subscription for cleaning up on BloC disposal
  StreamSubscription? _subscription;

  /// initialise state stream controller
  StreamController<TableState<T>> _controller = StreamController();

  /// expose stream for listening as getter function
  Stream<TableState<T>> get stream {
    return _controller.stream;
  }

  TableBloc({
    required this.inputStream,
    required this.columnNames,
    required this.cellValueBuilder,
    this.rowsToRender,
    this.defaultSortCompare,
    this.sortCompare,
    this.onFilter,
    this.onUpdate,
    this.enableCellSelectionEvents = true,
    this.enableRowSelectionEvents = true,
    this.enableColumnSelectionEvents = false,
    this.enableRowHeaderSelectionEvents = true,
    this.enableColumnHeaderSelectionEvents = true,
    this.enableCellHoverEvents = true,
    this.enableRowHoverEvents = true,
    this.enableColumnHoverEvents = false,
    this.enableRowHeaderHoverEvents = true,
    this.enableColumnHeaderHoverEvents = false,
    this.enableRowCheckedEvents = true,
  }) {
    /// listen to input data stream
    _subscription = inputStream.listen((event) {
      if (tableState == null) {
        /// case 1 - initial event released

        // initialise table state and release on internal stream
        _initBloc(event);
      } else {
        /// case 2 - otherwise - updated server data recieved

        // update the existing view with all changes (UPDATES, ADDS, DELETES) in
        // the new event data
        refresh(event);
      }
    });
  }

  ///
  /// **************************** Private functions ***************************
  ///

  int _getRowsToRender(int dataLength) {
    if (rowsToRender != null && dataLength > rowsToRender!) {
      return rowsToRender!;
    }
    return dataLength;
  }

  void _applyDefaultSort(List<RowState<T>> event) {
    if (defaultSortCompare != null) {
      event.sort((a, b) {
        return defaultSortCompare!(a.rowModel!, b.rowModel!);
      });
    }
  }

  void _initBloc(List<RowState<T>> event) {
    /// pre sort event data
    _applyDefaultSort(event);

    /// ui layer properties
    CellBloc uiLegendCell = CellBloc(initialValue: '');
    // initalise ui legend with false row checked state, legend cell is tristate
    // and null initialisation would imply partial checked status
    uiLegendCell.state.rowChecked = false;
    List<CellBloc> uiColumnHeaders = [];
    List<UiRow<T>> uiRows = [];
    List<ColumnState> uiColumnStates = [];
    int renderLimit = _getRowsToRender(event.length);

    /// loop through all [event] data and generate user interface layer
    for (var row = 0; row < renderLimit; row++) {
      RowState<T> rowState = event[row];
      T? rowModel = rowState.rowModel;

      /// create UI elements
      UiRow<T> uiRow = UiRow(
        rowState: rowState,
        rowHeader: CellBloc(initialValue: ''),
        cellBlocs: [],
      );

      for (var col = 0; col < columnNames.length; col++) {
        /// Create bloc for cell
        CellBloc cell = CellBloc(initialValue: cellValueBuilder(rowModel, col));
        uiRow.cellBlocs.add(cell);
      }

      /// store created elements
      uiRows.add(uiRow);
    }

    /// create columnHeaders - needs to be separate from row generation for case
    /// that an empty array of row data is provided
    for (var col = 0; col < columnNames.length; col++) {
      /// generate column states and column headers for the first row
      String columnName = columnNames[col];
      CellBloc columnHeader = CellBloc(initialValue: columnName);
      ColumnState columnState = ColumnState();

      uiColumnHeaders.add(columnHeader);
      uiColumnStates.add(columnState);
    }

    // List.from used so sorts applied do not effect the original dataCache
    List<RowState<T>> sortedDataCache = List.from(event);

    /// create the intial table state
    tableState = TableState<T>(
      dataCache: event,
      sortedDataCache: sortedDataCache,
      uiDataCache: sortedDataCache,
      uiLegendCell: uiLegendCell,
      uiColumnStates: uiColumnStates,
      uiColumnHeaders: uiColumnHeaders,
      uiRows: uiRows,
    );

    /// release state on stream
    _controller.sink.add(tableState!);
  }

  UiRow<T> _createUiRow(RowState<T> rowState) {
    /// generate the row
    UiRow<T> uiRow = UiRow(
      rowState: rowState,
      rowHeader: CellBloc(initialValue: ''),
      cellBlocs: [],
    );

    /// get the row model from the state if it exists
    T? rowModel = rowState.rowModel;

    /// generate row cells
    for (var col = 0; col < columnNames.length; col++) {
      CellBloc cell = CellBloc(initialValue: cellValueBuilder(rowModel, col));
      uiRow.cellBlocs.add(cell);
    }

    return uiRow;
  }

  void _informCellSelectionState(int? sRow, int? sCol, bool selected) {
    if (sRow != null && sCol != null) {
      TableState<T> state = tableState!;
      UiRow<T> uiRow = state.uiRows[sRow];
      CellBloc rowHeader = uiRow.rowHeader;
      CellBloc cell = uiRow.cellBlocs[sCol];
      CellBloc columnHeader = state.uiColumnHeaders[sCol];

      /// release selection events to ui elements
      if (enableCellSelectionEvents) {
        cell.setSelected(selected);
      }
      if (enableRowHeaderSelectionEvents) {
        rowHeader.setRowSelected(selected);
      }
      if (enableColumnHeaderSelectionEvents) {
        columnHeader.setColSelected(selected);
      }
    }
  }

  void _informRowSelectionState(int? sRow, bool selected) {
    if (!enableRowSelectionEvents) {
      return;
    } else if (sRow != null) {
      // get cell blocs for row
      TableState<T> state = tableState!;
      List<CellBloc> sRowCellBlocs = state.uiRows[sRow].cellBlocs;

      // loop through all cell blocs
      for (var col = 0; col < sRowCellBlocs.length; col++) {
        CellBloc cellBloc = sRowCellBlocs[col];

        // change row selection state
        cellBloc.setRowSelected(selected);
      }
    }
  }

  void _informColumnSelectionState(int? sCol, bool selected) {
    if (!enableColumnSelectionEvents) {
      return;
    } else if (sCol != null) {
      /// get all row blocs
      List<UiRow<T>> uiRows = tableState!.uiRows;

      /// loop through all rows
      for (var row = 0; row < uiRows.length; row++) {
        CellBloc cellBloc = uiRows[row].cellBlocs[sCol];

        /// change row selection state
        cellBloc.setColSelected(selected);
      }
    }
  }

  void _informCellHoverState(int? hRow, int? hCol, bool hovered) {
    if (hRow != null && hCol != null) {
      TableState<T> state = tableState!;
      UiRow<T> uiRow = state.uiRows[hRow];
      CellBloc rowHeader = uiRow.rowHeader;
      CellBloc cell = uiRow.cellBlocs[hCol];
      CellBloc columnHeader = state.uiColumnHeaders[hCol];

      if (enableCellHoverEvents) {
        cell.setHovered(hovered);
      }

      if (enableRowHeaderHoverEvents) {
        rowHeader.setRowHovered(hovered);
      }

      if (enableColumnHeaderHoverEvents) {
        columnHeader.setColHovered(hovered);
      }
    }
  }

  void _informRowHoverState(int? hRow, bool selected) {
    if (!enableRowHoverEvents) {
      return;
    }

    if (hRow != null) {
      /// get cell blocs for row
      List<CellBloc> hRowCellBlocs = tableState!.uiRows[hRow].cellBlocs;

      /// loop through all cell blocs
      for (var col = 0; col < hRowCellBlocs.length; col++) {
        CellBloc cellBloc = hRowCellBlocs[col];

        /// change row selection state
        cellBloc.setRowHovered(selected);
      }
    }
  }

  void _informColumnHoverState(int? hCol, bool selected) {
    if (!enableColumnHoverEvents) {
      return;
    }

    if (hCol != null) {
      /// get all row blocs
      List<UiRow<T>> uiRows = tableState!.uiRows;

      /// loop through all rows
      for (var row = 0; row < uiRows.length; row++) {
        CellBloc cellBloc = uiRows[row].cellBlocs[hCol];

        /// change row selection state
        cellBloc.setColHovered(selected);
      }
    }
  }

  void _informLegendCheckedStatus() {
    /// update status of legend cell
    TableState<T> state = tableState!;
    CellBloc legendCell = state.uiLegendCell;
    bool? newChecked = allRowsChecked();
    // will only release in child stream if checked status changes
    legendCell.setRowChecked(newChecked);
  }

  void _informCheckedStatus(UiRow<T> uiRow, bool checked) {
    if (enableRowCheckedEvents) {
      _informLegendCheckedStatus();

      /// update cell row checked status
      List<CellBloc> cells = uiRow.cellBlocs;
      for (var col = 0; col < cells.length; col++) {
        CellBloc cell = cells[col];
        cell.setRowChecked(checked);
      }

      /// update row header
      uiRow.rowHeader.setRowChecked(checked);
    }
  }

  /// isAscending
  /// true = ascending sort
  /// false = descending sort
  /// null = data left in original order
  void _sort(List<RowState<T>> data) {
    TableState state = tableState!;
    int? sortColumnIndex = state.sortColumnIndex;
    bool? isAscending = state.isAscending;

    if (sortColumnIndex != null && isAscending != null && sortCompare != null) {
      /// case 1 - user sort can applied
      data.sort((a, b) {
        return sortCompare!(
            sortColumnIndex, isAscending, a.rowModel!, b.rowModel!);
      });
    }

    /// case 2 - leave data in original sort
  }

  List<RowState<T>> _filter(List<RowState<T>> data) {
    if (onFilter != null) {
      /// case 1 - filter function provided
      List<RowState<T>> newData = data;

      /// loop through all filters
      for (var col = 0; col < columnNames.length; col++) {
        ColumnState columnState = tableState!.uiColumnStates[col];

        /// check for active filter on column
        String? filterValue = columnState.filterValue;

        if (filterValue != null) {
          newData = newData.where((rowState) {
            return onFilter!(rowState.rowModel!, col, filterValue.toString());
          }).toList();
        }
      }

      return newData;
    }

    /// case 2 - no filter provided
    return data;
  }

  void _renderNewView(List<RowState<T>> data) {
    TableState<T> state = tableState!;
    List<UiRow<T>> uiRows = state.uiRows;

    /// loop through available render area
    for (var i = 0; i < uiRows.length; i++) {
      UiRow<T> uiRow = uiRows[i];

      bool renderDataForRow = (i < data.length);
      RowState<T>? rowToRender;

      if (renderDataForRow) {
        /// case 1 - data exists for render location
        rowToRender = data[i];
      }

      /// render new data in cells
      _renderRow(rowToRender, null, uiRow, null, false);
    }
  }

  void _setViewableData() {
    /// update sort state if applicable
    _sort(tableState!.sortedDataCache);

    /// apply filters to data, returns a new list if filters are applied and
    /// a list reference if no filters are applied.
    List<RowState<T>> dataToView = _filter(tableState!.sortedDataCache);

    /// store data model in ui
    tableState!.uiDataCache = dataToView;

    /// render the new view
    _renderNewView(dataToView);
  }

  bool _rowExistsInArray(T? row, List<RowState<T>> array) {
    if (row == null) {
      return false;
    }
    return array.any((element) {
      return element.rowModel?.uid == row.uid;
    });
  }

  CellBlocState _getCellBlocState(
    RowState<T> rowState,
    int columnIndex,
    ChangeTypes? changeType,
  ) {
    bool columnSelected = columnIndex == tableState!.uiSelectedColumn;
    bool columnHovered = columnIndex == tableState!.uiHoveredColumn;
    bool columnSorted = tableState!.sortColumnIndex == columnIndex;
    bool cellSelected =
        enableCellSelectionEvents && rowState.selected && columnSelected;
    bool rowSelected = enableRowSelectionEvents && rowState.selected;
    bool cellColumnSelected = enableColumnSelectionEvents && columnSelected;
    bool cellHovered =
        enableCellHoverEvents && rowState.hovered && columnHovered;
    bool rowHovered = enableRowHoverEvents && rowState.hovered;
    bool cellColumnHovered = enableColumnHoverEvents && columnHovered;
    bool cellRowChecked = enableRowCheckedEvents && rowState.checked;

    return CellBlocState(
      value: cellValueBuilder(rowState.rowModel, columnIndex),
      visible: rowState.visible,
      selected: cellSelected,
      rowSelected: rowSelected,
      colSelected: cellColumnSelected,
      hovered: cellHovered,
      rowHovered: rowHovered,
      colHovered: cellColumnHovered,
      rowChecked: cellRowChecked,
      columnSorted: columnSorted,
      // TODO - management of request status state.
      requestInProgress: false,
      requestSucceeded: null,
      changeType: changeType,
    );
  }

  CellBlocState _getRowHeaderCellBlocState(
    RowState<T> rowState,
    ChangeTypes? changeType,
  ) {
    bool rowSelected = enableRowHeaderSelectionEvents && rowState.selected;
    bool rowHovered = enableRowHeaderHoverEvents && rowState.hovered;
    bool rowChecked = enableRowCheckedEvents && rowState.checked;

    return CellBlocState(
      value: '',
      visible: rowState.visible,
      rowSelected: rowSelected,
      rowHovered: rowHovered,
      rowChecked: rowChecked,
      // TODO - management of request status state.
      requestInProgress: false,
      requestSucceeded: null,
      changeType: changeType,
    );
  }

  bool _cellBlocStatesChanged(CellBlocState a, CellBlocState b) {
    return !(a.value == b.value &&
        a.visible == b.visible &&
        a.selected == b.selected &&
        a.rowSelected == b.rowSelected &&
        a.colSelected == b.colSelected &&
        a.hovered == b.hovered &&
        a.rowHovered == b.rowHovered &&
        a.colHovered == b.colHovered &&
        a.rowChecked == b.rowChecked &&
        a.columnSorted == b.columnSorted &&
        a.requestInProgress == b.requestInProgress &&
        a.requestSucceeded == b.requestSucceeded &&
        a.changeType == b.changeType);
  }

  void _renderCell(CellBloc cell, CellBlocState newState) {
    bool stateChanged = _cellBlocStatesChanged(newState, cell.state);
    if (stateChanged == true) {
      /// case 1 - state changed - render
      cell.setCellBlocState(newState);
    }
  }

  void _renderRowHeader(
    RowState<T>? rowToRender,
    UiRow<T> uiRow,
    ChangeTypes? rowChangeType,
  ) {
    /// determine new rowHeader state
    CellBlocState uiRowHeaderState;
    if (rowToRender != null) {
      /// case 1 - data exists for render location
      uiRowHeaderState = _getRowHeaderCellBlocState(rowToRender, rowChangeType);
    } else {
      /// case 2 - data does not exist for render location
      uiRowHeaderState = CellBlocState(value: null, changeType: rowChangeType);
    }

    /// render new rowheader state
    _renderCell(uiRow.rowHeader, uiRowHeaderState);
  }

  void _renderRow(
    RowState<T>? newRenderRow,
    RowState<T>? oldRenderRow,
    UiRow<T> uiRow,
    ChangeTypes? rowChangeType,
    bool informCellUpdates,
  ) {
    /// update cell renders
    List<CellBloc> uiCells = uiRow.cellBlocs;
    for (var col = 0; col < uiCells.length; col++) {
      CellBloc uiCell = uiCells[col];
      CellBlocState uiCellState;

      if (newRenderRow != null) {
        /// case 1 - data exists for render location
        uiCellState = _getCellBlocState(newRenderRow, col, rowChangeType);
      } else {
        /// case 2 - data does not exist for render location
        uiCellState = CellBlocState(value: null, changeType: rowChangeType);
      }

      if (informCellUpdates && newRenderRow != null && oldRenderRow != null) {
        /// release updates on state
        dynamic newValue = uiCellState.value;
        dynamic oldValue = cellValueBuilder(oldRenderRow.rowModel, col);
        if (!(newValue == oldValue)) {
          uiCellState.changeType = ChangeTypes.update;
        }
      }

      /// render new cell state
      _renderCell(uiCell, uiCellState);
    }

    /// render new row header states
    _renderRowHeader(newRenderRow, uiRow, rowChangeType);

    /// update state attached to render
    if (newRenderRow != null) {
      uiRow.rowState = newRenderRow;
    } else {
      uiRow.rowState = RowState(
        rowModel: null,
        cellStates: Map<int, CellState>(),
      );
    }
  }

  void _renderRowChanges(
      List<UiRow<T>> uiRows,
      int uiPos,
      RowState<T> newRowToRender,
      RowState<T>? oldRowRendered,
      ChangeTypes? rowChangeType) {
    UiRow<T> uiRow;

    /// confirm there is a row available at the requested render position
    if (uiPos < uiRows.length) {
      /// case 1 - row available
      uiRow = uiRows[uiPos];
    } else {
      /// case 2 - no row available
      RowState<T> rowState = RowState(
        rowModel: null,
        cellStates: Map<int, CellState>(),
      );
      uiRow = _createUiRow(rowState);
      uiRows.add(uiRow);
    }

    if (rowChangeType == ChangeTypes.update) {
      /// case 1 - update to render
      _renderRow(newRowToRender, oldRowRendered, uiRow, null, true);
    } else if (rowChangeType == ChangeTypes.add) {
      /// case 2 - add to render
      _renderRow(newRowToRender, oldRowRendered, uiRow, rowChangeType, false);
    } else if (rowChangeType == ChangeTypes.delete) {
      /// case 3 - delete to render
      _renderRow(null, null, uiRow, rowChangeType, false);
    }
  }

  ///
  /// ******************************* Public API *******************************
  ///

  /// [select] sets the selected cell to the specific row and column passed.
  ///
  /// Will store the selection details in local cache and also release events
  /// to the old and new selected cell ui elements.
  void select(int? newRow, int? newColumn) {
    TableState<T> state = tableState!;

    /// get old selection details
    int? oldRow = state.uiSelectedRow;
    int? oldColumn = state.uiSelectedColumn;
    RowState<T>? oldRowState = state.selectedRowState;

    /// get new selection details
    RowState<T>? newRowState =
        newRow != null ? state.uiRows[newRow].rowState : null;

    if (newRow != oldRow) {
      /// case 1 - row changed
      _informRowSelectionState(oldRow, false);
      _informRowSelectionState(newRow, true);
    }

    if (newColumn != oldColumn) {
      /// case 2 - column changed
      _informColumnSelectionState(oldColumn, false);
      _informColumnSelectionState(newColumn, true);
    }

    if (newRow != oldRow || newColumn != oldColumn) {
      /// case 3 - row and column changed
      _informCellSelectionState(oldRow, oldColumn, false);
      _informCellSelectionState(newRow, newColumn, true);
    }

    /// update selection status tracking
    oldRowState?.selected = false;
    newRowState?.selected = true;

    /// update new state
    state.uiSelectedRow = newRow;
    state.uiSelectedColumn = newColumn;
    state.selectedRowState = newRowState;
  }

  /// [deselect] clears the currently selected cell.
  ///
  /// Will store the selection details in local cache and also release events
  /// to the old selected cell ui elements.
  void deselect() {
    select(null, null);
  }

  /// [hover] sets the hovered cell to the specific row and column passed.
  ///
  /// Will store the hover details in local cache and also release events to the
  /// old and new hovered cell ui elements.
  void hover(int? newRow, int? newColumn) {
    TableState<T> state = tableState!;

    /// get old details
    int? oldRow = state.uiHoveredRow;
    int? oldColumn = state.uiHoveredColumn;
    RowState<T>? oldRowState = state.hoveredRowState;

    /// get new details
    RowState<T>? newRowState =
        newRow != null ? state.uiRows[newRow].rowState : null;

    if (newRow != oldRow) {
      /// case 1 - row changed
      _informRowHoverState(oldRow, false);
      _informRowHoverState(newRow, true);
    }

    if (newColumn != oldColumn) {
      /// case 2 - column changed
      _informColumnHoverState(oldColumn, false);
      _informColumnHoverState(newColumn, true);
    }

    if (newRow != oldRow || newColumn != oldColumn) {
      /// case 3 - row and column changed
      _informCellHoverState(oldRow, oldColumn, false);
      _informCellHoverState(newRow, newColumn, true);
    }

    /// update hovered status tracking
    oldRowState?.hovered = false;
    newRowState?.hovered = true;

    /// update new state
    state.uiHoveredRow = newRow;
    state.uiHoveredColumn = newColumn;
    state.hoveredRowState = newRowState;
  }

  void dehover() {
    hover(null, null);
  }

  void check(int row, bool newChecked) {
    /// get element in ui
    TableState<T> state = tableState!;
    UiRow<T> uiRow = state.uiRows[row];
    RowState<T> rowState = uiRow.rowState;
    bool oldChecked = rowState.checked;
    if (oldChecked != newChecked) {
      /// update state
      rowState.checked = newChecked;

      /// track checked status
      if (newChecked == true) {
        state.checkedRowCount++;
      } else {
        state.checkedRowCount--;
      }

      /// update ui elements
      _informCheckedStatus(uiRow, newChecked);
    }
  }

  void checkAll(bool newChecked) {
    /// update user interface elements
    List<UiRow<T>> uiRows = tableState!.uiRows;
    for (var r = 0; r < uiRows.length; r++) {
      check(r, newChecked);
    }

    /// ensure state updated correctly for case when there is a render limit
    /// applied
    List<RowState<T>> rows = tableState!.dataCache;
    for (var r = 0; r < rows.length; r++) {
      RowState<T> row = rows[r];
      row.checked = newChecked;
    }

    /// update legend cell to suit
    _informLegendCheckedStatus();
  }

  bool? allRowsChecked() {
    if (tableState!.checkedRowCount == tableState!.dataCache.length) {
      /// case 1 - all checked
      return true;
    } else if (tableState!.checkedRowCount == 0) {
      /// case 2 - none checked
      return false;
    } else {
      /// case 3 - partially checked
      return null;
    }
  }

  void filter(int col, String? newFilter) {
    ColumnState columnState = tableState!.uiColumnStates[col];
    String? oldFilter = columnState.filterValue;
    if (oldFilter != newFilter) {
      /// update state
      columnState.filterValue = newFilter;
      _setViewableData();
    }
  }

  void sort(int newColumnIndex) {
    TableState state = tableState!;
    int? oldColumnIndex = state.sortColumnIndex;

    if (newColumnIndex != oldColumnIndex) {
      /// case 1 - user changing sort column
      state.sortColumnIndex = newColumnIndex;
      state.isAscending = true;
      // update old ui column header element
      if (oldColumnIndex != null) {
        CellBloc oldColumn = state.uiColumnHeaders[oldColumnIndex];
        oldColumn.setColumnSorted(null);
      }
    } else {
      /// case 2 - user changing sort order
      if (state.isAscending == true) {
        state.isAscending = false;
      } else if (state.isAscending == false) {
        state.isAscending = null;
      } else {
        state.isAscending = true;
      }
    }

    /// update new column header ui elements
    CellBloc newColumn = state.uiColumnHeaders[newColumnIndex];
    newColumn.setColumnSorted(state.isAscending);

    _setViewableData();
  }

  /// aligns the newly recieved [eventData] with the current user interface
  ///
  /// outputs events for updated, added, delete data and persists any user state
  void refresh(List<RowState<T>> newData) {
    /// ensure new and old data sets are in the same order
    _applyDefaultSort(newData);

    /// copy of newData required so existing ui sorts can be applied without
    /// effecting the original sort order
    List<RowState<T>> newDataSorted = List.from(newData);
    List<RowState<T>> newUiData = newDataSorted;

    /// data references used in comparison
    // List<RowState<T>> oldData = tableState!.dataCache;
    List<RowState<T>> oldDataSorted = tableState!.sortedDataCache;
    List<RowState<T>> oldUiData = tableState!.uiDataCache;

    /// user interface to update comparison results to
    List<UiRow<T>> uiRows = tableState!.uiRows;

    /// limit on how many rows to render in the ui
    int uiRenderLimit = _getRowsToRender(newDataSorted.length);

    /// compare statistics
    // rows added in newData
    int added = 0;
    // rows removed in newData
    int deleted = 0;

    /// required for detecting when new or deleted rows should be rendered
    int rowsAvailableForRender = uiRows.length;
    int oldCheckedRowCount = tableState!.checkedRowCount;

    /// sync ui data arrangement with newData (apply filters and sort)
    _sort(newDataSorted);
    // filter will return a new list if a filter is applied and a list reference
    // if no filter is applied
    newUiData = _filter(newDataSorted);

    /// *********************** commence data comparison ***********************
    /// compare all underlying data so all state is rolled over and new
    /// information is rendered in the view
    /// Note*** This algorithm assumes that the newData, OldData and Ui data are
    /// all in the same order to work correctly

    /// location of the newData in the filtered data array
    int newUiPos = 0;
    // location of the old data in the filtered data array.
    int oldUiPos = 0;
    // location in ui to be rendered
    // if a row has been deleted. That row must remain in the ui.
    // if a row has been added. That is accounted for in the newUiPos prop.
    int uiPos = 0;
    // count of rows deleted from the ui
    int uiDeleted = 0;

    for (var newDataPos = 0; newDataPos < newDataSorted.length; newDataPos++) {
      // old data row to compare with newData row
      // if a row has been deleted compare against the next item
      // if a row has been added  then compare against the previous item
      int oldDataPos = newDataPos + deleted - added;

      // update ui position
      uiPos = newUiPos + uiDeleted;

      /// get rows to compare
      RowState<T> newDataRow = newDataSorted[newDataPos];
      RowState<T>? oldDataRow =
          oldDataPos < oldDataSorted.length ? oldDataSorted[oldDataPos] : null;

      /// get rows to be rendered
      RowState<T>? newUiRow =
          newUiPos < newUiData.length ? newUiData[newUiPos] : null;
      RowState<T>? oldUiRow =
          oldUiPos < oldUiData.length ? oldUiData[oldUiPos] : null;

      /// compare rows and determine change case
      ChangeTypes? changeType;
      if (newDataRow.rowModel!.uid == oldDataRow?.rowModel!.uid) {
        /// case 1 - UPDATE
        changeType = ChangeTypes.update;
      } else if (!_rowExistsInArray(newDataRow.rowModel, oldDataSorted)) {
        /// case 2 - ADD
        changeType = ChangeTypes.add;
      } else if (!_rowExistsInArray(oldDataRow?.rowModel!, newDataSorted)) {
        /// case 3 - DELETE
        changeType = ChangeTypes.delete;
      }

      /// roll over rowState
      /// only time there is existing state is if an old row exists
      if (oldDataRow != null) {
        if (changeType == ChangeTypes.update) {
          newDataRow.checked = oldDataRow.checked;
          newDataRow.hovered = oldDataRow.hovered;
          newDataRow.selected = oldDataRow.selected;
          newDataRow.visible = oldDataRow.visible;
          newDataRow.cellStates = oldDataRow.cellStates;

          if (newDataRow.selected == true) {
            /// update selected row references
            tableState!.uiSelectedRow = newDataPos;
            tableState!.selectedRowState = newDataRow;
          }

          if (newDataRow.hovered == true) {
            /// update hovered row references
            tableState!.uiHoveredRow = newDataPos;
            tableState!.hoveredRowState = newDataRow;
          }
        } else if (changeType == ChangeTypes.delete &&
            tableState!.checkedRowCount != 0) {
          tableState!.checkedRowCount--;
        }
      }

      /// *********************** commence rendering data **********************

      /// update the old ui position
      if (oldDataRow == oldUiRow) {
        oldUiPos++;
      }

      if (changeType == ChangeTypes.delete && oldDataRow == oldUiRow) {
        /// case 1 - rendering a deleted row
        _renderRowChanges(uiRows, uiPos, newDataRow, oldDataRow, changeType);

        /// track that a deleted row has been rendered
        uiDeleted++;
      } else if (newDataRow == newUiRow) {
        /// case 2 - rendering a added or updated row
        /// data within render criteria
        if (newUiPos < uiRenderLimit) {
          _renderRowChanges(uiRows, uiPos, newDataRow, oldDataRow, changeType);
        }

        /// update new ui position
        newUiPos++;
      }

      /// update position details
      if (changeType == ChangeTypes.add) {
        added++;
      } else if (changeType == ChangeTypes.delete) {
        deleted++;
        // repeat comparison for current row
        newDataPos--;
      }
    }

    /// render remaining rows not included in above render e.g. filtered out data
    /// ensures for case where data has been deleted and rendered. Then refreshed
    /// that the old row positions including the delete count are cleaned up.
    for (var i = uiPos + 1; i < uiRows.length; i++) {
      _renderRow(null, null, uiRows[i], null, false);
    }

    /// update viewed data cache
    tableState!.dataCache = newData;
    tableState!.sortedDataCache = newDataSorted;
    tableState!.uiDataCache = newUiData;

    /// add or remove rows from the render
    int rowsRequiredForRender = uiRenderLimit + deleted;
    int rowChange = (rowsRequiredForRender - rowsAvailableForRender);

    if (rowChange > 0) {
      /// case 1 - rows added to render
      _controller.sink.add(tableState!);
    } else if (rowChange < 0) {
      /// case 2 - rows removed from render
      List<UiRow<T>> removedUIRows = [];
      for (var i = 0; i < rowChange.abs(); i++) {
        removedUIRows.add(uiRows.removeLast());
      }

      /// Testing confims that releasing the entire table state does not cause
      /// the streams of individual cells to fire again
      _controller.sink.add(tableState!);

      /// clean up any excess rows in the render to prevent memory leaks from
      /// constant row deletion (deleted rows always add to the render)
      tableState!.disposeRows(removedUIRows);
    }

    if (oldCheckedRowCount != tableState!.checkedRowCount) {
      // Re-render legend cell
      _informLegendCheckedStatus();
    }
  }

  /// clean up variables to prevent memory leaks
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    tableState!.dispose();
  }

  // TODO items
  void undo() {}
  void redo() {}
  void update() {}
  void add() {}
  void delete() {}

  ///
  /// ************************** User CRUD Operations **************************
  ///

  /// TODO - All code below to be completed
  // UiRow? _findUIRow(T rowModel) {
  //   return tableState!.uiRows.firstWhere(
  //     (element) {
  //       return element.rowState.rowModel?.uid == rowModel.uid;
  //     },
  //   );
  // }

  // void _updateCellView(
  //   T rowModel,
  //   UpdateEvent updateEvent,
  // ) {
  //   /// find row in user interface
  //   UiRow? uiRow = _findUIRow(rowModel);

  //   if (uiRow != null) {
  //     /// get the cell ui bloc
  //     CellBloc cellBloc = uiRow.cellBlocs[updateEvent.colIndex];

  //     /// release new cell state on cell stream
  //     cellBloc.applyCellBlocStateToView(
  //       updateEvent.newValue,
  //       updateEvent.requestInProgress,
  //       updateEvent.requestSucceeded,
  //     );
  //   }
  // }

  /// Log of all user data modification events
  // EventManager<T> eventManager = EventManager();

  /// Performs update to a row as requested by a user
  void userUpdate(
    /// row to be updated
    T rowModel,

    /// column in row to update
    int colIndex,

    /// new value to assign to row column
    String newValue,

    /// current value assigned to row column
    String oldValue,
  ) {
    // /// check if there are any pending changes against cell. Prevent the user
    // /// spamming multiple async change requests while one is in progress
    // UpdateEvent? pendingUpdate =
    //     eventManager.getPendingUpdateEvent(rowModel, colIndex);

    // bool hasValueChanged = newValue != oldValue;

    // if (pendingUpdate == null && hasValueChanged == true) {
    //   /// case 1 - value changed and no pending updates
    //   /// create new event
    //   UpdateEvent<T> updateEvent = UpdateEvent(
    //     row: rowModel,
    //     colIndex: colIndex,
    //     newValue: newValue,
    //     oldValue: oldValue,
    //     requestInProgress: true,
    //     requestSucceeded: null,
    //   );

    //   /// add to event cache
    //   eventManager.addUpdateEvent(updateEvent);

    //   /// release event to UI
    //   _updateCellView(rowModel, updateEvent);

    //   /// perform onChange request
    //   /// TODO - row number not required
    //   if (onUpdate != null) {
    //     onUpdate!(rowModel, colIndex, newValue).then((_) {
    //       /// case 1 - async request performed successfully
    //       /// update state
    //       updateEvent.requestInProgress = false;
    //       updateEvent.requestSucceeded = true;

    //       /// release on stream
    //       /// find row in user interface
    //       UiRow? uiRow = _findUIRow(rowModel);

    //       /// update the ui with new new cell state
    //       _updateCellView(rowModel, updateEvent);
    //     }).catchError((e) {
    //       /// case 1 - error in async request
    //       /// update state
    //       updateEvent.requestInProgress = false;
    //       updateEvent.requestSucceeded = false;

    //       /// release on stream
    //       /// find row in user interface
    //       UiRow? uiRow = _findUIRow(rowModel);

    //       /// update the ui with new new cell state
    //       _updateCellView(rowModel, updateEvent);
    //     });
    //   }
    // }

    // /// case 2 - pending updates against cell. Do nothing.
  }
}