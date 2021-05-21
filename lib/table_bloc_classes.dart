part of premo_table;

enum ChangeTypes { update, add, delete, duplicate }

class ColumnState {
  /// filter applied to column, if any
  String? filterValue;

  ColumnState({
    this.filterValue,
  });
}

/// all rows in a [PremoTable] require a unique identifier so all internal BLoC
/// functionality can operate correctly. E.g. update, delete, add, ui state
/// peristance etc.
class PremoTableRow<T extends IUniqueParentChildRow>
    extends IUniqueParentChildRow {
  T model;
  bool selected;
  bool checked;
  bool hovered;
  bool visible;
  CellBloc rowHeaderCell;
  List<CellBloc> cells;

  PremoTableRow({
    /// data model attached to row
    required this.model,

    /// user selected
    this.selected = false,

    /// user marked as checked
    this.checked = false,

    /// user hovering
    this.hovered = false,

    /// row visibility
    this.visible = true,

    /// BLoC for row header cell
    required this.rowHeaderCell,

    /// BLoC for each cell
    required this.cells,
  });

  @override
  String getId() {
    return model.getId();
  }

  @override
  String? getParentId() {
    return model.getParentId();
  }

  void dispose() {
    cells.forEach((cell) {
      cell.dispose();
    });
    rowHeaderCell.dispose();
  }
}

class TableState<T extends IUniqueParentChildRow> {
  /// store of latest event released on the input stream
  List<T> eventCache;

  /// Latest data model recieved from the input stream with each row wrapped
  /// with [PremoTableRow] so that the local state, model and ui streeams
  /// for each rows can be persisted on new data events
  List<PremoTableRow<T>> dataCache;

  /// new list with same data as [dataCache] with the sort in the user interface
  /// applied. Can be removed if the functionality to "desort" data is not
  /// required
  List<PremoTableRow<T>> sortedDataCache;

  /// subset of the [dataCache] which represents the data currently displayed in
  /// the user interface
  List<PremoTableRow<T>> uiDataCache;

  /// store of all user interaction state with columns
  List<ColumnState> uiColumnStates;

  /// store of any [PremoTableRow]s that have been marked for disposal.
  /// Specifically deleted items for rendered on initial deletion. Then on
  /// subsequent refresh events, are disposed and removed from the UI.
  List<PremoTableRow<T>> markedForDisposal;

  /// ************** presentation layer of underlying data model ***************
  CellBloc uiLegendCell;
  List<CellBloc> uiColumnHeaders;

  /// location in the user interface layer of the selected row and column
  int? uiSelectedRow;
  int? uiSelectedColumn;

  /// reference to the currently selected row so its state can be updated
  PremoTableRow<T>? selectedRowReference;

  /// location in the user interface layer of the highted row and column
  int? uiHoveredRow;
  int? uiHoveredColumn;

  /// reference to the currently hovered row so its state can be updated
  PremoTableRow<T>? hoveredRowReference;

  /// count of rows marked/checked
  int checkedRowCount;

  /// currently sorted column
  int? sortColumnIndex;

  /// Whether the column mentioned in [sortColumnIndex], if any, is sorted
  /// in ascending order. Supports tristate.
  /// true = ascending
  /// false = descending
  /// null = original order of data / unsorted
  bool? isAscending;

  TableState({
    required this.eventCache,
    required this.dataCache,
    required this.sortedDataCache,
    required this.uiDataCache,
    this.markedForDisposal = const [],
    required this.uiColumnStates,
    required this.uiLegendCell,
    required this.uiColumnHeaders,
    this.uiSelectedRow,
    this.uiSelectedColumn,
    this.selectedRowReference,
    this.uiHoveredRow,
    this.uiHoveredColumn,
    this.hoveredRowReference,
    this.checkedRowCount = 0,
    this.sortColumnIndex,
    this.isAscending,
  });

  void disposeRows(List<PremoTableRow<T>> rows) {
    for (var i = 0; i < rows.length; i++) {
      PremoTableRow<T> removedUiRow = rows[i];
      removedUiRow.dispose();
    }
  }

  void dispose() {
    uiLegendCell.dispose();
    uiColumnHeaders.forEach((column) {
      column.dispose();
    });
    disposeRows(dataCache);
  }
}
