part of premo_table;

/// Controls all cell animations.
///
/// Will animate the both the cell background colours and sizes based on the
/// provided [CellBlocState].
class CellAnimations extends StatefulWidget {
  /// current state of the cell
  final CellBlocState cellBlocState;

  /// widget to be animated
  final Widget Function(BuildContext context, Animation<Color?>? colorTween,
      Animation<double>? _sizeTween) widgetBuilder;

  /// color to finish all animations at
  final Color? endAnimationColor;

  /// height to animate from or too based on the [CellBlocState] reporting an
  /// add or delete. if no height is provided no size animation will occur.
  final double? animationHeight;

  CellAnimations({
    required this.cellBlocState,
    required this.widgetBuilder,
    this.endAnimationColor,
    this.animationHeight,
  });

  @override
  _CellAnimationsState createState() => _CellAnimationsState();
}

/// [SingleTickerProviderStateMixin] mixin class is required to "mix in" the
/// additional functionality required to animate a widget.
class _CellAnimationsState extends State<CellAnimations>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<Color?>? _colorTween;
  Animation<double>? _sizeTween;

  @override
  void initState() {
    super.initState();

    /// create animation controller and sync to widget state
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 1000,
      ),
    );

    /// rebuild widget every time the animation fires
    _animationController!.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(CellAnimations oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// set tween to animate
    _colorTween = _getColorTween(widget.cellBlocState);
    _sizeTween = _getSizeTween(widget.cellBlocState);

    if (_colorTween != null || _sizeTween != null) {
      /// case 1 - [CellBlocState] has associated animation
      _animate();
    }

    /// case 2 - no animation to play
  }

  /// call dispose method to cleanup all cell state variables to eliminate any
  /// memory leaks
  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  Color? _getAnimationColor(CellBlocState cellBlocState) {
    if (cellBlocState.changeType == ChangeTypes.update) {
      /// case 1 - cell change recieved from server
      return Colors.orange;
    } else if (cellBlocState.changeType == ChangeTypes.add) {
      /// case 2 - newly added row
      return Colors.green;
    } else if (cellBlocState.changeType == ChangeTypes.delete) {
      /// case 3 - deleted row
      return Colors.red;
    } else if (cellBlocState.changeType == ChangeTypes.duplicate) {
      /// case 3 - deleted row
      return Colors.red[900];
    } else if (cellBlocState.requestSucceeded == true) {
      /// case 5 - client/user change passed
      return Colors.green;
    } else if (cellBlocState.requestSucceeded == false) {
      /// case 6 - client/user change failed
      return Colors.red;
    }

    /// case 6 - no animation color configured for provided [CellBlocState]
    return null;
  }

  /// *********************** Configure animation TWEENS ***********************
  /// A Tween is a linear interpolation between two
  /// values. A tween is a key process in all animations. It is effectively the
  /// process of generating the frames between two images to create an animation.

  /// Tween for animating cell colours
  Animation<Color?>? _getColorTween(CellBlocState cellBlocState) {
    Color? animationColor = _getAnimationColor(cellBlocState);
    if (animationColor != null) {
      /// case 1 - animation available
      return ColorTween(
        begin: animationColor,
        end: widget.endAnimationColor,
      ).animate(_animationController!);
    }

    /// case 2 - no animation configured for provided [CellBlocState]
    return null;
  }

  /// Tween for collapsing and expanding rows
  Animation<double>? _getSizeTween(CellBlocState cellBlocState) {
    if (cellBlocState.changeType == ChangeTypes.add ||
        cellBlocState.changeType == ChangeTypes.duplicate) {
      /// case 1 - newly added row
      return Tween<double>(
        begin: 0.0,
        end: widget.animationHeight ?? 0,
      ).animate(_animationController!);
    } else if (cellBlocState.changeType == ChangeTypes.delete) {
      /// case 2 - deleted row
      return Tween<double>(
        begin: widget.animationHeight ?? 0,
        end: 0.0,
      ).animate(_animationController!);
    }

    /// no animation configured for provided [CellBlocState]
    return null;
  }

  /// run animations
  void _animate() {
    _animationController!.reset();
    _animationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return widget.widgetBuilder(context, _colorTween, _sizeTween);
  }
}
