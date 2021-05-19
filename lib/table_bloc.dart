part of premo_table;

class TableBloc<T extends IUniqueParentChildRow> {
  /// stream of data model to be displayed in the table
  final Stream<List<T>> inputStream;

  /// column ui elements (column headers and column cells) will be generated for
  /// each column name provided
  final List<String> columnNames;
  // updateing to JSON data would have additional benefits that the map names can
  // be passed and therefore underlying data can be accessed in the BLOC and also
  // in areas such as filters and sorts so specific if functions dont have to be
  // assigned for each uiColumnIndex.
  //   //       columns: [
  //   //   {
  //   //     data: 'id',
  //   //     type: 'numeric',

  //   //   },
  //   //   {
  //   //     data: 'flag',
  //   // 		renderer: flagRenderer
  //   //   },
  //   //   {
  //   //     data: 'currencyCode',
  //   //     type: 'text'
  //   //   },
  //   //   {
  //   //     data: 'currency',
  //   //     type: 'text'
  //   //   },
  //   //   {
  //   //     data: 'level',
  //   //     type: 'numeric',
  //   //     numericFormat: {
  //   //       pattern: '0.0000'
  //   //     }
  //   //   },
  //   //   {
  //   //     data: 'units',
  //   //     type: 'text'
  //   //   },
  //   //   {
  //   //     data: 'asOf',
  //   //     type: 'date',
  //   //     dateFormat: 'MM/DD/YYYY'
  //   //   },
  //   //   {
  //   //     data: 'onedChng',
  //   //     type: 'numeric',
  //   //     numericFormat: {
  //   //       pattern: '0.00%'
  //   //     }
  //   //   }
  //   // ],

  /// value to display in each cell of the user interface. col is the index of
  /// current column in the [columnNames] array
  final dynamic Function(T? rowModel, int columnIndex) cellValueBuilder;

  /// count of total rows to render in the user interface
  final int? rowsToRender;

  /// sort function to run when no sorts are applied to the current table.
  /// Enforces all external data events to be in the correct order. Can be left
  /// null if the assumption that all event data will be provided in the same
  /// order is always true.
  final List<PremoTableRow<T>> Function(List<PremoTableRow<T>> data)?
      defaultSort;

  /// sort [compare] function to run when the public api [sort] is called
  final int Function(int columnIndex, bool ascending, T a, T b)? sortCompare;

  /// filter function to run when the public api [filter] is called
  final bool Function(T rowModel, int columnIndex, String filterValue)?
      onFilter;

  /// update function to execute whenever a cell value is changed
  final Future<void> Function(T rowModel, int columnIndex, String newValue)?
      onUpdate;

  /// add function to run whenever a new row is added
  final Future<void> Function()? onAdd;

  /// delete function to run whenever a row is deleted
  final Future<void> Function(List<T> rowModel)? onDelete;

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
    this.defaultSort,
    this.sortCompare,
    this.onFilter,
    this.onUpdate,
    this.onAdd,
    this.onDelete,
    this.enableCellSelectionEvents = true,
    this.enableRowSelectionEvents = true,
    this.enableColumnSelectionEvents = false,
    this.enableRowHeaderSelectionEvents = true,
    this.enableColumnHeaderSelectionEvents = false,
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

  void _initBloc(List<T> event) {
    /// ui layer properties
    CellBloc uiLegendCell = CellBloc(initialValue: '');
    // initalise ui legend with false row checked state, legend cell is tristate
    // and null initialisation would imply partial checked status
    uiLegendCell.state.rowChecked = false;
    List<CellBloc> uiColumnHeaders = [];
    List<ColumnState> uiColumnStates = [];
    List<PremoTableRow<T>> tableData = _getPremoTableRows(event);

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

    /// pre sort event data
    defaultSort?.call(tableData);

    // List.from used so sorts applied do not effect the original dataCache
    List<PremoTableRow<T>> sortedDataCache = List.from(tableData);

    /// create the intial table state
    tableState = TableState<T>(
      eventCache: event,
      dataCache: tableData,
      sortedDataCache: sortedDataCache,
      uiDataCache: sortedDataCache,
      uiLegendCell: uiLegendCell,
      uiColumnStates: uiColumnStates,
      uiColumnHeaders: uiColumnHeaders,
    );

    /// release state on stream
    _controller.sink.add(tableState!);
  }

  List<PremoTableRow<T>> _getPremoTableRows(List<T> event) {
    List<PremoTableRow<T>> tableData = [];

    /// loop through all [event] data and generate [PremoTableRow]s
    for (var row = 0; row < event.length; row++) {
      T rowModel = event[row];

      PremoTableRow<T> ptRow = _createUiRow(rowModel);

      /// store created elements
      tableData.add(ptRow);
    }
    return tableData;
  }

  PremoTableRow<T> _createUiRow(T rowModel) {
    /// generate the row
    PremoTableRow<T> ptRow = PremoTableRow(
      model: rowModel,
      rowHeaderCell: CellBloc(initialValue: ''),
      cells: [],
    );

    /// generate row cells
    for (var col = 0; col < columnNames.length; col++) {
      CellBloc cell = CellBloc(initialValue: cellValueBuilder(rowModel, col));
      ptRow.cells.add(cell);
    }

    return ptRow;
  }

  void _informCellSelectionState(int? sRow, int? sCol, bool selected) {
    if (sRow != null && sCol != null) {
      TableState<T> state = tableState!;
      PremoTableRow<T> ptRow = state.uiDataCache[sRow];
      CellBloc rowHeader = ptRow.rowHeaderCell;
      CellBloc cell = ptRow.cells[sCol];
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
      List<CellBloc> sRowCellBlocs = state.uiDataCache[sRow].cells;

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
      List<PremoTableRow<T>> ptRows = tableState!.uiDataCache;

      /// loop through all rows
      for (var row = 0; row < ptRows.length; row++) {
        CellBloc cellBloc = ptRows[row].cells[sCol];

        /// change row selection state
        cellBloc.setColSelected(selected);
      }
    }
  }

  void _informCellHoverState(int? hRow, int? hCol, bool hovered) {
    if (hRow != null && hCol != null) {
      TableState<T> state = tableState!;
      PremoTableRow<T> ptRow = state.uiDataCache[hRow];
      CellBloc rowHeader = ptRow.rowHeaderCell;
      CellBloc cell = ptRow.cells[hCol];
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
      List<CellBloc> hRowCellBlocs = tableState!.uiDataCache[hRow].cells;

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
      List<PremoTableRow<T>> uiRows = tableState!.uiDataCache;

      /// loop through all rows
      for (var row = 0; row < uiRows.length; row++) {
        CellBloc cellBloc = uiRows[row].cells[hCol];

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

  void _informCheckedStatus(PremoTableRow<T> ptRow, bool checked) {
    if (enableRowCheckedEvents) {
      _informLegendCheckedStatus();

      /// update cell row checked status
      List<CellBloc> cells = ptRow.cells;
      for (var col = 0; col < cells.length; col++) {
        CellBloc cell = cells[col];
        cell.setRowChecked(checked);
      }

      /// update row header
      ptRow.rowHeaderCell.setRowChecked(checked);
    }
  }

  /// isAscending
  /// true = ascending sort
  /// false = descending sort
  /// null = data left in original order
  List<PremoTableRow<T>> _sort(List<PremoTableRow<T>> data) {
    int? sortColumnIndex = tableState!.sortColumnIndex;
    bool? isAscending = tableState!.isAscending;

    if (sortColumnIndex != null && isAscending != null && sortCompare != null) {
      /// case 1 - sort
      // create new list to prevent loosing the sort order of the original data
      List<PremoTableRow<T>> sortData = List.from(data);
      sortData.sort((a, b) {
        return sortCompare!(
          sortColumnIndex,
          isAscending,
          a.model,
          b.model,
        );
      });
      return sortData;
    }

    /// case 2 - no sort
    return data;
  }

  List<PremoTableRow<T>> _filter(List<PremoTableRow<T>> data) {
    if (onFilter != null) {
      /// case 1 - filter function provided
      List<PremoTableRow<T>> newData = data;

      /// loop through all filters
      for (var col = 0; col < columnNames.length; col++) {
        ColumnState columnState = tableState!.uiColumnStates[col];

        /// check for active filter on column
        String? filterValue = columnState.filterValue;

        if (filterValue != null) {
          newData = newData.where((ptRow) {
            return onFilter!(ptRow.model, col, filterValue.toString());
          }).toList();
        }
      }

      return newData;
    }

    /// case 2 - no filter provided
    return data;
  }

  void _renderNewView(List<PremoTableRow<T>> data) {
    TableState<T> state = tableState!;
    List<PremoTableRow<T>> ptRows = state.uiDataCache;

    /// loop through available render area
    for (var i = 0; i < ptRows.length; i++) {
      PremoTableRow<T> ptRow = ptRows[i];

      /// clear animation states on sort / filter
      ptRow.cells.forEach((cell) {
        cell.state.requestSucceeded = null;
      });

      /// render new data in cells
      _renderRow(ptRow, null, ptRow, null, false);
    }
  }

  void _setViewableData() {
    /// update sort state if applicable
    tableState!.sortedDataCache = _sort(tableState!.dataCache);

    /// apply filters to data, returns a new list if filters are applied and
    /// a list reference if no filters are applied.
    List<PremoTableRow<T>> dataToView = _filter(tableState!.sortedDataCache);

    /// store data model in ui
    tableState!.uiDataCache = dataToView;

    /// render the new view
    _renderNewView(dataToView);
  }

  bool _rowExistsInArray(T? row, List<PremoTableRow<T>> array) {
    if (row == null) {
      return false;
    }
    return array.any((element) {
      return element.model.getId() == row.getId();
    });
  }

  CellBlocState _getCellBlocState(
    PremoTableRow<T> ptRow,
    int columnIndex,
    ChangeTypes? changeType,
  ) {
    bool columnSelected = columnIndex == tableState!.uiSelectedColumn;
    bool columnHovered = columnIndex == tableState!.uiHoveredColumn;
    bool columnSorted = tableState!.sortColumnIndex == columnIndex;
    bool cellSelected =
        enableCellSelectionEvents && ptRow.selected && columnSelected;
    bool rowSelected = enableRowSelectionEvents && ptRow.selected;
    bool cellColumnSelected = enableColumnSelectionEvents && columnSelected;
    bool cellHovered = enableCellHoverEvents && ptRow.hovered && columnHovered;
    bool rowHovered = enableRowHoverEvents && ptRow.hovered;
    bool cellColumnHovered = enableColumnHoverEvents && columnHovered;
    bool cellRowChecked = enableRowCheckedEvents && ptRow.checked;

    CellBlocState cellState = ptRow.cells[columnIndex].state;
    return CellBlocState(
      value: cellValueBuilder(ptRow.model, columnIndex),
      visible: ptRow.visible,
      selected: cellSelected,
      rowSelected: rowSelected,
      colSelected: cellColumnSelected,
      hovered: cellHovered,
      rowHovered: rowHovered,
      colHovered: cellColumnHovered,
      rowChecked: cellRowChecked,
      columnSorted: columnSorted,
      requestInProgress: cellState.requestInProgress,
      requestSucceeded: cellState.requestSucceeded,
      changeType: changeType,
    );
  }

  CellBlocState _getRowHeaderCellBlocState(
    PremoTableRow<T> ptRow,
    ChangeTypes? changeType,
  ) {
    bool rowSelected = enableRowHeaderSelectionEvents && ptRow.selected;
    bool rowHovered = enableRowHeaderHoverEvents && ptRow.hovered;
    bool rowChecked = enableRowCheckedEvents && ptRow.checked;

    return CellBlocState(
      value: '',
      visible: ptRow.visible,
      rowSelected: rowSelected,
      rowHovered: rowHovered,
      rowChecked: rowChecked,
      // TODO - management of request status state.
      requestInProgress: false,
      requestSucceeded: null,
      changeType: changeType,
    );
  }

  void _renderCell(CellBloc cell, CellBlocState newState) {
    cell.setState(newState);
  }

  void _renderRowHeader(
    PremoTableRow<T>? rowToRender,
    PremoTableRow<T> uiRow,
    ChangeTypes? rowChangeType,
  ) {
    /// determine new rowHeader state
    CellBlocState uiRowHeaderState;
    if (rowToRender != null) {
      /// case 1 - data exists for render location
      uiRowHeaderState = _getRowHeaderCellBlocState(rowToRender, rowChangeType);
    } else {
      /// case 2 - data does not exist for render location
      uiRowHeaderState = CellBlocState(
        value: null,
        visible: false,
        changeType: rowChangeType,
      );
    }

    /// render new rowheader state
    _renderCell(uiRow.rowHeaderCell, uiRowHeaderState);
  }

  void _renderRow(
    PremoTableRow<T>? newRenderRow,
    PremoTableRow<T>? oldRenderRow,
    PremoTableRow<T> uiRow,
    ChangeTypes? rowChangeType,
    bool informCellUpdates,
  ) {
    /// update cell renders
    List<CellBloc> uiCells = uiRow.cells;
    for (var col = 0; col < uiCells.length; col++) {
      CellBloc uiCell = uiCells[col];
      CellBlocState uiCellState;

      if (newRenderRow != null) {
        /// case 1 - data exists for render location
        uiCellState = _getCellBlocState(newRenderRow, col, rowChangeType);
      } else {
        /// case 2 - data does not exist for render location
        uiCellState = CellBlocState(
          value: null,
          visible: false,
          changeType: rowChangeType,
        );
      }

      if (informCellUpdates && newRenderRow != null && oldRenderRow != null) {
        /// release updates on state
        dynamic newValue = uiCellState.value;
        dynamic oldValue = cellValueBuilder(oldRenderRow.model, col);
        if (!(newValue == oldValue)) {
          uiCellState.changeType = ChangeTypes.update;
        }
      }

      /// render new cell state
      _renderCell(uiCell, uiCellState);
    }

    /// render new row header states
    _renderRowHeader(newRenderRow, uiRow, rowChangeType);

    /// TODO - Is this required now?
    // /// update state attached to render
    // if (newRenderRow != null) {
    //   uiRow.checked = newRenderRow.checked;
    //   uiRow.hovered  = newRenderRow.hovered;
    //   uiRow.cells = newRenderRow.cells;
    //   uiRow.rowHeaderCell = newRenderRow.rowHeaderCell;
    //   uiRow.selected  = newRenderRow.selected;
    //   uiRow.visible  = newRenderRow.visible;
    // } else {
    //   uiRow.rowState = RowState(
    //     rowModel: null,
    //     cellStates: Map<int, CellState>(),
    //   );
    // }
  }

  void _renderRowChanges(
    List<PremoTableRow<T>> ptRows,
    int uiPos,
    PremoTableRow<T>? newRowToRender,
    PremoTableRow<T>? oldRowRendered,
    ChangeTypes? rowChangeType,
  ) {
    PremoTableRow<T> ptRow;

    /// get row to render
    ptRow = ptRows[uiPos];

    if (rowChangeType == ChangeTypes.update) {
      /// case 1 - update to render
      _renderRow(newRowToRender, oldRowRendered, ptRow, null, true);
    } else if (rowChangeType == ChangeTypes.duplicate) {
      /// case 2 - duplicate to render
      _renderRow(newRowToRender, null, ptRow, rowChangeType, false);
    } else if (rowChangeType == ChangeTypes.add) {
      /// case 3 - add to render
      _renderRow(newRowToRender, null, ptRow, rowChangeType, false);
    } else if (rowChangeType == ChangeTypes.delete) {
      /// case 4 - delete to render
      _renderRow(null, null, ptRow, rowChangeType, false);
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
    PremoTableRow<T>? oldRowReference = state.selectedRowReference;

    /// get new selection details
    PremoTableRow<T>? newRowReference =
        newRow != null ? state.uiDataCache[newRow] : null;

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
    oldRowReference?.selected = false;
    newRowReference?.selected = true;

    /// update new state
    state.uiSelectedRow = newRow;
    state.uiSelectedColumn = newColumn;
    state.selectedRowReference = newRowReference;
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
    PremoTableRow<T>? oldRowReference = state.hoveredRowReference;

    /// get new details
    PremoTableRow<T>? newRowReference =
        newRow != null ? state.uiDataCache[newRow] : null;

    if (newRow != oldRow) {
      /// case 1 - row changed
      /// HOLD - row and cell hover state changes firing cell hover state?
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
    oldRowReference?.hovered = false;
    newRowReference?.hovered = true;

    /// update new state
    state.uiHoveredRow = newRow;
    state.uiHoveredColumn = newColumn;
    state.hoveredRowReference = newRowReference;
  }

  void dehover() {
    hover(null, null);
  }

  void _updateCheckCount(bool oldChecked, bool newChecked) {
    /// track checked status
    if (oldChecked == false && newChecked == true) {
      tableState!.checkedRowCount++;
    } else if (oldChecked == true && newChecked == false) {
      tableState!.checkedRowCount--;
    }
  }

  void check(int row, bool newChecked) {
    /// get element in ui
    TableState<T> state = tableState!;
    PremoTableRow<T> ptRow = state.uiDataCache[row];
    bool oldChecked = ptRow.checked;
    if (oldChecked != newChecked) {
      _updateCheckCount(oldChecked, newChecked);

      /// update state
      ptRow.checked = newChecked;

      /// update ui elements
      _informCheckedStatus(ptRow, newChecked);
    }
  }

  void checkAll(bool newChecked) {
    /// update user interface elements
    List<PremoTableRow<T>> uiRows = tableState!.uiDataCache;
    for (var r = 0; r < uiRows.length; r++) {
      check(r, newChecked);
    }

    /// ensure state updated correctly for case when there is a render limit
    /// applied
    List<PremoTableRow<T>> rows = tableState!.dataCache;
    for (var r = 0; r < rows.length; r++) {
      PremoTableRow<T> row = rows[r];
      _updateCheckCount(row.checked, newChecked);
      row.checked = newChecked;
    }

    /// update legend cell to suit
    _informLegendCheckedStatus();
  }

  List<PremoTableRow<T>> getChecked() {
    return tableState!.dataCache.where((e) {
      return e.checked == true;
    }).toList();
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

      /// inform column header to rebuild
      CellBloc columnHeader = tableState!.uiColumnHeaders[col];

      /// determine filter status
      if ([null, ''].contains(newFilter)) {
        /// case 1 - no filter applied
        columnHeader.setColumnFiltered(false);
      } else {
        /// case 2 - filter applied
        columnHeader.setColumnFiltered(true);
      }

      /// update displayed data
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

  /// TODO - Are these required?
  // PremoTableRow<T>? _findUIRow(PremoTableRow<T> ptRow) {
  //   for (var i = 0; i < tableState!.uiDataCache.length; i++) {
  //     if (tableState!.uiDataCache[i].model.getId() == ptRow.model.getId()) {
  //       return tableState!.uiDataCache[i];
  //     }
  //   }
  // }

  // CellBloc? _findUICell(PremoTableRow<T> ptRow, int uiColumnIndex) {
  //   PremoTableRow<T>? uiRow = _findUIRow(ptRow);
  //   return uiRow?.cells[uiColumnIndex];
  // }

  // /// assumptions
  // /// - inputs lists are sorted in the same order
  // /// - no duplicates in either list
  // List<int> setDifference(List<int> listA, List<int> listB) {
  //   int a = 0, b = 0;
  //   List<int> intersection = [];
  //   List<int> setDifferenceAB = [];
  //   List<int> setDifferenceBA = [];

  //   while (a < listA.length || b < listB.length) {
  //     if (listA[a] == listB[b]) {
  //       /// case 1 - value in both lists
  //       a++;
  //       b++;
  //       intersection.add(listA[a]);
  //     } else if (listA[a] < listB[b]) {
  //       /// case 2 - Set difference A|B - in A and not in B
  //       a++;
  //       // b = b;
  //       setDifferenceAB.add(listA[a]);
  //     } else if (listA[a] > listB[b]) {
  //       /// case 3 - Set difference B|A - in B and not in A
  //       // a = a;
  //       b++;
  //       setDifferenceBA.add(listB[b]);
  //     }
  //   }

  //   print('intersection: ${intersection.toString()}');
  //   print('A|B: ${setDifferenceAB.toString()}');
  //   print('B|A: ${setDifferenceBA.toString()}');

  //   return intersection;
  // }

  /// TODO - Requires thorough test
  /// aligns the newly recieved [eventData] with the current user interface
  ///
  /// outputs events for updated, added, delete data and persists any user state
  void refresh(List<T> newEventData) {
    /// TODO - look at refactor of how premoTable Rows are generated?
    List<PremoTableRow<T>> newData = _getPremoTableRows(newEventData);

    /// ensure new and old data sets are in the same order
    defaultSort?.call(newData);

    /// copy of newData required so existing ui sorts can be applied without
    /// effecting the original sort order
    /// sync ui data arrangement with newData (apply filters and sort)
    List<PremoTableRow<T>> newDataSorted = _sort(newData);
    // filter will return a new list if a filter is applied and a list reference
    // if no filter is applied
    List<PremoTableRow<T>> newUiData = _filter(newDataSorted);

    /// data references used in comparison
    // List<RowState<T>> oldData = tableState!.dataCache;
    List<PremoTableRow<T>> oldDataSorted = tableState!.sortedDataCache;
    List<PremoTableRow<T>> oldUiData = tableState!.uiDataCache;

    /// compare statistics
    // rows added in newData
    int added = 0;
    // rows removed in newData
    int deleted = 0;
    // duplicate rows in newData
    int duplicates = 0;

    /// required for detecting when the legend should be rendered
    int oldCheckedRowCount = tableState!.checkedRowCount;

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
    // count of rows in old data that exceed the newData length
    int excessOldData = 0;

    for (var newDataPos = 0;
        newDataPos < newDataSorted.length + excessOldData;
        newDataPos++) {
      // old data row to compare with newData row
      // if a row has been deleted compare against the next item
      // if a row has been added  then compare against the previous item
      int oldDataPos = newDataPos + deleted - added - duplicates;

      // update ui position
      // duplicates and adds are rendered in the newUiPos parameter
      uiPos = newUiPos + uiDeleted;

      /// get rows to compare
      PremoTableRow<T>? newDataRow =
          newDataPos < newDataSorted.length ? newDataSorted[newDataPos] : null;
      PremoTableRow<T>? oldDataRow =
          oldDataPos < oldDataSorted.length ? oldDataSorted[oldDataPos] : null;

      /// Rows for duplicate checks
      PremoTableRow<T>? previousNewDataRow =
          newDataPos != 0 && newDataPos - 1 < newDataSorted.length
              ? newDataSorted[newDataPos - 1]
              : null;

      /// get rows to be rendered
      PremoTableRow<T>? newUiRow =
          newUiPos < newUiData.length ? newUiData[newUiPos] : null;
      PremoTableRow<T>? oldUiRow =
          oldUiPos < oldUiData.length ? oldUiData[oldUiPos] : null;

      /// compare rows and determine change case
      ChangeTypes? changeType;
      if (newDataRow != null &&
          newDataRow.model.getId() == oldDataRow?.model.getId()) {
        /// case 1 - UPDATE
        changeType = ChangeTypes.update;
      } else if (newDataRow != null &&
          (newDataRow.model.getId() == previousNewDataRow?.model.getId())) {
        /// case 2 - DUPLICATE
        changeType = ChangeTypes.duplicate;
      } else if (newDataRow != null &&
          !_rowExistsInArray(newDataRow.model, oldDataSorted)) {
        /// case 2 - ADD
        changeType = ChangeTypes.add;
      } else if (oldDataRow != null &&
          !_rowExistsInArray(oldDataRow.model, newDataSorted)) {
        /// case 3 - DELETE
        changeType = ChangeTypes.delete;
      }

      /// roll over rowState
      /// only time there is existing state is if an old row exists
      if (oldDataRow != null &&
          changeType == ChangeTypes.delete &&
          oldDataRow.checked == true) {
        tableState!.checkedRowCount--;
      }
      if (oldDataRow != null && newDataRow != null) {
        if (changeType == ChangeTypes.update) {
          newDataRow.checked = oldDataRow.checked;
          newDataRow.hovered = oldDataRow.hovered;
          newDataRow.selected = oldDataRow.selected;
          newDataRow.visible = oldDataRow.visible;
          newDataRow.cells = oldDataRow.cells;

          if (newDataRow.selected == true) {
            /// update selected row references
            tableState!.uiSelectedRow = uiPos;
            tableState!.selectedRowReference = newDataRow;
          }

          if (newDataRow.hovered == true) {
            /// update hovered row references
            tableState!.uiHoveredRow = uiPos;
            tableState!.hoveredRowReference = newDataRow;
          }
        }
      }

      /// *********************** commence rendering data **********************
      // old or new data must exist for it to be possible to render a row

      /// ensure new render rows are made available for dataset
      // TODO - Is this required? Same issue with creating new PremoTableRows
      // on refresh events
      // if (newDataPos + deleted >= uiRows.length) {
      //   /// case 1 - no row available
      //   RowState<T> rowState = RowState(
      //     rowModel: null,
      //     cellStates: Map<int, CellState>(),
      //   );
      //   UiRow<T> uiRow = _createUiRow(rowState);
      //   uiRows.add(uiRow);
      // }

      // /// case 2 - row available... do nothing

      // current old data row was rendered in the ui
      if (oldDataRow != null &&
          oldDataRow == oldUiRow &&
          changeType != ChangeTypes.duplicate &&
          changeType != ChangeTypes.add) {
        /// update old ui position to check in next loop
        oldUiPos++;
      }

      /// handle all render cases
      if (changeType == ChangeTypes.delete) {
        if (oldDataRow == oldUiRow) {
          /// case 1 - rendering a deleted row
          _renderRowChanges(
              newUiData, uiPos, newDataRow, oldDataRow, changeType);

          /// track that a deleted row has been rendered
          uiDeleted++;
        }
      } else if (newDataRow != null && newDataRow == newUiRow) {
        /// case 3 - rendering a added or updated row
        /// data within render criteria

        _renderRowChanges(newUiData, uiPos, newDataRow, oldDataRow, changeType);

        /// update new ui position
        newUiPos++;
      }

      /// *********************** end rendering data **********************

      /// update position details
      if (changeType == ChangeTypes.add) {
        added++;
      } else if (changeType == ChangeTypes.delete) {
        deleted++;
        // repeat comparison for current row
        newDataPos--;
      } else if (changeType == ChangeTypes.duplicate) {
        duplicates++;
      }

      /// Check for loop end conditions
      /// must look at every row in the new and old data set to determine what
      /// render case should be applied for each item.
      /// note: >= used to prevent infinite loops when lists are of different
      /// lengths
      // case 1 - all newData has been assessed
      bool allNewDataCompared = newDataPos >= newDataSorted.length - 1;
      // case 2 - all oldData has been assessed
      bool allOldDataCompared = oldDataPos >= oldDataSorted.length - 1;

      if (allNewDataCompared && !allOldDataCompared) {
        /// repeat until all old data has been assessed
        excessOldData++;
      }
    }

    /// render remaining rows not included in above render e.g. filtered out data
    /// ensures for case where data has been deleted and rendered. Then refreshed
    /// that the old row positions including the delete count are cleaned up.
    for (var i = newUiPos + uiDeleted; i < newUiData.length; i++) {
      _renderRow(null, null, newUiData[i], null, false);
    }

    /// update viewed data cache
    tableState!.dataCache = newData;
    tableState!.sortedDataCache = newDataSorted;
    tableState!.uiDataCache = newUiData;

    /// add or remove rows from the render
    int rowsRequiredForRender = newUiData.length + deleted;
    int rowChange = (rowsRequiredForRender - oldUiData.length);

    if (rowChange > 0) {
      /// case 1 - rows added to render
      _controller.sink.add(tableState!);
    } else if (rowChange < 0) {
      /// case 2 - rows removed from render
      List<PremoTableRow<T>> removedUIRows = [];
      for (var i = 0; i < rowChange.abs(); i++) {
        removedUIRows.add(newUiData.removeLast());
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

  /// Performs update to a row as requested by a user
  void update(
    PremoTableRow<T> ptRow,
    int columnIndex,
    String newValue,
    String oldValue,
  ) {
    CellBloc cellBloc = ptRow.cells[columnIndex];
    CellBlocState cellBlocState = cellBloc.state;
    T rowModel = ptRow.model;

    /// check if there are any pending changes. Prevents the user issuing more
    /// async requests while one is in progress
    bool requestInProgress = cellBlocState.requestInProgress;
    bool hasValueChanged = newValue != oldValue;

    if (requestInProgress != true && hasValueChanged == true) {
      /// case 1 - value changed and no pending updates

      // update state
      cellBlocState.requestInProgress = true;
      cellBlocState.value = newValue;
      // release state to listeners
      cellBloc.setRequestInProgress(true);

      /// perform onChange request
      onUpdate?.call(rowModel, columnIndex, newValue).then((_) {
        /// case 1 - async request performed successfully
        /// update state
        cellBlocState.requestInProgress = false;
        cellBlocState.requestSucceeded = true;

        /// if onUpdate is returned after a new stream (refresh) event then the
        /// cell component will be rebuilt to suit
        cellBloc.setRequestDetails(false, true);

        /// release details on stream
        /// N/A - updated cell recieved in new table data stream event
      }).catchError((e) {
        /// case 1 - error in async request
        /// update state
        cellBlocState.requestInProgress = false;
        cellBlocState.requestSucceeded = false;

        cellBloc.setRequestDetails(false, false);

        /// inform user of failed update
        // print(e.toString());
      });
    }

    /// case 2 - pending updates against cell. Do nothing.
  }

  /// Not used. all add functionality with external server handled by provided
  /// onAdd callback.
  Future<void>? add() {
    return onAdd?.call();
  }

  Future<void>? delete(List<PremoTableRow<T>> deletes) {
    List<PremoTableRow<T>> deletesToProcess = [];

    /// loop through all deletes
    for (var r = 0; r < deletes.length; r++) {
      PremoTableRow<T> delete = deletes[r];

      /// determine request pending state
      bool requestInProgress = true;
      for (var i = 0; i < columnNames.length; i++) {
        if ([false, null].contains(delete.cells[i].state.requestInProgress)) {
          requestInProgress = false;
        }
      }

      if (requestInProgress != true) {
        /// case 1 - no pending updates

        // update state and release to listeners
        delete.cells.forEach((cell) {
          cell.setRequestInProgress(true);
        });
        // add as delete to process
        deletesToProcess.add(delete);
      }

      /// case 2 - pending updates against cell. Do nothing.
    }
    if (deletesToProcess.length > 0) {
      /// perform request
      return onDelete
          ?.call(deletesToProcess.map((e) => e.model).toList())
          .then((_) {
        /// case 1 - async request performed successfully
        /// release details on stream
        /// N/A - updated cell recieved in new table data stream event
      }).catchError((e) {
        /// case 1 - error in async request
        deletesToProcess.forEach((delete) {
          /// update state and release to listeners
          delete.cells.forEach((cell) {
            cell.setRequestDetails(false, false);
          });
        });

        /// inform user of failed update
        // print(e.toString());
      });
    }
  }

  void undo() {}
  void redo() {}
}
