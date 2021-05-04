part of premo_table;

/// all rows in a [PremoTable] require a unique identifier so all internal BLoC
/// functionality can operate correctly. E.g. update, delete, add, ui state
/// peristance etc.
abstract class IUniqueIdentifier {
  final String id;
  IUniqueIdentifier({required this.id});
}

enum ChangeTypes { update, add, delete }

class CellState {
  /// user selected row
  bool requestPending;

  /// user is hovering over the row
  bool requestSucceeded;

  CellState({
    this.requestPending = false,
    this.requestSucceeded = false,
  });
}

class RowState<T extends IUniqueIdentifier> {
  /// data model for row
  T? rowModel;

  /// user selected
  bool selected;

  /// user marked as checked
  bool checked;

  /// user hovering
  bool hovered;

  /// row visibility
  bool visible;

  /// state for each cell in row
  Map<int, CellState> cellStates;

  RowState({
    required this.rowModel,
    this.selected = false,
    this.checked = false,
    this.hovered = false,
    this.visible = true,
    required this.cellStates,
  });
}

/// represents a row that can be displayed in the ui
class UiRow<T extends IUniqueIdentifier> {
  /// RowState reference attached to the user interface
  RowState<T> rowState;

  /// header cell for the row
  CellBloc rowHeader;

  /// user interface cells controlled by [UiRow]
  List<CellBloc> cellBlocs;

  UiRow({
    required this.rowState,
    required this.rowHeader,
    required this.cellBlocs,
  });

  void dispose() {
    cellBlocs.forEach((cell) {
      cell.dispose();
    });
    rowHeader.dispose();
  }
}

class ColumnState {
  /// filter applied to column, if any
  String? filterValue;

  ColumnState({
    this.filterValue,
  });
}

class TableState<T extends IUniqueIdentifier> {
  /// Latest data model recieved from the input stream with each row wrapped
  /// with [RowState] so that the local state of rows can be persisted on new
  /// data events
  List<RowState<T>> dataCache;

  /// new list with same data as [dataCache] with the sort in the user interface
  /// applied. Can be removed if the functionality to "desort" data is not
  /// required
  List<RowState<T>> sortedDataCache;

  /// subset of the [dataCache] which represents the data currently displayed in
  /// the user interface
  List<RowState<T>> uiDataCache;

  /// store of all user interaction state with columns
  List<ColumnState> uiColumnStates;

  /// ************** presentation layer of underlying data model ***************
  CellBloc uiLegendCell;
  List<CellBloc> uiColumnHeaders;
  List<UiRow<T>> uiRows;

  /// location in the user interface layer of the selected row and column
  int? uiSelectedRow;
  int? uiSelectedColumn;

  /// reference to the currently selected row so its state can be updated
  RowState<T>? selectedRowState;

  /// location in the user interface layer of the highted row and column
  int? uiHoveredRow;
  int? uiHoveredColumn;

  /// reference to the currently hovered row so its state can be updated
  RowState<T>? hoveredRowState;

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
    required this.dataCache,
    required this.sortedDataCache,
    required this.uiDataCache,
    required this.uiColumnStates,
    required this.uiLegendCell,
    required this.uiColumnHeaders,
    required this.uiRows,
    this.uiSelectedRow,
    this.uiSelectedColumn,
    this.selectedRowState,
    this.uiHoveredRow,
    this.uiHoveredColumn,
    this.hoveredRowState,
    this.checkedRowCount = 0,
    this.sortColumnIndex,
    this.isAscending,
  });

  void disposeRows(List<UiRow<T>> rows) {
    for (var i = 0; i < rows.length; i++) {
      UiRow<T> removedUiRow = rows[i];
      removedUiRow.dispose();
    }
  }

  void dispose() {
    uiLegendCell.dispose();
    uiColumnHeaders.forEach((column) {
      column.dispose();
    });
    disposeRows(uiRows);
  }
}
