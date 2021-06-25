part of premo_table;

class LegendCell extends StatelessWidget {
  /// widget to load in front of the passed child
  final Widget? leading;

  /// widget to load in behind the passed child
  final Widget? trailing;

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

  /// configurable style properties
  final Color? backgroundColor;
  final Color cellBorderColor;

  /// whether to display a check, dash or empty checkbox
  final bool? allRowsChecked;

  final void Function(bool?)? onChanged;

  LegendCell({
    /// Base [Cell] API
    this.leading,
    this.trailing,
    this.height = 50,
    this.width = 50,
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

    /// [LegendCell] specific API
    this.backgroundColor,
    this.cellBorderColor = const Color(4278190080),
    this.allRowsChecked = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Cell(
      leading: leading,
      trailing: trailing,
      height: height,
      width: width,
      padding: padding,
      verticalAlignment: verticalAlignment,
      decoration: decoration ??
          BoxDecoration(
            color: backgroundColor,
            border: Border(
              right: BorderSide(
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
      child: Checkbox(
        value: allRowsChecked,

        /// display a dash in the checkbox when the value is null
        tristate: true,
        onChanged: onChanged,
      ),
    );
  }
}
