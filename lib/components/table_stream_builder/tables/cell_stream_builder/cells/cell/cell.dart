part of premo_table;

/// [Cell] is a generic widget for displaying any type of cell in a table. Be it
/// a content cell, column header, row header or the special case legend cell
/// (position 0,0).
///
/// Content within a cell is managed separately.
///
/// Manages effects (hover, clicked etc.), animations, layout (height, width,
/// alignment), styling and user interaction.
class Cell extends StatelessWidget {
  /// content to load within the cell
  final Widget child;

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

  Cell({
    Key? key,
    required this.child,
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
  }) : super(key: key);

  Color? _getCellEffect(BuildContext context) {
    Color? color;
    ThemeData theme = Theme.of(context);
    if (selected == true) {
      /// case 1 - cell is selected
      color = selectedColor ?? theme.accentColor.withOpacity(0.5);
    } else if (hovered == true) {
      /// case 2 - cell is hovered
      color = hoveredColor ?? Colors.grey[300];
    } else if (rowSelected || columnSelected) {
      /// case 3 - cells row or column selected
      color = rowColumnSelectedColor ?? theme.accentColor.withOpacity(0.25);
    } else if (rowHovered || columnHovered) {
      /// case 4 - cell row or column hovered
      color = rowColumnHoveredColor ?? Colors.grey[200]!;
    } else if (rowChecked == true) {
      /// case 5 - cell row checked by user
      color = rowCheckedColor ?? theme.accentColor.withOpacity(0.10);
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    Color? effectColor = _getCellEffect(context);
    return CellAnimations(
      animation: animation,
      endAnimationColor: effectColor,
      animationHeight: height,
      builder: (_, _colorTween, _sizeTween) {
        return Visibility(
          visible: visible == false
              ? false
              : _sizeTween != null && _sizeTween.value == 0
                  ? false
                  : true,

          /// https://stackoverflow.com/questions/54717748/why-flutter-container-does-not-respects-its-width-and-height-constraints-when-it
          /// for the container widget inherently in the cell to respect the height
          /// and width constraints passed, it must be wrapped in an alignment widget
          /// so that it has a height, width, x and y position and can be painted correctly.
          child: Align(
            /// Absorb pointer used to disable all user interaction (pointer
            /// events) if there is a pending async request on the cell
            child: AbsorbPointer(
              absorbing: !enabled,
              child: MouseRegion(
                onHover: onHover,
                onEnter: onMouseEnter,
                onExit: onMouseExit,

                /// Gesture detection will not fire if the child widget has an onTap
                /// pointer event configured. i.e. in the case of a child TextFormField
                /// therefore the onTap must be provided to the [Cell] and the
                /// child widgets on tap callback.
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: _sizeTween == null ? height : _sizeTween.value,
                    width: width,
                    padding: padding,
                    decoration: _colorTween == null
                        ? decoration?.copyWith(color: effectColor)
                        : decoration?.copyWith(
                            color: _colorTween.isCompleted == true
                                ? effectColor
                                : _colorTween.value,
                          ),
                    child: Align(
                      alignment: verticalAlignment,
                      child: Row(
                        children: [
                          if (leading != null) ...[leading!],
                          Expanded(child: child),
                          if (showLoadingIndicator) ...[CellLoadingIndicator()],
                          if (trailing != null) ...[trailing!],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
