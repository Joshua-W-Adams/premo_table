part of premo_table;

class ActionButton extends StatefulWidget {
  final String text;
  final Icon? icon;

  /// if future is returned from the onPressed function the button will be
  /// disabled until the future has finished processing.
  final Future<void>? Function()? onPressed;
  final double width;

  ActionButton({
    required this.text,
    this.icon,
    this.onPressed,
    this.width = 125.0,
  });

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _requestProcessing = false;

  void _onPressed() {
    /// get future
    Future<void>? future = widget.onPressed?.call();

    if (future != null) {
      /// case 1 - future returned. Allow management of button state
      setState(() {
        _requestProcessing = true;
      });
      future.then((_) {
        setState(() {
          _requestProcessing = false;
        });
      }).onError((_, __) {
        setState(() {
          _requestProcessing = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: ElevatedButton(
        onPressed: _requestProcessing == false ? _onPressed : null,
        child: Row(
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              SizedBox(width: 8.0),
            ],
            Expanded(
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
              ),
            ),
            if (_requestProcessing == true) ...[
              SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
