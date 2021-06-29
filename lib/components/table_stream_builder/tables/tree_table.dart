part of premo_table;

/// Generates a Google Sheets / Excel like table interface
class TreeTable<T extends IUniqueParentChildRow> extends StatefulWidget {
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
  final Alignment Function(T? item, int uiColumnIndex)
      columnHorizontalAlignmentBuilder;
  final Alignment Function(T? item, int uiColumnIndex)
      columnVerticalAlignmentBuilder;
  final CellTypes Function(int uiColumnIndex) columnTypeBuilder;
  final List<String>? Function(T? item, int uiColumnIndex)
      columnDropdownBuilder;
  final String? Function(String?)? Function(T? item, int uiColumnIndex)
      columnValidatorBuilder;

  /// Cell based configuration options
  final TextStyle? Function(T? item, int uiColumnIndex)? cellTextStyleBuilder;
  final Widget Function(T? item, int uiColumnIndex)? cellWidgetBuilder;

  final String? buildFromId;

  /// default callback functions for configuring table properties
  static double defaultColumnWidthBuilder(int uiColumnIndex) {
    return 125.0;
  }

  static bool defaultColumnReadOnlyBuilder(int uiColumnIndex) {
    return false;
  }

  static Alignment defaultColumnHorizontalAlignmentBuilder(
    dynamic item,
    int uiColumnIndex,
  ) {
    return Alignment.center;
  }

  static Alignment defaultColumnVerticalAlignmentBuilder(
    dynamic item,
    int uiColumnIndex,
  ) {
    return Alignment.center;
  }

  static CellTypes defaultColumnTypeBuilder(int uiColumnIndex) {
    return CellTypes.text;
  }

  static List<String>? defaultColumnDropdownBuilder(
    dynamic item,
    int uiColumnIndex,
  ) {
    return null;
  }

  static String? Function(String?)? defaultColumnValidatorBuilder(
    dynamic item,
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
    this.buildFromId,
  }) : super(key: key);

  @override
  _TreeTableState<T> createState() => _TreeTableState<T>();
}

class _TreeTableState<T extends IUniqueParentChildRow>
    extends State<TreeTable<T>> {
  Map<PremoTableRow<T>, ParentBloc> syncedParentBlocs = Map();

  ParentBloc _getParentBLoc(
    Map<PremoTableRow<T>, ParentBloc> blocMap,
    PremoTableRow<T> parent,
  ) {
    ParentBloc? parentBloc = blocMap[parent];
    if (parentBloc != null) {
      parentBloc.dispose();
    }
    parentBloc = ParentBloc(expanded: true);
    blocMap[parent] = parentBloc;
    return parentBloc;
  }

  @override
  void dispose() {
    syncedParentBlocs.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final double effectiveDataRowHeight = widget.rowHeight ??
        theme.dataTableTheme.dataRowHeight ??
        kMinInteractiveDimension;
    final Color cellBottomBorderColor = theme.canvasColor;
    final TextStyle? defaultCellTextStyle = theme.textTheme.bodyText1;
    final double iconWidth = 40.0;

    List<Icon?> icons = [
      Icon(Icons.keyboard_arrow_right, size: 24),
      Icon(Icons.keyboard_arrow_right, size: 16),
    ];
    return TableStreamBuilder<T>(
      stream: widget.tableBloc.stream,
      builder: (tableState) {
        /// Build table
        return MouseRegion(
          onExit: (event) {
            widget.tableBloc.dehover();
          },
          child: TreeTableLayout<PremoTableRow<T>>(
            // stickToColumn: 0,
            // enableColHeaders: true,
            // enableRowHeaders: true,
            columnCount: widget.tableBloc.columnNames.length,

            /// rowheaders and legend cell will not be generated if the checking
            /// is not enabled
            enableRowHeaders: widget.enableChecking,

            /// *********** cell at position 0,0 ***********
            legendCell: CellStreamBuilder(
              cellBloc: widget.tableBloc.tableState!.uiLegendCell,
              builder: (cellState) {
                return Row(
                  children: [
                    /// separator for [ParentWidget] icons
                    Container(width: iconWidth),
                    LegendCell(
                      height: effectiveDataRowHeight,
                      onTap: () {
                        widget.tableBloc.deselect();
                      },
                      onHover: (_) {
                        widget.tableBloc.dehover();
                      },
                      cellBorderColor: widget.cellBorderColor,
                      allRowsChecked: widget.tableBloc.allRowsChecked(),
                      onChanged: (newValue) {
                        widget.tableBloc.checkAll(newValue ?? false);
                      },
                    ),
                  ],
                );
              },
            ),

            /// *********** COLUMN HEADERS ***********
            columnHeadersBuilder: (uiColumnIndex) {
              return CellStreamBuilder(
                cellBloc:
                    widget.tableBloc.tableState!.uiColumnHeaders[uiColumnIndex],
                builder: (cellBlocState) {
                  return ColumnHeaderCell(
                    height: effectiveDataRowHeight,
                    width: widget.columnWidthBuilder(uiColumnIndex),
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
                      widget.tableBloc.deselect();
                      widget.tableBloc.sort(uiColumnIndex);
                    },
                    onHover: (_) {
                      widget.tableBloc.dehover();
                    },
                    backgroundColor: widget.columnBackgroundColor,
                    cellBorderColor: widget.cellBorderColor,
                    value: cellBlocState.value,
                    textStyle: widget.columnTextStyle,
                    sorted: tableState.sortColumnIndex == uiColumnIndex &&
                        tableState.isAscending != null,
                    ascending: tableState.isAscending ?? false,
                    onSort: widget.enableSorting == true
                        ? () {
                            widget.tableBloc.deselect();
                            widget.tableBloc.sort(uiColumnIndex);
                          }
                        : null,
                    onFilter: (value) {
                      widget.tableBloc
                          .filter(uiColumnIndex, value == '' ? null : value);
                    },
                    onFilterButtonTap: () {
                      widget.tableBloc.deselect();
                    },
                  );
                },
              );
            },

            /// *********** ROW HEADERS ***********
            rowHeadersBuilder: (uiRow, _) {
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
                      widget.tableBloc.deselect();
                    },
                    onHover: (_) {
                      widget.tableBloc.dehover();
                    },
                    cellRightBorderColor: widget.cellBorderColor,

                    /// bottom cell border color required to ensure row header
                    /// and row cell highlighting lines up correctly.
                    cellBottomBorderColor: cellBottomBorderColor,
                    checked: cellBlocState.rowChecked ?? false,
                    onChanged: (newValue) {
                      widget.tableBloc.check(uiRow, newValue ?? false);
                    },
                  );
                },
              );
            },

            /// *********** CONTENT ***********
            contentCellBuilder: (uiColumnIndex, uiRow, _) {
              bool readOnly = widget.columnReadOnlyBuilder(uiColumnIndex);
              return CellStreamBuilder(
                cellBloc: uiRow.cells[uiColumnIndex],
                builder: (cellBlocState) {
                  /// get data model associated to current cell
                  T rowModel = uiRow.model;
                  return ContentCell(
                    height: effectiveDataRowHeight,
                    width: widget.columnWidthBuilder(uiColumnIndex),
                    verticalAlignment: widget.columnVerticalAlignmentBuilder(
                      rowModel,
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
                      widget.tableBloc.select(uiRow, uiColumnIndex);
                    },
                    onHover: (_) {
                      widget.tableBloc.hover(uiRow, uiColumnIndex);
                    },
                    backgroundColor:
                        readOnly == true ? widget.disabledCellColor : null,
                    cellBorderColor: widget.cellBorderColor,
                    horizontalAlignment:
                        widget.columnHorizontalAlignmentBuilder(
                      rowModel,
                      uiColumnIndex,
                    ),
                    textStyle: widget.cellTextStyleBuilder != null
                        ? widget.cellTextStyleBuilder!(
                            rowModel,
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
                      widget.tableBloc.update(
                        uiRow,
                        uiColumnIndex,
                        newValue,
                        cellBlocState.value,
                      );
                    },
                    cellType: widget.columnTypeBuilder(uiColumnIndex),
                    value: cellBlocState.value,
                    validator: widget.columnValidatorBuilder(
                      rowModel,
                      uiColumnIndex,
                    ),
                    dropdownList: widget.columnDropdownBuilder(
                      rowModel,
                      uiColumnIndex,
                    ),
                    customCellContent: widget.cellWidgetBuilder != null
                        ? widget.cellWidgetBuilder!(
                            rowModel,
                            uiColumnIndex,
                          )
                        : null,
                  );
                },
              );
            },
            data: tableState.uiDataCache,
            buildFromId: widget.buildFromId,
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
              ParentBloc parentBloc = _getParentBLoc(syncedParentBlocs, parent);
              return ParentBuilder(
                stream: parentBloc.stream,
                builder: (expanded) {
                  return ParentWidget(
                    parent: RotatingIconRow(
                      icon: depth <= 1 ? icons[depth] : null,
                      expanded: expanded,
                      content: Row(children: cells),
                      onPressed: () {
                        parentBloc.setExpanded(!expanded);
                      },
                    ),
                    children: childrenWidgets,
                    expanded: expanded,
                  );
                },
              );
            },
            onParentUpS2: (parent, parentParent, children, depth,
                childrenWidgets, cells) {
              // ParentBloc parentBloc = _getParentBLoc(syncedParentBlocs, parent);
              ParentBloc parentBloc = syncedParentBlocs[parent]!;
              return ParentBuilder(
                stream: parentBloc.stream,
                builder: (expanded) {
                  return ParentWidget(
                    parent: RotatingIconRow(
                      icon: null,
                      expanded: expanded,
                      content: Row(children: cells),
                      onPressed: () {
                        parentBloc.setExpanded(!expanded);
                      },
                    ),
                    children: childrenWidgets,
                    expanded: expanded,
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
