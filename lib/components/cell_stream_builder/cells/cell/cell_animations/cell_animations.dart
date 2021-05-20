part of premo_table;

/// Controls all cell animations.
///
/// Will animate the both the cell background colours and sizes based on the
/// provided animation string.
class CellAnimations extends StatefulWidget {
  /// current state of the cell
  final String? animation;

  /// widget to be animated
  final Widget Function(
    BuildContext context,
    Animation<Color?>? colorTween,
    Animation<double>? _sizeTween,
  ) builder;

  /// color to finish all animations at
  final Color? endAnimationColor;

  /// height to animate from or too based on the animation specifying an add or
  /// delete. If no height is provided no size animation will occur.
  final double? animationHeight;

  CellAnimations({
    this.animation,
    required this.builder,
    this.endAnimationColor,
    this.animationHeight,
  }) : assert(animations.contains(animation),
            'Animation must be one of the following: ${animations.toString()}');

  /// supported list of animations
  static final animations = [
    'add',
    'delete',
    'update',
    'duplicate',
    'requestPassed',
    'requestFailed',
    null,
  ];

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

    _runAnimation();
  }

  @override
  void didUpdateWidget(CellAnimations oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runAnimation();
  }

  /// call dispose method to cleanup all cell state variables to eliminate any
  /// memory leaks
  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  void _runAnimation() {
    /// set tween to animate
    _colorTween = _getColorTween(widget.animation);
    _sizeTween = _getSizeTween(widget.animation);

    if (_colorTween != null || _sizeTween != null) {
      /// case 1 - animation string has associated animation
      _animate();
    }

    /// case 2 - no animation to play
  }

  Color? _getAnimationColor(String? animation) {
    if (animation == 'update') {
      /// case 1 - cell change recieved from server
      return Colors.orange;
    } else if (animation == 'add') {
      /// case 2 - newly added row
      return Colors.green;
    } else if (animation == 'delete') {
      /// case 3 - deleted row
      return Colors.red;
    } else if (animation == 'duplicate') {
      /// case 3 - deleted row
      return Colors.red[900];
    } else if (animation == 'requestPassed') {
      /// case 5 - client/user change passed
      return Colors.green;
    } else if (animation == 'requestFailed') {
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
  Animation<Color?>? _getColorTween(String? animation) {
    Color? animationColor = _getAnimationColor(animation);
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
  Animation<double>? _getSizeTween(String? animation) {
    if (['add', 'duplicate'].contains(animation)) {
      /// case 1 - newly added row
      return Tween<double>(
        begin: 0.0,
        end: widget.animationHeight ?? 0,
      ).animate(_animationController!);
    } else if (animation == 'delete') {
      /// case 2 - deleted row
      return Tween<double>(
        begin: widget.animationHeight ?? 0,
        end: 0.0,
      ).animate(_animationController!);
    }

    /// no animation configured for provided animation
    return null;
  }

  /// run animations
  void _animate() {
    _animationController!.reset();
    _animationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _colorTween, _sizeTween);
  }
}
