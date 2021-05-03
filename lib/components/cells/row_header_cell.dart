part of premo_table;

class RowHeaderCell extends StatelessWidget {
  /// all cell operations are controlled in the tableBloC so cell state changes
  /// and operations can be shared through all relevant components in the table
  final TableBloc tableBloc;

  /// index of the cell in the displayed ui which is output in the [uiRow]s
  /// property from the tableBloc
  final int uiRowIndex;

  /// configurable style properties
  final Color cellBorderColor;

  RowHeaderCell({
    required this.tableBloc,
    required this.uiRowIndex,
    required this.cellBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    /// block assigned to each cell is final and does not change, however the
    /// values within the cell and the cells state will
    CellBloc rowHeaderBloc = tableBloc.tableState!.uiRows[uiRowIndex].rowHeader;
    return Cell(
      cellBloc: rowHeaderBloc,
      width: 50,
      height: 50,
      onHover: (_) {
        tableBloc.dehover();
      },
      onTap: () {
        tableBloc.deselect();
      },
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: cellBorderColor,
          ),
        ),
      ),
      builder: (cellBlocState) {
        UiRow uiRow = tableBloc.tableState!.uiRows[uiRowIndex];
        return Checkbox(
          value: uiRow.rowState.checked,
          onChanged: (newValue) {
            tableBloc.deselect();
            tableBloc.check(uiRowIndex, newValue ?? false);
          },
        );
      },
    );
  }
}
