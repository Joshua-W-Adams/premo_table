part of premo_table;

class ColumnHeadersBuilder extends StatelessWidget {
  final int columnCount;
  final int? stickToColumn;
  final bool enableRowHeaders;
  final bool enableColHeaders;
  final Widget legendCell;
  final Widget Function(int columnIndex) columnHeadersBuilder;
  final Widget Function(Row? leftColumns, Row? rightColumns) builder;

  ColumnHeadersBuilder({
    /// Number of Columns
    required this.columnCount,

    /// Stick all columns up to this column to the side of the table
    this.stickToColumn,

    /// Enable or disable row headers in the table
    this.enableRowHeaders = true,

    /// Enable or disable col headers in the table
    this.enableColHeaders = true,

    /// Top left cell
    this.legendCell = const Text(''),

    /// Builder for column headers. Takes index of column as parameter and
    /// returns a widget for displaying in column header
    required this.columnHeadersBuilder,

    /// child widget builder
    required this.builder,
  });

  /// [_buildLegendAndColumnHeaders] loop through all the provided columns and
  /// generates the legendCell, frozen and non frozen column headers
  Map<int, Row?> _buildLegendAndColumnHeaders() {
    List<Widget> q1Cells = [];
    List<Widget> q2Cells = [];
    for (int col = 0; col < columnCount; col++) {
      // case 1 - row and column headers enabled
      if (col == 0 && enableColHeaders && enableRowHeaders) {
        q1Cells.add(legendCell);
      }
      // case 2 - row headers enabled only
      // no specific config required
      // case 3 - col headers enabled only
      // no specific config required
      // case 4 - no row or column headers
      // no specific config required

      // build TOP HALF - table headers
      if (enableColHeaders == true) {
        if (stickToColumn != null && col <= stickToColumn!) {
          // build q1 - sticky headers
          q1Cells.add(columnHeadersBuilder(col));
        } else {
          // build q2 - scrollable headers
          q2Cells.add(columnHeadersBuilder(col));
        }
      }
    }
    Row? q1;
    Row? q2;
    // add cells to row and store in quarter
    if (enableColHeaders == true) {
      q1 = Row(children: q1Cells);
      q2 = Row(children: q2Cells);
    }
    return {
      0: q1,
      1: q2,
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<int, Row?> columns = _buildLegendAndColumnHeaders();
    return builder(columns[0], columns[1]);
  }
}
