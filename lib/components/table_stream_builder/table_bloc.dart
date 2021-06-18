part of premo_table;

class TableBloc<T extends IUniqueParentChildRow> {
  /// stream of data model to be displayed in the table
  final Stream<List<T>> inputStream;

  /// column ui elements (column headers and column cells) will be generated for
  /// each column name provided
  final List<String> columnNames;

  /// value to display in each cell of the user interface. col is the index of
  /// current column in the [columnNames] array
  final dynamic Function(T? rowModel, int columnIndex) cellValueBuilder;

  /// count of total rows to render in the user interface
  final int? rowsToRender;

  /// Whether the data coming in from the stream is already sorted by id in
  /// alphanumeric order. Data must be sorted alphanumerically for the internal
  /// set difference algorithms (that run on new stream events) to operate.
  final bool streamAlphanumericSorted;

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
    this.streamAlphanumericSorted = false,
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
      /// ensure all stream data is sorted in the correct order
      _alphaNumericSort(event);

      if (tableState == null) {
        /// case 1 - initial event released

        // initialise table state and release on internal stream
        _initBloc(event);
      } else {
        /// case 2 - otherwise - updated server data recieved
        // update view with all data changes (UPDATES, ADDS, DELETES)
        refresh(event);
      }
    });
  }

  ///
  /// **************************** Private functions ***************************
  ///

  void _alphaNumericSort(List<T> data) {
    if (!streamAlphanumericSorted) {
      data.sort((a, b) {
        return a.getId().compareTo(b.getId());
      });
    }
  }

  void _initBloc(List<T> event) {
    /// ui layer properties
    CellBloc uiLegendCell = CellBloc(initialState: CellBlocState(value: ''));
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
      CellBloc columnHeader =
          CellBloc(initialState: CellBlocState(value: columnName));
      ColumnState columnState = ColumnState();

      uiColumnHeaders.add(columnHeader);
      uiColumnStates.add(columnState);
    }

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

  PremoTableRow<T> _createUiRow(T rowModel, [ChangeTypes? changeType]) {
    /// generate the row
    PremoTableRow<T> ptRow = PremoTableRow(
      model: rowModel,
      rowHeaderCell: CellBloc(
        initialState: CellBlocState(
          value: '',
          changeType: changeType,
        ),
      ),
      cells: [],
    );

    /// generate row cells
    for (var col = 0; col < columnNames.length; col++) {
      CellBloc cell = CellBloc(
        initialState: CellBlocState(
          value: cellValueBuilder(rowModel, col),
          changeType: changeType,
        ),
      );
      ptRow.cells.add(cell);
    }

    return ptRow;
  }

  void _informCellSelectionState(
      PremoTableRow<T>? sRow, int? sCol, bool selected) {
    if (sRow != null && sCol != null) {
      CellBloc rowHeader = sRow.rowHeaderCell;
      CellBloc cell = sRow.cells[sCol];
      CellBloc columnHeader = tableState!.uiColumnHeaders[sCol];

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

  void _informRowSelectionState(PremoTableRow<T>? sRow, bool selected) {
    if (!enableRowSelectionEvents) {
      return;
    } else if (sRow != null) {
      // get cell blocs for row
      List<CellBloc> sRowCellBlocs = sRow.cells;

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

  void _informCellHoverState(PremoTableRow<T>? hRow, int? hCol, bool hovered) {
    if (hRow != null && hCol != null) {
      TableState<T> state = tableState!;
      CellBloc rowHeader = hRow.rowHeaderCell;
      CellBloc cell = hRow.cells[hCol];
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

  void _informRowHoverState(PremoTableRow<T>? hRow, bool selected) {
    if (!enableRowHoverEvents) {
      return;
    }

    if (hRow != null) {
      /// get cell blocs for row
      List<CellBloc> hRowCellBlocs = hRow.cells;

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

  void _renderSortAndFilter() {
    /// update sort state if applicable
    tableState!.sortedDataCache = _sort(tableState!.dataCache);

    /// apply filters to data, returns a new list if filters are applied and
    /// a list reference if no filters are applied.
    List<PremoTableRow<T>> dataToView = _filter(tableState!.sortedDataCache);

    /// store data model in ui
    tableState!.uiDataCache = dataToView;

    /// clear animation states on sort / filter
    tableState!.uiDataCache.forEach((ptRow) {
      ptRow.cells.forEach((cell) {
        cell.state.requestSucceeded = null;
      });
    });

    /// render the new view
    _controller.sink.add(tableState!);
  }

  ///
  /// ******************************* Public API *******************************
  ///

  /// [select] sets the selected cell to the specific row and column passed.
  ///
  /// Will store the selection details in local cache and also release events
  /// to the old and new selected cell ui elements.
  void select(PremoTableRow<T>? newRow, int? newColumn) {
    TableState<T> state = tableState!;

    /// get old selection details
    int? oldColumn = state.uiSelectedColumn;
    PremoTableRow<T>? oldRow = state.selectedRowReference;

    if (newRow != oldRow || newColumn != oldColumn) {
      /// case 1 - row and column changed
      _informCellSelectionState(oldRow, oldColumn, false);
      _informCellSelectionState(newRow, newColumn, true);
    }

    if (newRow != oldRow) {
      /// case 2 - row changed
      _informRowSelectionState(oldRow, false);
      _informRowSelectionState(newRow, true);
    }

    if (newColumn != oldColumn) {
      /// case 3 - column changed
      _informColumnSelectionState(oldColumn, false);
      _informColumnSelectionState(newColumn, true);
    }

    /// update selection status tracking
    oldRow?.selected = false;
    newRow?.selected = true;

    /// update new state
    state.uiSelectedColumn = newColumn;
    state.selectedRowReference = newRow;
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
  void hover(PremoTableRow<T>? newRow, int? newColumn) {
    TableState<T> state = tableState!;

    /// get old details
    int? oldColumn = state.uiHoveredColumn;
    PremoTableRow<T>? oldRow = state.hoveredRowReference;

    if (newRow != oldRow || newColumn != oldColumn) {
      /// case 1 - row or column changed
      /// must be first to prevent child cell stream firing twice. i.e. once on
      /// row or column selection state change, then once on the cell selection
      /// state change
      _informCellHoverState(oldRow, oldColumn, false);
      _informCellHoverState(newRow, newColumn, true);
    }

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

    /// update hovered status tracking
    oldRow?.hovered = false;
    newRow?.hovered = true;

    /// update new state
    state.uiHoveredColumn = newColumn;
    state.hoveredRowReference = newRow;
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

  void check(PremoTableRow<T> row, bool newChecked) {
    /// get element in ui
    bool oldChecked = row.checked;
    if (oldChecked != newChecked) {
      _updateCheckCount(oldChecked, newChecked);

      /// update state
      row.checked = newChecked;

      /// update ui elements
      _informCheckedStatus(row, newChecked);
    }
  }

  void checkAll(bool newChecked) {
    /// update user interface elements
    List<PremoTableRow<T>> uiRows = tableState!.uiDataCache;
    for (var r = 0; r < uiRows.length; r++) {
      check(uiRows[r], newChecked);
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
      _renderSortAndFilter();
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

    _renderSortAndFilter();
  }

  /// Set difference algorithm can be visualised at as a Venn Diagram.
  ///
  /// Assumptions are:
  /// - inputs lists are sorted alphanumerically by get.Id()
  /// - no duplicates in either list
  ///
  /// Sorted Complexity is:
  /// O(n log n) * 2 + 2 * O(n)
  /// Unsorted complexity would be O(n^2)
  ///
  /// Logic is:
  /// Sort list A and B in same order (alpha numeric)
  /// Conduct comparison
  /// case 1 - in both
  /// increment a and b position
  /// case 2 - in a and not b
  /// increment a position
  /// case 3 - in b and not in a
  /// increment b position
  /// case 4 - remaining items in a
  /// case 5 - remaining items in b
  void setDifference({
    required List<T> listA,
    required List<PremoTableRow<T>> listB,
    void Function(T a, PremoTableRow<T> b)? onIntersection,
    void Function(T a)? onSetDifferenceAB,
    void Function(PremoTableRow<T> b)? onSetDifferenceBA,
  }) {
    int a = 0, b = 0;
    // List<PremoTableRow<T>> intersection = [];
    // List<PremoTableRow<T>> setDifferenceAB = [];
    // List<PremoTableRow<T>> setDifferenceBA = [];
    // print('listA.length: ${listA.length}, listB.length: ${listB.length}');
    while (a < listA.length && b < listB.length) {
      T aRow = listA[a];
      PremoTableRow<T> bRow = listB[b];
      String aId = aRow.getId();
      String bId = bRow.model.getId();
      // compare strings by their alphabetical order
      int compare = aId.compareTo(bId);
      // print('aId: $aId, bId: $bId, compare: $compare');
      if (compare == 0) {
        /// case 1 - value in both lists
        // intersection.add(aModel);
        onIntersection?.call(aRow, bRow);
        a++;
        b++;
      } else if (compare < 0) {
        /// case 2 - Set difference A|B - in A and not in B
        // setDifferenceAB.add(aModel);
        onSetDifferenceAB?.call(aRow);
        a++;
        // b = b;
      } else if (compare > 0) {
        /// case 3 - Set difference B|A - in B and not in A
        // setDifferenceBA.add(bModel);
        onSetDifferenceBA?.call(bRow);
        // a = a;
        b++;
      }
    }

    if (a < listA.length) {
      /// case 4 - remaining elements in list A
      for (var i = a; i < listA.length; i++) {
        T aRow = listA[a];
        // setDifferenceAB.add(aModel);
        onSetDifferenceAB?.call(aRow);
      }
    } else if (b < listB.length) {
      /// case 5 - remaining elements in list B
      for (var i = b; i < listB.length; i++) {
        PremoTableRow<T> bRow = listB[b];
        // setDifferenceBA.add(bModel);
        onSetDifferenceBA?.call(bRow);
      }
    }

    // print(
    //     'intersection: ${intersection.length}, setDifferenceAB: ${setDifferenceAB.length}, setDifferenceBA: ${setDifferenceBA.length},');

    // return intersection;
  }

  void _updateCellValues(T eventRow, PremoTableRow<T> oldRow) {
    List<CellBloc> cells = oldRow.cells;
    for (var col = 0; col < cells.length; col++) {
      CellBloc cell = cells[col];
      CellBlocState cellState = cell.state;
      // compare values
      dynamic newValue = cellValueBuilder(eventRow, col);
      dynamic oldValue = cell.state.value;
      if (newValue == oldValue) {
        cell.setChangeType(null);
      } else {
        CellBlocState newState = CellBlocState.clone(cellState);
        newState.value = newValue;
        newState.changeType = ChangeTypes.update;
        cell.setState(newState);
      }
    }
  }

  /// compares the newly recieved stream [event] with the current data in the
  /// table and renders any changes.
  void refresh(List<T> event) {
    List<PremoTableRow<T>> dataToRender = [];
    List<PremoTableRow<T>> deletes = [];
    int oldCheckedRowCount = tableState!.checkedRowCount;
    int added = 0;

    tableState!.eventCache = event;

    setDifference(
      listA: event,
      listB: tableState!.dataCache,
      onIntersection: (T eventRow, PremoTableRow<T> oldRow) {
        /// case 1 - UPDATE
        /// update row model
        oldRow.model = eventRow;

        /// update state
        /// N/A - persisted in existing [oldRow]

        /// update row cells
        /// mark change type
        _updateCellValues(eventRow, oldRow);

        /// update row headers
        /// clear old header cell change types (add or delete)
        oldRow.rowHeaderCell.setChangeType(null);

        /// add array for rendering
        dataToRender.add(oldRow);
      },
      onSetDifferenceAB: (T eventRow) {
        /// case 2 - ADD (in a and not in b)

        /// create new row
        /// update row model
        /// update state
        /// update row cells
        /// mark change type
        /// update row headers
        PremoTableRow<T> newRow = _createUiRow(eventRow, ChangeTypes.add);

        /// add row to array for rendering
        dataToRender.add(newRow);

        /// count rows added
        added++;
      },
      onSetDifferenceBA: (PremoTableRow<T> oldRow) {
        /// case 3 - DELETE (in b and not in a)

        /// get old row

        /// update row model - N/A

        /// update state
        if (oldRow.checked == true) {
          // increment checked status if deleted
          tableState!.checkedRowCount--;
        }

        /// update row cells
        /// mark change type
        List<CellBloc> cells = oldRow.cells;
        for (var col = 0; col < cells.length; col++) {
          CellBloc cell = cells[col];
          cell.setChangeType(ChangeTypes.delete);
        }

        /// update row headers
        oldRow.rowHeaderCell.setChangeType(ChangeTypes.delete);

        /// add row to array for rendering
        dataToRender.add(oldRow);

        /// store deletes
        deletes.add(oldRow);
      },
    );

    /// new list required so sorts can be applied without effecting the original
    /// sort order
    List<PremoTableRow<T>> clone = List.from(dataToRender);

    /// apply filter and sort state from ui
    List<PremoTableRow<T>> sortedData = _sort(clone);
    List<PremoTableRow<T>> uiData = _filter(sortedData);

    /// remove deleted rows so that they are not considered in any future
    /// refresh events
    for (var d = 0; d < deletes.length; d++) {
      PremoTableRow<T> delete = deletes[d];
      dataToRender.remove(delete);
      sortedData.remove(delete);
    }

    /// update state with new data caches
    tableState!.dataCache = dataToRender;
    tableState!.sortedDataCache = sortedData;
    tableState!.uiDataCache = uiData;

    if (oldCheckedRowCount != tableState!.checkedRowCount) {
      // Re-render legend cell
      _informLegendCheckedStatus();
    }

    if (added > 0 || tableState!.markedForDisposal.length > 0) {
      /// Full table render required.
      /// case 1 - new elements added. Therefore new cell streams.
      /// case 2 - ui elements marked for removal (deleted).
      /// Note: Testing confims that releasing the entire table state does not
      /// cause the streams of individual cells to fire again
      _controller.sink.add(tableState!);
    }

    /// clean up deleted blocs to prevent memory leaks
    tableState!.disposeRows(tableState!.markedForDisposal);

    /// store new deletes for clean up in future refreshes
    tableState!.markedForDisposal = deletes;
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
      CellBlocState newState = CellBlocState.clone(cellBlocState);
      newState.requestInProgress = true;
      newState.value = newValue;
      // release state to listeners
      cellBloc.setState(newState);

      /// perform onChange request
      onUpdate?.call(rowModel, columnIndex, newValue).then((_) {
        /// case 1 - async request performed successfully
        /// if onUpdate is returned after a new stream (refresh) event then the
        /// cell component will be rebuilt to suit
        cellBloc.setRequestDetails(false, true);

        /// release details on stream
        /// N/A - updated cell recieved in new table data stream event
      }).catchError((e) {
        /// case 1 - error in async request
        /// update state
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

// part 'table_bloc_event_manager.dart';

// part of premo_table;

// ///
// /// ***************************** Server Events ********************************
// ///

// class ServerEvent<T extends IUniqueIdentifier> {
//   final String type;
//   final T row;

//   ServerEvent({
//     required this.type,
//     required this.row,
//   }) : assert(['add', 'delete', 'update'].contains(type),
//             'change type must be add, delete or update');
// }

// /// represents a stream event fed to the premotable. Allows specification of
// /// data event changes in the form of 'add', 'delete' and 'update'.
// class PremoTableSnapshot<T extends IUniqueIdentifier> {
//   final List<T> data;
//   final List<ServerEvent<T>> changes;

//   PremoTableSnapshot({
//     required this.data,
//     required this.changes,
//   });
// }

// ///
// /// ***************************** User Events ********************************
// ///

// // class ITableEvent<T extends IUniqueIdentifier> {}

// class UpdateEvent<T extends IUniqueIdentifier> {
//   final T row;
//   final int colIndex;
//   final dynamic oldValue;
//   final dynamic newValue;
//   bool requestInProgress;
//   bool? requestSucceeded;

//   UpdateEvent({
//     required this.row,
//     required this.colIndex,
//     required this.oldValue,
//     required this.newValue,
//     required this.requestInProgress,
//     required this.requestSucceeded,
//   });
// }

// class EventManager<T extends IUniqueIdentifier> {
//   /// local store of all events occuring on table
//   List<UpdateEvent<T>> eventCache = [];

//   EventManager();

//   UpdateEvent<T>? getPendingUpdateEvent(T row, int colIndex) {
//     for (var e = 0; e < eventCache.length; e++) {
//       UpdateEvent<T> event = eventCache[e];

//       if (event.colIndex == colIndex &&
//           event.row.id == row.id &&
//           event.requestInProgress == true) {
//         /// case 1 - update found
//         return event;
//       }
//     }

//     /// case 2 - no updates
//     return null;
//   }

//   void addUpdateEvent(UpdateEvent<T> update) {
//     eventCache.add(update);
//   }
// }
