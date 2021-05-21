part of premo_table;

/// [TableLayout] is a ui widget intended to produce a table /
/// spreadsheet. With the following functionality:
///
/// - Sticky column and row headers (if you scroll content horizontally or
///   vertically column and row headers always stay),
/// - Custom builder widgets for all elements of the table
///
/// In terms of its layout. It is divided into four main sections as follows:
/// - Top Left Quarter:
///   Legend cell and sticky column headers.
/// - Top Right Quarter:
///   Scrollable column headers.
/// - Bottom Left Quarter:
///   Row headers and sticky row cells.
/// - Bottom Right Quarter:
///   Scrollable row cells.
/// Each section is wrapped in a [SingleChildScrollView] as required to stick /
/// freeze the appropriate section.
class TableLayout extends StatefulWidget {
  final int rowCount;
  final int columnCount;
  final int? stickToColumn;
  final bool enableRowHeaders;
  final bool enableColHeaders;
  final Widget legendCell;
  final Widget Function(int columnIndex) columnHeadersBuilder;
  final Widget Function(int rowIndex) rowHeadersBuilder;
  final Widget Function(int columnIndex, int rowIndex) contentCellBuilder;
  final String Function(int rowIndex)? rowKeyBuilder;

  TableLayout({
    Key? key,

    /// Number of Columns
    required this.columnCount,

    /// Number of Rows
    required this.rowCount,

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

    /// Builder for row headers. Takes index of row as parameter and returns a
    /// widget for displaying in row header
    required this.rowHeadersBuilder,

    /// Builder for content cells. Takes indexes for column and row and returns
    /// a widget for displaying in cell
    required this.contentCellBuilder,

    /// Expects a unique string identifier to be returned. This unique string is
    /// used to create a map of unique keys for each row in the bottom half of
    /// the [TableLayout]. Enables more refined state management over the table.
    /// For example the state can be cleared or persisted on adding and
    /// removing rows from the table.
    this.rowKeyBuilder,
  }) : super(key: key);

  @override
  _TableLayoutState createState() => _TableLayoutState();
}

class _TableLayoutState extends State<TableLayout> {
  Map<String, List<UniqueKey>> _rowKeys = Map<String, List<UniqueKey>>();

  List<UniqueKey> _getUniqueRowKeys(
    String uniqueKey,
  ) {
    List<UniqueKey> keys;

    if (_rowKeys[uniqueKey] == null) {
      /// case 1 - create key if id does not exist
      keys = [
        UniqueKey(),
        UniqueKey(),
      ];
    } else {
      /// case 2 - return current keys
      keys = _rowKeys[uniqueKey]!;
    }

    return keys;
  }

  /// [_buildRowAndRowHeaders] loop through all rows and columns and generate
  /// the row header and row widgets.
  Map<int, Widget> _buildRowAndRowHeaders() {
    List<Widget> q3 = [];
    List<Widget> q4 = [];
    // loop through table
    for (int row = 0; row < widget.rowCount; row++) {
      List<Widget> q3Cells = [];
      List<Widget> q4Cells = [];
      // case 1 - row and column headers enabled
      // no specific config required
      // case 2 - row headers enabled only
      // no specific config required
      // case 3 - col headers enabled only
      // no specific config required
      // case 4 - no row or column headers
      // no specific config required
      for (int col = 0; col < widget.columnCount; col++) {
        // build BOTTOM HALF - table content
        // handle enabled row headers
        if (col == 0 && widget.enableRowHeaders == true) {
          q3Cells.add(widget.rowHeadersBuilder(row));
        }
        if (widget.stickToColumn != null && col <= widget.stickToColumn!) {
          // build q3 - sticky row headers
          q3Cells.add(widget.contentCellBuilder(col, row));
        } else {
          // build q4 - scrollable cell content
          q4Cells.add(widget.contentCellBuilder(col, row));
        }
      }
      // generate unique keys to assign to rows
      List<UniqueKey>? keys;
      if (widget.rowKeyBuilder != null) {
        // get user specified unique string identifier
        String key = widget.rowKeyBuilder!(row);
        keys = _getUniqueRowKeys(
          key,
        );
        // update map with keys
        _rowKeys[key] = keys;
      }
      q3.add(
        Row(key: keys != null ? keys[0] : null, children: q3Cells),
      );
      q4.add(
        Row(key: keys != null ? keys[1] : null, children: q4Cells),
      );
    }
    return {
      1: Column(children: q3),
      2: Column(children: q4),
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<int, Widget> bottom = _buildRowAndRowHeaders();
    return ColumnHeadersBuilder(
      columnCount: widget.columnCount,
      stickToColumn: widget.stickToColumn,
      enableRowHeaders: widget.enableRowHeaders,
      enableColHeaders: widget.enableColHeaders,
      legendCell: widget.legendCell,
      columnHeadersBuilder: widget.columnHeadersBuilder,
      builder: (leftColumns, rightColumns) {
        return FrozenHeadersLayout(
          q1: leftColumns,
          q2: rightColumns,
          q3: bottom[1]!,
          q4: bottom[2]!,
        );
      },
    );
  }
}
