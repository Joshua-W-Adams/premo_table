part of premo_table;

class ColumnHeaderCell extends StatelessWidget {
  /// sizing
  final double? height;
  final double? width;

  /// styling
  final EdgeInsetsGeometry? padding;
  final Alignment verticalAlignment;
  final BoxDecoration? decoration;

  /// misc functionality
  final bool visible;
  final bool enabled;
  final bool showLoadingIndicator;

  /// cell effects to apply on user interaction
  final bool selected;
  final bool rowSelected;
  final bool columnSelected;
  final bool hovered;
  final bool rowHovered;
  final bool columnHovered;
  final bool rowChecked;

  /// animations to run on cell build
  final String? animation;

  /// user events
  final VoidCallback? onTap;
  final void Function(PointerHoverEvent)? onHover;
  final void Function(PointerEnterEvent)? onMouseEnter;
  final void Function(PointerExitEvent)? onMouseExit;

  /// column header specific style properties
  final Color? backgroundColor;
  final Color cellBorderColor;

  /// value to load into the column header
  final String? value;

  /// configurable style properties
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final String? tooltip;
  final bool sorted;
  final bool ascending;

  /// configurable functionality
  final VoidCallback? onSort;
  final Function(String value)? onFilter;
  final VoidCallback? onFilterButtonTap;

  ColumnHeaderCell({
    /// Base [Cell] API
    this.height = 50,
    this.width = 70,
    this.padding = const EdgeInsets.only(
      left: 5.0,
      right: 5.0,
      top: 5.0,
      bottom: 5.0,
    ),
    this.verticalAlignment = Alignment.center,
    this.decoration,
    this.visible = true,
    this.enabled = true,
    this.showLoadingIndicator = false,
    this.selected = false,
    this.rowSelected = false,
    this.columnSelected = false,
    this.hovered = false,
    this.rowHovered = false,
    this.columnHovered = false,
    this.rowChecked = false,
    this.animation,
    this.onTap,
    this.onHover,
    this.onMouseEnter,
    this.onMouseExit,

    /// [ColumnHeaderCell] specific API
    this.backgroundColor,
    this.cellBorderColor = const Color(4278190080),

    /// child [ColumnHeaderCellContent] API
    this.value,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.tooltip,
    this.sorted = false,
    this.ascending = false,
    this.onSort,
    this.onFilter,
    this.onFilterButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Cell(
      height: height,
      width: width,
      padding: padding,
      verticalAlignment: verticalAlignment,
      decoration: decoration ??
          BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(
                color: cellBorderColor,
              ),
              right: BorderSide(
                color: cellBorderColor,
              ),
              bottom: BorderSide(
                color: cellBorderColor,
              ),
            ),
          ),
      visible: visible,
      enabled: enabled,
      showLoadingIndicator: showLoadingIndicator,
      selected: selected,
      rowSelected: rowSelected,
      columnSelected: columnSelected,
      hovered: hovered,
      rowHovered: rowHovered,
      columnHovered: columnHovered,
      rowChecked: rowChecked,
      animation: animation,
      onTap: onTap,
      onHover: onHover,
      onMouseEnter: onMouseEnter,
      onMouseExit: onMouseExit,
      child: ColumnHeaderCellContent(
        value: value,
        textStyle: textStyle,
        textAlign: textAlign,
        tooltip: tooltip,
        sorted: sorted,
        ascending: ascending,
        onSort: onSort,
        onFilter: onFilter,
        onFilterButtonTap: onFilterButtonTap,
      ),
    );
  }
}
