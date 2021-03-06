part of premo_table;

/// Generates a Google Sheets / Excel like table interface
class PremoTable<T extends IUniqueParentChildRow> extends StatelessWidget {
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
  final TextStyle? Function(T? item, int uiRowIndex, int uiColumnIndex)?
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
    this.cellTextStyleBuilder,
    this.cellWidgetBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final double effectiveDataRowHeight = rowHeight ??
        theme.dataTableTheme.dataRowHeight ??
        kMinInteractiveDimension;
    final Color cellBottomBorderColor = theme.canvasColor;
    final TextStyle? defaultCellTextStyle = theme.textTheme.bodyText1;
    return TableStreamBuilder<T>(
      stream: tableBloc.stream,
      builder: (tableState) {
        int? rowCount = tableState.uiDataCache.length;

        /// Build table
        return MouseRegion(
          onExit: (event) {
            tableBloc.dehover();
          },
          child: TableLayout(
            // stickToColumn: 0,
            // enableColHeaders: true,
            // enableRowHeaders: true,
            columnCount: tableBloc.columnNames.length,
            rowCount: rowCount,

            /// rowheaders and legend cell will not be generated if the checking
            /// is not enabled
            enableRowHeaders: enableChecking,

            /// *********** cell at position 0,0 ***********
            legendCell: CellStreamBuilder(
              cellBloc: tableBloc.tableState!.uiLegendCell,
              builder: (cellState) {
                return LegendCell(
                  height: effectiveDataRowHeight,
                  onTap: () {
                    tableBloc.deselect();
                  },
                  onHover: (_) {
                    tableBloc.dehover();
                  },
                  cellBorderColor: cellBorderColor,
                  allRowsChecked: tableBloc.allRowsChecked(),
                  onChanged: (newValue) {
                    tableBloc.checkAll(newValue ?? false);
                  },
                );
              },
            ),

            /// *********** COLUMN HEADERS ***********
            columnHeadersBuilder: (uiColumnIndex) {
              return CellStreamBuilder(
                cellBloc: tableBloc.tableState!.uiColumnHeaders[uiColumnIndex],
                builder: (cellBlocState) {
                  return ColumnHeaderCell(
                    height: effectiveDataRowHeight,
                    width: columnWidthBuilder(uiColumnIndex),
                    visible: cellBlocState.visible,
                    enabled: !cellBlocState.requestInProgress,
                    showLoadingIndicator: cellBlocState.requestInProgress,
                    selected: cellBlocState.selected,
                    rowSelected: cellBlocState.rowSelected,
                    columnSelected: cellBlocState.colSelected,
                    hovered: cellBlocState.hovered,
                    rowHovered: cellBlocState.rowHovered,
                    columnHovered: cellBlocState.colHovered,
                    rowChecked: cellBlocState.rowChecked ?? false,
                    animation: TableFunctions.getAnimation(cellBlocState),
                    onTap: () {
                      tableBloc.deselect();
                      tableBloc.sort(uiColumnIndex);
                    },
                    onHover: (_) {
                      tableBloc.dehover();
                    },
                    backgroundColor: columnBackgroundColor,
                    cellBorderColor: cellBorderColor,
                    value: cellBlocState.value,
                    textStyle: columnTextStyle,
                    sorted: tableState.sortColumnIndex == uiColumnIndex &&
                        tableState.isAscending != null,
                    ascending: tableState.isAscending ?? false,
                    onSort: enableSorting == true
                        ? () {
                            tableBloc.deselect();
                            tableBloc.sort(uiColumnIndex);
                          }
                        : null,
                    onFilter: (value) {
                      tableBloc.filter(
                          uiColumnIndex, value == '' ? null : value);
                    },
                    onFilterButtonTap: () {
                      tableBloc.deselect();
                    },
                  );
                },
              );
            },

            /// *********** ROW HEADERS ***********
            rowHeadersBuilder: (uiRowIndex) {
              PremoTableRow<T> uiRow =
                  tableBloc.tableState!.uiDataCache[uiRowIndex];
              return CellStreamBuilder(
                cellBloc: uiRow.rowHeaderCell,
                builder: (cellBlocState) {
                  return RowHeaderCell(
                    height: effectiveDataRowHeight,
                    visible: cellBlocState.visible,
                    enabled: !cellBlocState.requestInProgress,
                    showLoadingIndicator: cellBlocState.requestInProgress,
                    selected: cellBlocState.selected,
                    rowSelected: cellBlocState.rowSelected,
                    columnSelected: cellBlocState.colSelected,
                    hovered: cellBlocState.hovered,
                    rowHovered: cellBlocState.rowHovered,
                    columnHovered: cellBlocState.colHovered,
                    rowChecked: cellBlocState.rowChecked ?? false,
                    animation: TableFunctions.getAnimation(cellBlocState),
                    onTap: () {
                      tableBloc.deselect();
                    },
                    onHover: (_) {
                      tableBloc.dehover();
                    },
                    cellRightBorderColor: cellBorderColor,

                    /// bottom cell border color required to ensure row header
                    /// and row cell highlighting lines up correctly.
                    cellBottomBorderColor: cellBottomBorderColor,
                    checked: cellBlocState.rowChecked ?? false,
                    onChanged: (newValue) {
                      tableBloc.check(uiRow, newValue ?? false);
                    },
                  );
                },
              );
            },

            /// *********** CONTENT ***********
            contentCellBuilder: (uiColumnIndex, uiRowIndex) {
              bool readOnly = columnReadOnlyBuilder(uiColumnIndex);
              PremoTableRow<T> uiRow =
                  tableBloc.tableState!.uiDataCache[uiRowIndex];
              return CellStreamBuilder(
                cellBloc: uiRow.cells[uiColumnIndex],
                builder: (cellBlocState) {
                  /// get data model associated to current cell
                  T rowModel = uiRow.model;
                  return ContentCell(
                    height: effectiveDataRowHeight,
                    width: columnWidthBuilder(uiColumnIndex),
                    verticalAlignment: columnVerticalAlignmentBuilder(
                      rowModel,
                      uiRowIndex,
                      uiColumnIndex,
                    ),
                    visible: cellBlocState.visible,
                    enabled: !cellBlocState.requestInProgress,
                    showLoadingIndicator: cellBlocState.requestInProgress,
                    selected: cellBlocState.selected,
                    rowSelected: cellBlocState.rowSelected,
                    columnSelected: cellBlocState.colSelected,
                    hovered: cellBlocState.hovered,
                    rowHovered: cellBlocState.rowHovered,
                    columnHovered: cellBlocState.colHovered,
                    rowChecked: cellBlocState.rowChecked ?? false,
                    animation: TableFunctions.getAnimation(cellBlocState),
                    onTap: () {
                      tableBloc.select(uiRow, uiColumnIndex);
                    },
                    onHover: (_) {
                      tableBloc.hover(uiRow, uiColumnIndex);
                    },
                    backgroundColor:
                        readOnly == true ? disabledCellColor : null,
                    cellBorderColor: cellBorderColor,
                    horizontalAlignment: columnHorizontalAlignmentBuilder(
                      rowModel,
                      uiRowIndex,
                      uiColumnIndex,
                    ),
                    textStyle: cellTextStyleBuilder != null
                        ? cellTextStyleBuilder!(
                            rowModel,
                            uiRowIndex,
                            uiColumnIndex,
                          )
                        : defaultCellTextStyle,
                    readOnly: readOnly,
                    onFocusLost: (newValue) {
                      /// Note for Content Cells with text, currency or number
                      /// content the onChanged function is mapped to the
                      /// onFocusLost function. This is only fired when the user
                      /// clicks out of the cell or submits the value
                      /// note: server side modifications never cause cells to
                      /// loose focus so checking the change state is not
                      /// required.
                      tableBloc.update(
                        uiRow,
                        uiColumnIndex,
                        newValue,
                        cellBlocState.value,
                      );
                    },
                    cellType: columnTypeBuilder(uiColumnIndex),
                    value: cellBlocState.value,
                    validator: columnValidatorBuilder(
                      rowModel,
                      uiRowIndex,
                      uiColumnIndex,
                    ),
                    dropdownList: columnDropdownBuilder(
                      rowModel,
                      uiRowIndex,
                      uiColumnIndex,
                    ),
                    customCellContent: cellWidgetBuilder != null
                        ? cellWidgetBuilder!(
                            rowModel, uiRowIndex, uiColumnIndex)
                        : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
