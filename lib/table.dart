part of premo_table;

/// supported cell types
enum CellTypes { text, number, currency, date, dropdown, cellswitch, custom }

/// Generates a Google Sheets / Excel like table interface
class PremoTable<T extends IUniqueIdentifier> extends StatelessWidget {
  /// Business logic and state
  final TableBloc<T> tableBloc;

  /// enable table filters
  final bool enableFilters;

  /// enable table sorting
  final bool enableSorting;

  /// enable selection of single or multiple rows
  final bool enableChecking;

  /// Styling configuration options for table
  final double? rowHeight;
  final Color? columnBackgroundColor;
  final Color disabledCellColor;
  final Color cellBorderColor;

  final TextStyle? columnTextStyle;

  /// Column based configuration options
  final double Function(int uiColumnIndex) columnWidthBuilder;
  final bool Function(int uiColumnIndex) columnReadOnlyBuilder;
  final Alignment Function(T? item, int uiRowIndex, int uiColumnIndex)
      columnHorizontalAlignmentBuilder;
  final Alignment Function(T? item, int uiRowIndex, int uiColumnIndex)
      columnVerticalAlignmentBuilder;
  final CellTypes Function(int uiColumnIndex) columnTypeBuilder;
  final List<String>? Function(T? item, int uiRowIndex, int uiColumnIndex)
      columnDropdownBuilder;
  final String? Function(String?)? Function(
      T? item, int uiRowIndex, int uiColumnIndex) columnValidatorBuilder;

  /// Cell based configuration options
  final TextStyle? Function(T? item, int uiRowIndex, int uiColumnIndex)
      cellTextStyleBuilder;
  final Widget Function(T? item, int uiRowIndex, int uiColumnIndex)?
      cellWidgetBuilder;

  /// default callback functions for configuring table properties
  static double defaultColumnWidthBuilder(int uiColumnIndex) {
    return 125.0;
  }

  static bool defaultColumnReadOnlyBuilder(int uiColumnIndex) {
    return false;
  }

  static Alignment defaultColumnHorizontalAlignmentBuilder(
    dynamic item,
    int uiRowIndex,
    int uiColumnIndex,
  ) {
    return Alignment.center;
  }

  static Alignment defaultColumnVerticalAlignmentBuilder(
    dynamic item,
    int uiRowIndex,
    int uiColumnIndex,
  ) {
    return Alignment.center;
  }

  static CellTypes defaultColumnTypeBuilder(int uiColumnIndex) {
    return CellTypes.text;
  }

  static List<String>? defaultColumnDropdownBuilder(
    dynamic item,
    int uiRowIndex,
    int uiColumnIndex,
  ) {
    return null;
  }

  static String? Function(String?)? defaultColumnValidatorBuilder(
    dynamic item,
    int uiRowIndex,
    int uiColumnIndex,
  ) {
    return null;
  }

  static TextStyle? defaultColumnTextStyleBuilder(
      dynamic item, int uiRowIndex, int uiColumnIndex) {
    return null;
  }

  PremoTable({
    Key? key,
    required this.tableBloc,
    this.enableFilters = true,
    this.enableSorting = true,
    this.enableChecking = true,
    this.rowHeight,
    this.columnBackgroundColor,
    this.disabledCellColor = const Color(0xFFF5F5F5), // Colors.grey[100]
    this.cellBorderColor = const Color(0xFFE0E0E0), // Colors.grey[300]
    this.columnTextStyle,
    this.columnWidthBuilder = defaultColumnWidthBuilder,
    this.columnReadOnlyBuilder = defaultColumnReadOnlyBuilder,
    this.columnHorizontalAlignmentBuilder =
        defaultColumnHorizontalAlignmentBuilder,
    this.columnVerticalAlignmentBuilder = defaultColumnVerticalAlignmentBuilder,
    this.columnTypeBuilder = defaultColumnTypeBuilder,
    this.columnDropdownBuilder = defaultColumnDropdownBuilder,
    this.columnValidatorBuilder = defaultColumnValidatorBuilder,
    this.cellTextStyleBuilder = defaultColumnTextStyleBuilder,
    this.cellWidgetBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final double effectiveDataRowHeight = rowHeight ??
        theme.dataTableTheme.dataRowHeight ??
        kMinInteractiveDimension;
    return StreamBuilder<TableState<T>>(
      /// Stream of entire table state
      stream: tableBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          /// case 1 - awaiting connection
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          /// case 2 - error in snapshot
          return ErrorMessage(
            error: '${snapshot.error.toString()}',
          );
        } else if (!snapshot.hasData) {
          /// case 3 - no data
          return ErrorMessage(
            error: 'No data recieved from server',
          );
        }

        /// case 4 - all verification checks passed.

        /// Get current state released by stream
        TableState<T> tableState = snapshot.data!;
        int? rowCount = tableState.uiRows.length;

        /// Build table
        return MouseRegion(
          onExit: (event) {
            tableBloc.dehover();
          },
          child: FreezeableTableLayout(
            // stickToColumn: 0,
            // enableColHeaders: true,
            // enableRowHeaders: true,
            columnCount: tableBloc.columnNames.length,
            rowCount: rowCount,

            /// rowheaders and legend cell will not be generated if the checking
            /// is not enabled
            enableRowHeaders: enableChecking,

            /// *********** cell at position 0,0 ***********
            legendCell: LegendCell(
              tableBloc: tableBloc,
              height: effectiveDataRowHeight,
              cellBorderColor: cellBorderColor,
            ),

            /// *********** COLUMN HEADERS ***********
            columnHeadersBuilder: (uiColumnIndex) {
              /// get table level configuration
              double width = columnWidthBuilder(uiColumnIndex);

              return ColumnHeaderCell(
                tableBloc: tableBloc,
                uiColumnIndex: uiColumnIndex,
                width: width,
                height: effectiveDataRowHeight,
                cellBorderColor: cellBorderColor,
                columnBackgroundColor: columnBackgroundColor,
                textStyle: columnTextStyle,
                enableFilters: enableFilters,
                enableSorting: enableSorting,
              );
            },

            /// *********** ROW HEADERS ***********
            rowHeadersBuilder: (uiRowIndex) {
              return RowHeaderCell(
                tableBloc: tableBloc,
                uiRowIndex: uiRowIndex,
                height: effectiveDataRowHeight,
                cellBorderColor: cellBorderColor,
              );
            },

            /// *********** CONTENT ***********
            contentCellBuilder: (uiColumnIndex, uiRowIndex) {
              /// get item associated to current cell
              T? item;
              if (uiRowIndex < tableState.uiRows.length) {
                /// only get an item if the current ui row being built has data
                /// attached to it. i.e. it has not been flagged for deletion
                item = tableState.uiRows[uiRowIndex].rowState.rowModel;
              }

              /// get styling configuration
              double width = columnWidthBuilder(uiColumnIndex);
              CellTypes cellType = columnTypeBuilder(uiColumnIndex);
              bool readOnly = columnReadOnlyBuilder(uiColumnIndex);
              TextStyle? textStyle =
                  cellTextStyleBuilder(item, uiRowIndex, uiColumnIndex);
              Alignment horizontalAlignment = columnHorizontalAlignmentBuilder(
                  item, uiRowIndex, uiColumnIndex);
              Alignment verticalAlignment = columnVerticalAlignmentBuilder(
                  item, uiRowIndex, uiColumnIndex);
              List<String>? dropdownList =
                  columnDropdownBuilder(item, uiRowIndex, uiColumnIndex);
              String? Function(String?)? validator =
                  columnValidatorBuilder(item, uiRowIndex, uiColumnIndex);
              Widget? customCellContent = cellWidgetBuilder != null
                  ? cellWidgetBuilder!(item, uiRowIndex, uiColumnIndex)
                  : null;

              return ContentCell(
                tableBloc: tableBloc,
                uiRowIndex: uiRowIndex,
                uiColumnIndex: uiColumnIndex,
                width: width,
                height: effectiveDataRowHeight,
                cellType: cellType,
                readOnly: readOnly,
                textStyle: textStyle,
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                dropdownList: dropdownList,
                validator: validator,
                customCellContent: customCellContent,
                cellBorderColor: cellBorderColor,
                disabledCellColor: disabledCellColor,
              );
            },
          ),
        );
      },
    );
  }
}
