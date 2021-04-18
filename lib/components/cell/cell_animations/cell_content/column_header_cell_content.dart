part of premo_table;

/// All content within a [Cell] to be loaded as a column header.
class ColumnHeaderCellContent extends StatelessWidget {
  final CellState cellState;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final String? tooltip;
  final bool sorted;
  final bool ascending;
  final VoidCallback? onSort;
  final Function(String value)? onFilter;

  ColumnHeaderCellContent({
    Key? key,
    required this.cellState,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.tooltip,
    required this.sorted,
    required this.ascending,
    this.onSort,
    this.onFilter,
  }) : super(key: key);

  /// The default padding between the heading content and sort arrow or filter
  /// menu icon
  static const double _padding = 1.0;

  static const Duration _sortArrowAnimationDuration =
      Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    Widget label;
    label = Row(
      children: <Widget>[
        /// Column heading label
        Expanded(
          child: Text(
            cellState.value,
            style: textStyle,
            textAlign: textAlign,
          ),
        ),

        /// add sort arrow functionality
        if (onSort != null) ...<Widget>[
          SortArrow(
            visible: sorted,
            up: sorted ? ascending : false,
            duration: _sortArrowAnimationDuration,
          ),
          const SizedBox(width: _padding),
        ],

        /// add filter box to widget
        if (onFilter != null) ...<Widget>[
          FilterMenuButton(
            onFilter: onFilter!,
          ),
          const SizedBox(width: _padding),
        ],
      ],
    );

    /// append tooltip
    if (tooltip != null) {
      label = Tooltip(
        message: tooltip!,
        child: label,
      );
    }

    /// append on sort
    if (onSort != null) {
      label = GestureDetector(
        onTap: onSort,
        child: label,
      );
    }
    return label;
  }
}
