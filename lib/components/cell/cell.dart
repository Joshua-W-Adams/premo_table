part of premo_table;

/// [Cell] is a generic widget for displaying any type of cell in a table. Be it
/// a content cell, column header, row header or the special case legend cell
/// (position 0,0).
///
/// Content within a cell is managed separately.
///
/// Controls the stream status, cell effects (hover, clicked etc.), cell
/// animations, cell layout (height, width, alignment), styling and user
/// interaction.
class Cell extends StatelessWidget {
  /// bloc that controls all Cell state
  final CellBloc cellBloc;

  /// content
  final Widget Function(CellBlocState) builder;

  /// sizing
  final double? height;
  final double? width;

  /// styling
  final EdgeInsetsGeometry? padding;
  final Alignment verticalAlignment;
  final BoxDecoration? decoration;

  /// user events
  final VoidCallback? onTap;
  final void Function(PointerHoverEvent)? onHover;
  final void Function(PointerEnterEvent)? onMouseEnter;
  final void Function(PointerExitEvent)? onMouseExit;

  Cell({
    Key? key,
    required this.cellBloc,
    required this.builder,
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
    this.onTap,
    this.onHover,
    this.onMouseEnter,
    this.onMouseExit,
  }) : super(key: key);

  Color? _applyCellEffects(
    CellBlocState cellBlocState,
    BuildContext context,
  ) {
    Color? color;
    ThemeData theme = Theme.of(context);
    if (cellBlocState.selected == true) {
      /// case 1 - cell is selected
      color = theme.accentColor.withOpacity(0.5);
    } else if (cellBlocState.hovered == true) {
      /// case 2 - cell is hovered
      color = Colors.grey[300];
    } else if (cellBlocState.rowSelected || cellBlocState.colSelected) {
      /// case 3 - cells row or column selected
      color = theme.accentColor.withOpacity(0.25);
    } else if (cellBlocState.rowHovered || cellBlocState.colHovered) {
      /// case 4 - cell row or column hovered
      color = Colors.grey[200]!;
    } else if (cellBlocState.rowChecked == true) {
      /// case 5 - cell row checked by user
      color = theme.accentColor.withOpacity(0.10);
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CellBlocState>(
      stream: cellBloc.stream,
      builder: (_context, _snapshot) {
        if (_snapshot.connectionState == ConnectionState.waiting) {
          /// case 1 - awaiting connection
          return Center(child: CircularProgressIndicator());
        } else if (_snapshot.hasError) {
          /// case 2 - error in snapshot
          return ErrorMessage(error: '${_snapshot.error.toString()}');
        } else if (!_snapshot.hasData) {
          /// case 3 - no data recieved
          return ErrorMessage(error: 'No data recieved');
        }

        /// case 4 - all generic state checks passed
        /// get cell state released on stream
        CellBlocState cellBlocState = _snapshot.data!;

        /// determine cell effect to apply based on state
        Color? color = _applyCellEffects(cellBlocState, _context);

        /// get visibility
        bool visible = cellBlocState.visible;

        /// get requeststatus
        bool requestInProgress = cellBlocState.requestInProgress;

        return CellAnimations(
          cellBlocState: cellBlocState,
          endAnimationColor: color,
          animationHeight: height,
          widgetBuilder: (_, _colorTween, _sizeTween) {
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
                  absorbing: requestInProgress,
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
                            ? decoration?.copyWith(color: color)
                            : decoration?.copyWith(
                                color: _colorTween.isCompleted == true
                                    ? color
                                    : _colorTween.value,
                              ),
                        child: Align(
                          alignment: verticalAlignment,
                          child: requestInProgress == true
                              ? Row(
                                  children: [
                                    Expanded(child: builder(cellBlocState)),
                                    CellLoadingIndicator(),
                                  ],
                                )
                              : builder(cellBlocState),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
