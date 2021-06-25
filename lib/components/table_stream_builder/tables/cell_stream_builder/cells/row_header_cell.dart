part of premo_table;

class RowHeaderCell extends StatelessWidget {
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

  /// cell effect color configuration
  final Color? selectedColor;
  final Color? hoveredColor;
  final Color? rowColumnSelectedColor;
  final Color? rowColumnHoveredColor;
  final Color? rowCheckedColor;

  /// animations to run on cell build
  final String? animation;

  /// user events
  final VoidCallback? onTap;
  final void Function(PointerHoverEvent)? onHover;
  final void Function(PointerEnterEvent)? onMouseEnter;
  final void Function(PointerExitEvent)? onMouseExit;

  /// configurable style properties
  final Color? backgroundColor;
  final Color cellRightBorderColor;
  final Color cellBottomBorderColor;

  /// whether to display a check or empty checkbox
  final bool checked;

  final void Function(bool?)? onChanged;

  /// checkbox style configuration
  final Color? checkboxActiveColor;
  final Color? checkboxCheckColor;
  final Color? checkboxFocusColor;
  final Color? checkboxHoverColor;
  final Color? checkboxBorderColor;

  RowHeaderCell({
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
    this.selectedColor,
    this.hoveredColor,
    this.rowColumnSelectedColor,
    this.rowColumnHoveredColor,
    this.rowCheckedColor,
    this.animation,
    this.onTap,
    this.onHover,
    this.onMouseEnter,
    this.onMouseExit,

    /// [RowHeaderCell] specific API
    this.backgroundColor,
    this.cellRightBorderColor = const Color(4278190080),
    this.cellBottomBorderColor = const Color(4278190080),
    this.checked = false,
    this.onChanged,
    this.checkboxActiveColor,
    this.checkboxCheckColor,
    this.checkboxFocusColor,
    this.checkboxHoverColor,
    this.checkboxBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    Checkbox _checkbox = Checkbox(
      value: checked,
      onChanged: onChanged,
      activeColor: checkboxActiveColor,
      checkColor: checkboxCheckColor,
      focusColor: checkboxFocusColor,
      hoverColor: checkboxHoverColor,
    );
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
                color: cellRightBorderColor,
              ),
              bottom: BorderSide(
                color: cellBottomBorderColor,
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
      selectedColor: selectedColor,
      hoveredColor: hoveredColor,
      rowColumnSelectedColor: rowColumnSelectedColor,
      rowColumnHoveredColor: rowColumnHoveredColor,
      rowCheckedColor: rowCheckedColor,
      animation: animation,
      onTap: onTap,
      onHover: onHover,
      onMouseEnter: onMouseEnter,
      onMouseExit: onMouseExit,
      child: checkboxBorderColor != null
          ? Theme(
              data: ThemeData(unselectedWidgetColor: checkboxBorderColor),
              child: _checkbox,
            )
          : _checkbox,
    );
  }
}
