part of premo_table;

/// [TreeTableLayout] is a ui widget intended to produce a table /
/// spreadsheet for a parent / child data structure. With the following
/// functionality:
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
class TreeTableLayout<T extends IUniqueParentChildRow> extends StatelessWidget {
  final int columnCount;
  final int? stickToColumn;
  final bool enableRowHeaders;
  final bool enableColHeaders;
  final Widget legendCell;
  final Widget Function(int columnIndex) columnHeadersBuilder;
  final Widget Function(T rowModel) rowHeadersBuilder;
  final Widget Function(int columnIndex, T rowModel) contentCellBuilder;
  final List<T> data;
  final String? buildFromId;
  final Widget Function(
    T child,
    T? parent,
    int depth,
    List<Widget> cells,
  ) onChildS1;
  final Widget Function(
    T child,
    T? parent,
    int depth,
    List<Widget> cells,
  ) onChildS2;
  final Widget Function(
    T parent,
    T? parentParent,
    List<T> children,
    int depth,
    List<Widget> childrenWidgets,
    List<Widget> cells,
  ) onParentUpS1;
  final Widget Function(
    T parent,
    T? parentParent,
    List<T> children,
    int depth,
    List<Widget> childrenWidgets,
    List<Widget> cells,
  ) onParentUpS2;
  final Widget Function(T? parent, int depth) onEndOfDepthS1;
  final Widget Function(T? parent, int depth) onEndOfDepthS2;

  TreeTableLayout({
    Key? key,

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

    /// Builder for row headers. Takes rowModel as parameter and returns a
    /// widget for displaying in row header
    required this.rowHeadersBuilder,

    /// Builder for content cells. Takes index for column and rowModel and
    /// returns a widget for displaying in cell
    required this.contentCellBuilder,

    /// data to be displayed in the tree table. Must be a parent child data
    /// model
    required this.data,

    /// id of the item in the parent child data model to build the tree from
    required this.buildFromId,

    /// A parent child widget tree is created for the quarter 3 and 4 of the
    /// [FrozenHeadersLayout] widget to enable freezing of rows and column
    /// headers
    required this.onChildS1,
    required this.onChildS2,
    required this.onParentUpS1,
    required this.onParentUpS2,
    required this.onEndOfDepthS1,
    required this.onEndOfDepthS2,
  }) : super(key: key);

  Map<int, List<Widget>> _getCells(T rowModel) {
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
    for (int col = 0; col < columnCount; col++) {
      // build BOTTOM HALF - table content
      // handle enabled row headers
      if (col == 0 && enableRowHeaders == true) {
        q3Cells.add(rowHeadersBuilder(rowModel));
      }
      if (stickToColumn != null && col <= stickToColumn!) {
        // build q3 - sticky row headers
        q3Cells.add(contentCellBuilder(col, rowModel));
      } else {
        // build q4 - scrollable cell content
        q4Cells.add(contentCellBuilder(col, rowModel));
      }
    }
    return {
      1: q3Cells,
      2: q4Cells,
    };
  }

  /// [_buildRowAndRowHeaders] loop through all rows and columns and generates
  /// the row header and row widgets.
  Map<int, Widget> _buildRowAndRowHeaders() {
    /// get all root data to start from
    List<T> roots = TreeBuilderModel.getDirectChildrenFromParent<T>(
      data: data,
      parentId: buildFromId,
    );

    /// get parent data
    T? parent = data.firstWhereOrNull((element) {
      return element.getId() == buildFromId;
    });

    /// create widget array for storing generated tree
    Map<T?, List<Widget>> treeS1 = Map<T?, List<Widget>>();
    Map<T?, List<Widget>> treeS2 = Map<T?, List<Widget>>();

    /// perform recursive loop to generate tree
    TreeBuilderModel.recursiveParentChildLoop<T>(
      parent: parent,
      depthData: roots,
      data: data,
      // depth = 0
      onChild: (T child, T? parent, int depth) {
        /// generate cell sections (rowheaders, frozen cells and cells) for row
        Map<int, List<Widget>> cells = _getCells(child);

        /// generate row sections
        Widget cWidgetS1 = onChildS1(child, parent, depth, cells[1]!);
        Widget cWidgetS2 = onChildS2(child, parent, depth, cells[2]!);

        /// store widget in current depth array
        treeS1[parent] =
            TreeBuilderModel.addToArray<T>(treeS1, cWidgetS1, parent);
        treeS2[parent] =
            TreeBuilderModel.addToArray<T>(treeS2, cWidgetS2, parent);
      },
      // unused - pass function to prevent missing callback errors
      onParentDown: (_, __, ___, ____) {},
      onParentUp: (T parent, T? parentParent, List<T> children, int depth) {
        /// generate cell sections (rowheaders, frozen cells and cells) for row
        Map<int, List<Widget>> cells = _getCells(parent);

        /// get children
        List<Widget> cWidgetsS1 = treeS1[parent]!;
        List<Widget> cWidgetsS2 = treeS2[parent]!;

        /// generate widget
        Widget pWidgetS1 = onParentUpS1(
            parent, parentParent, children, depth, cWidgetsS1, cells[1]!);
        Widget pWidgetS2 = onParentUpS2(
            parent, parentParent, children, depth, cWidgetsS2, cells[2]!);

        /// store widget
        treeS1[parentParent] =
            TreeBuilderModel.addToArray<T>(treeS1, pWidgetS1, parentParent);
        treeS2[parentParent] =
            TreeBuilderModel.addToArray<T>(treeS2, pWidgetS2, parentParent);
      },
      onEndOfDepth: (T? parent, int depth) {
        /// generate widget
        Widget endWidgetS1 = onEndOfDepthS1(parent, depth);

        /// generate widget
        Widget endWidgetS2 = onEndOfDepthS2(parent, depth);

        /// store widget
        treeS1[parent] =
            TreeBuilderModel.addToArray<T>(treeS1, endWidgetS1, parent);
        treeS2[parent] =
            TreeBuilderModel.addToArray<T>(treeS2, endWidgetS2, parent);
      },
    );

    return {
      1: treeS1[parent] != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: treeS1[parent]!,
            )
          : Container(),
      2: treeS2[parent] != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: treeS2[parent]!,
            )
          : Container(),
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<int, Widget> bottom = _buildRowAndRowHeaders();
    return ColumnHeadersBuilder(
      columnCount: columnCount,
      stickToColumn: stickToColumn,
      enableRowHeaders: enableRowHeaders,
      enableColHeaders: enableColHeaders,
      legendCell: legendCell,
      columnHeadersBuilder: columnHeadersBuilder,
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
