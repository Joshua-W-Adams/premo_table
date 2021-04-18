part of premo_table;

/// Controls all cell animations.
///
/// Will animate the cell background colours based on the provided [CellState].
class CellAnimations extends StatefulWidget {
  /// current state of the cell
  final CellState cellState;

  /// widget to be animated
  final Widget Function(BuildContext context, Animation? animationTween)
      widgetBuilder;

  /// color to finish all animations at
  final Color? endAnimationColor;

  CellAnimations({
    required this.cellState,
    required this.widgetBuilder,
    this.endAnimationColor,
  });

  @override
  _CellAnimationsState createState() => _CellAnimationsState();
}

/// [SingleTickerProviderStateMixin] mixin class is required to "mix in" the
/// additional functionality required to animate a widget.
class _CellAnimationsState extends State<CellAnimations>
    with SingleTickerProviderStateMixin {
  /// local anaimation properties
  AnimationController? _animationController;
  Animation? _animationTween;

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
  }

  /// Configure animation TWEENS. A Tween is a linear interpolation between two
  /// values. A tween is a key process in all animations. It is effectively the
  /// process of generating the frames between two images to create an animation.
  Animation? _getColorTween(CellState cellState) {
    if (cellState.serverUpdate == true) {
      /// case 1 - cell change recieved from server
      return ColorTween(
        begin: Colors.orange,
        end: widget.endAnimationColor,
      ).animate(_animationController!);
    } else if (cellState.requestSucceeded == true) {
      /// case 2 - client/user change passed
      return ColorTween(
        begin: Colors.green,
        end: widget.endAnimationColor,
      ).animate(_animationController!);
    } else if (cellState.requestSucceeded == false) {
      /// case 3 - client/user change failed
      return ColorTween(
        begin: Colors.red,
        end: widget.endAnimationColor,
      ).animate(_animationController!);
    } else {
      /// no animation configured for provided [CellState]
      return null;
    }
  }

  /// call dispose method to cleanup all cell state variables to eliminate any
  /// memory leaks.
  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  /// run animations
  void _animate() {
    _animationController!.reset();
    _animationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    /// set tween to animate
    _animationTween = _getColorTween(widget.cellState);

    if (_animationTween != null) {
      /// case 1 - [CellState] has associated animation
      _animate();
      return AnimatedBuilder(
        animation: _animationTween!,
        builder: (_context, __) {
          return widget.widgetBuilder(_context, _animationTween);
        },
      );
    } else {
      /// case 2 - no animation to play
      return widget.widgetBuilder(context, null);
    }
  }
}
