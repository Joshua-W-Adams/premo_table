part of premo_table;

class LegendCell extends StatelessWidget {
  /// all cell operations are controlled in the tableBloC so cell state changes
  /// and operations can be shared through all relevant components in the table
  final TableBloc tableBloc;

  /// configurable style properties
  final Color cellBorderColor;

  final double height;

  LegendCell({
    required this.tableBloc,
    required this.cellBorderColor,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    /// block assigned to each cell is final and does not change, however the
    /// values within the cell and the cells state will
    CellBloc cellBloc = tableBloc.tableState!.uiLegendCell;

    return Cell(
      cellBloc: cellBloc,
      width: 50,
      height: height,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: cellBorderColor,
          ),
        ),
      ),
      onHover: (_) {
        tableBloc.dehover();
      },
      onTap: () {
        tableBloc.deselect();
      },
      builder: (_) {
        return Checkbox(
          value: tableBloc.allRowsChecked(),

          /// display a dash in the checkbox when the value is null
          tristate: true,
          onChanged: (newValue) {
            tableBloc.checkAll(newValue ?? false);
          },
        );
      },
    );
  }
}
