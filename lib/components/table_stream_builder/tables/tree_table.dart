part of premo_table;

/// Generates a Google Sheets / Excel like table interface
class TreeTable<T extends IUniqueParentChildRow> extends StatelessWidget {
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

  TreeTable({
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

  ParentBloc _getParentBLoc(
    Map<PremoTableRow<T>, ParentBloc> blocMap,
    PremoTableRow<T> parent,
  ) {
    ParentBloc? parentBloc = blocMap[parent];
    if (parentBloc == null) {
      parentBloc = ParentBloc(expanded: false);
      blocMap[parent] = parentBloc;
    }
    return parentBloc;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final double effectiveDataRowHeight = rowHeight ??
        theme.dataTableTheme.dataRowHeight ??
        kMinInteractiveDimension;
    final Color cellBottomBorderColor = theme.canvasColor;
    final TextStyle? defaultCellTextStyle = theme.textTheme.bodyText1;
    final double iconWidth = 40.0;
    List<Color> rowColors = [
      Theme.of(context).accentColor.withOpacity(0.15),
      Theme.of(context).accentColor.withOpacity(0.05),
    ];
    Map<PremoTableRow<T>, ParentBloc> syncedParentBlocs = Map();
    return TableStreamBuilder<T>(
      stream: tableBloc.stream,
      builder: (tableState) {
        /// Build table
        return MouseRegion(
          onExit: (event) {
            tableBloc.dehover();
          },
          child: TreeTableLayout<PremoTableRow<T>>(
            // stickToColumn: 0,
            // enableColHeaders: true,
            // enableRowHeaders: true,
            columnCount: tableBloc.columnNames.length,

            /// rowheaders and legend cell will not be generated if the checking
            /// is not enabled
            enableRowHeaders: enableChecking,

            /// *********** cell at position 0,0 ***********
            legendCell: CellStreamBuilder(
              cellBloc: tableBloc.tableState!.uiLegendCell,
              builder: (cellState) {
                return Row(
                  children: [
                    /// separator for [ParentWidget] icons
                    Container(width: iconWidth),
                    LegendCell(
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
                    ),
                  ],
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
            rowHeadersBuilder: (uiRow) {
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
            contentCellBuilder: (uiColumnIndex, uiRow) {
              bool readOnly = columnReadOnlyBuilder(uiColumnIndex);
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
                      0, // TODO - refactor vertial alignment builder
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
                      0, // TODO - refactor horizontal alignment builder
                      uiColumnIndex,
                    ),
                    textStyle: cellTextStyleBuilder != null
                        ? cellTextStyleBuilder!(
                            rowModel,
                            0, // TODO - refactor textstyle builder
                            uiColumnIndex,
                          )
                        : defaultCellTextStyle,
                    readOnly: readOnly,
                    onChanged: (newValue) {
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
                      0, // TODO - refactor column validator
                      uiColumnIndex,
                    ),
                    dropdownList: columnDropdownBuilder(
                      rowModel,
                      0, // TODO - refactor column dropdown builder
                      uiColumnIndex,
                    ),
                    customCellContent: cellWidgetBuilder != null
                        ? cellWidgetBuilder!(
                            rowModel,
                            0, // TODO - refactor
                            uiColumnIndex,
                          )
                        : null,
                  );
                },
              );
            },
            data: tableState.uiDataCache,
            buildFromId: null,
            onChildS1: (_, __, ___, cells) {
              return Row(
                children: [Container(width: iconWidth), ...cells],
              );
            },
            onChildS2: (_, __, ___, cells) {
              return Row(
                children: cells,
              );
            },
            onParentUpS1: (parent, _, __, depth, childrenWidgets, cells) {
              // TODO - clean up parent blocs to avoid memory leaks.
              ParentBloc parentBloc = _getParentBLoc(syncedParentBlocs, parent);
              return ParentBuilder(
                stream: parentBloc.stream,
                builder: (expanded) {
                  return ParentWidget(
                    parent: Row(children: cells),
                    parentRowColor: depth <= 1 ? rowColors[depth] : null,
                    children: childrenWidgets,
                    expanded: expanded,
                    onPressed: () {
                      parentBloc.setExpanded(!expanded);
                    },
                  );
                },
              );
            },
            onParentUpS2: (parent, parentParent, children, depth,
                childrenWidgets, cells) {
              ParentBloc parentBloc = _getParentBLoc(syncedParentBlocs, parent);
              return ParentBuilder(
                stream: parentBloc.syncStream,
                builder: (expanded) {
                  return ParentWidget(
                    parent: Row(children: cells),
                    parentRowColor: depth <= 1 ? rowColors[depth] : null,
                    icon: null,
                    children: childrenWidgets,
                    expanded: expanded,
                    onPressed: () {
                      parentBloc.setExpanded(!expanded);
                    },
                  );
                },
              );
            },
            onEndOfDepthS1: (parent, depth) {
              return Container();
            },
            onEndOfDepthS2: (parent, depth) {
              return Container();
            },
          ),
        );
      },
    );
  }
}
