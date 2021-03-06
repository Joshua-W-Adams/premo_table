part of premo_table;

class ContentCell extends StatelessWidget {
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
  final Color cellBorderColor;
  final Alignment horizontalAlignment;
  final TextStyle? textStyle;
  final bool readOnly;
  final void Function(String)? onChanged;
  final void Function(String)? onFocusLost;
  final CellTypes cellType;
  final Color? cursorColor;

  /// value to load into cell
  final String? value;

  /// Text, number, currency specific config
  final InputDecoration inputDecoration;
  final String? Function(String?)? validator;
  final int? minLines;
  final int? maxLines;

  /// dropdown specific config
  final List<String>? dropdownList;
  final bool isDropdownButtonExpanded;
  final bool isDropdownButtonDense;
  final Widget? icon;
  final TextStyle? dropdownItemTextStyle;

  /// custom content to load as cell child
  final Widget? customCellContent;

  ContentCell({
    /// Base [Cell] API
    this.leading,
    this.trailing,
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

    /// [ContentCell] specific API
    this.backgroundColor,
    this.cellBorderColor = const Color(4278190080),
    this.horizontalAlignment = Alignment.center,
    this.textStyle,
    this.readOnly = false,
    this.onChanged,
    this.onFocusLost,
    required this.cellType,
    this.cursorColor,
    this.value,

    /// child [TextCellContent] api
    this.inputDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(0),

      /// dense display of text cell. Required to ensure the textFormField
      /// respects the cells alignment property. E.g. so that the text form
      /// field is centered within the parent widget.
      isDense: true,
    ),
    this.validator,
    this.minLines,
    this.maxLines,

    /// child [DropdownCellContent] api
    this.dropdownList,
    this.isDropdownButtonExpanded = false,
    this.isDropdownButtonDense = false,
    this.icon,
    this.dropdownItemTextStyle,

    /// custom [Cell] content override
    this.customCellContent,
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
      child: _getCellContentType(),
    );
  }

  Widget _getCellContentType() {
    if ([CellTypes.text, CellTypes.number, CellTypes.currency]
        .contains(cellType)) {
      /// case 1 - text cell
      String? Function(String?)? inputParser;
      String? Function(String?)? outputParser;
      List<TextInputFormatter>? inputFormatters;
      TextInputType? keyboardType = TextInputType.text;

      if (cellType == CellTypes.number) {
        /// case 2 - numeric cell
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];
        outputParser = DataFormatter.toNumber;
        keyboardType = TextInputType.number;
      } else if (cellType == CellTypes.currency) {
        /// case 3 - currency cell
        inputFormatters = [
          InputFormatter(formatterCallback: DataFormatter.toCurrency)
        ];
        inputParser = DataFormatter.toCurrency;
        outputParser = DataFormatter.toNumber;
        keyboardType = TextInputType.number;
      }
      return TextCellContent(
        value: value,
        selected: selected,
        enabled: enabled,
        readOnly: readOnly,
        textStyle: textStyle,
        horizontalAlignment: horizontalAlignment,
        validator: validator,
        inputDecoration: inputDecoration,
        inputFormatters: inputFormatters,
        inputParser: inputParser,
        outputParser: outputParser,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        cursorColor: cursorColor,
        onTap: onTap,
        onChanged: onChanged,
        onFocusLost: onFocusLost,
      );
    } else if (cellType == CellTypes.dropdown) {
      return DropdownCellContent(
        value: value,
        enabled: enabled && !readOnly,
        textStyle: textStyle,
        horizontalAlignment: horizontalAlignment,
        inputDecoration: inputDecoration,
        dropdownList: dropdownList!,
        isDropdownButtonExpanded: isDropdownButtonExpanded,
        isDropdownButtonDense: isDropdownButtonDense,
        icon: icon,
        dropdownItemTextStyle: dropdownItemTextStyle,
        onTap: onTap,
        onChanged: (newValue) {
          onChanged?.call(newValue);
          onFocusLost?.call(newValue);
        },
      );
    } else if (cellType == CellTypes.cellswitch) {
      return SwitchCellContent(
        value: value,
        enabled: enabled && !readOnly,
        horizontalAlignment: horizontalAlignment,
        inputDecoration: inputDecoration,
        onChanged: (newValue) {
          onTap?.call();
          onChanged?.call(newValue);
          onFocusLost?.call(newValue);
        },
      );
    } else if (cellType == CellTypes.date) {
      return DateCellContent(
        value: value,
        selected: selected,
        enabled: enabled,
        readOnly: readOnly,
        textStyle: textStyle,
        horizontalAlignment: horizontalAlignment,
        // validator: validator,
        inputDecoration: inputDecoration,
        // inputFormatters: inputFormatters,
        inputParser: DataFormatter.toDate,
        // outputParser: outputParser,
        // keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        cursorColor: cursorColor,
        onTap: onTap,
        onChanged: onChanged,
        onFocusLost: onFocusLost,
      );
    } else if (cellType == CellTypes.custom) {
      return customCellContent!;
    }

    /// Cell type not supported
    return Container();
  }
}
