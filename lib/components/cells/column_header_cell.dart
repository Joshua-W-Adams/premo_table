part of premo_table;

class ColumnHeaderCell extends StatelessWidget {
  /// all cell operations are controlled in the tableBloC so cell state changes
  /// and operations can be shared through all relevant components in the table
  final TableBloc tableBloc;

  /// index of the cells column in the displayed ui which is output in the
  /// [uiRow]s property from the tableBloc
  final int uiColumnIndex;

  /// configurable style properties
  final double width;
  final Color? columnBackgroundColor;
  final Color cellBorderColor;

  /// configurable functionality
  final bool enableSorting;
  final bool enableFilters;

  ColumnHeaderCell({
    required this.tableBloc,
    required this.uiColumnIndex,
    required this.width,
    this.columnBackgroundColor,
    required this.cellBorderColor,
    this.enableSorting = true,
    this.enableFilters = true,
  });

  @override
  Widget build(BuildContext context) {
    /// block assigned to each header is final and does not change, however the
    /// values within the cell and the cells state will
    CellBloc columnHeaderBloc =
        tableBloc.tableState!.uiColumnHeaders[uiColumnIndex];
    return Cell(
      cellBloc: columnHeaderBloc,
      height: 50,
      width: width,
      decoration: BoxDecoration(
        color: columnBackgroundColor,
        border: Border(
          top: BorderSide(
            color: cellBorderColor,
          ),
          right: BorderSide(
            color: cellBorderColor,
          ),
          bottom: BorderSide(
            color: cellBorderColor,
          ),
        ),
      ),
      onTap: () {
        tableBloc.deselect();
        tableBloc.sort(uiColumnIndex);
      },
      onHover: (_) {
        tableBloc.dehover();
      },
      builder: (cellBlocState) {
        TableState tableState = tableBloc.tableState!;
        return ColumnHeaderCellContent(
          cellBlocState: cellBlocState,
          textAlign: TextAlign.center,
          sorted: tableState.sortColumnIndex == uiColumnIndex &&
              tableState.isAscending != null,
          ascending: tableState.isAscending ?? false,
          onSort: enableSorting == true
              ? () {
                  tableBloc.deselect();
                  tableBloc.sort(uiColumnIndex);
                }
              : null,
          onFilter: enableFilters == true
              ? (value) {
                  tableBloc.filter(uiColumnIndex, value == '' ? null : value);
                }
              : null,
          onFilterButtonTap: () {
            tableBloc.deselect();
          },
        );
      },
    );
  }
}
