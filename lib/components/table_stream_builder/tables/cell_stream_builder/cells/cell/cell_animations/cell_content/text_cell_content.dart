part of premo_table;

/// Manages all content of type text in a [Cell].
class TextCellContent extends StatefulWidget {
  final String? value;
  final bool selected;
  final TextStyle? textStyle;
  final Alignment horizontalAlignment;

  /// cannot be edited but can be selected
  final bool readOnly;

  /// cannot be edited or selected
  final bool enabled;

  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;

  /// label text, hint text, helper text, prefix icon, suffix icon
  final InputDecoration? inputDecoration;

  /// text field validator
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  // final void Function(String value)? onEditingComplete;
  // final void Function(String)? onFieldSubmitted;
  final void Function(String)? onFocusLost;

  /// user events
  final VoidCallback? onTap;

  /// parsers for the value property so that the data is can be presented in a
  /// certain format
  /// applied to all values set in a cell
  final String? Function(String?)? inputParser;
  // applied to all values returned from cell
  final String? Function(String?)? outputParser;

  /// input formatters applied to all keystrokes in the [TextFormField]
  final List<TextInputFormatter>? inputFormatters;

  final Color? cursorColor;

  TextCellContent({
    Key? key,
    required this.value,
    required this.selected,
    this.textStyle,
    this.horizontalAlignment = Alignment.centerLeft,
    this.readOnly = false,
    this.enabled = true,
    this.minLines,
    this.maxLines,
    this.keyboardType = TextInputType.text,
    this.inputDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(0),

      /// dense display of text cell. Required to ensure the textFormField
      /// respects the cells alignment property. E.g. so that the text form
      /// field is centered within the parent widget.
      isDense: true,
    ),
    this.validator,
    this.onChanged,
    // this.onEditingComplete,
    // this.onFieldSubmitted,
    this.onFocusLost,
    this.onTap,
    this.inputParser,
    this.outputParser,
    this.inputFormatters,
    this.cursorColor,
  }) : super(key: key);

  @override
  _TextCellContentState createState() => _TextCellContentState();
}

class _TextCellContentState extends State<TextCellContent> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  /// key required to perform validation on content when the value changes
  final GlobalKey<FormFieldState> _key = GlobalKey<FormFieldState>();

  String? _oldValue;

  void initState() {
    super.initState();

    /// store value to enablechange detection
    _oldValue = _setValueFormat(widget.value);
    _textController.text = _oldValue!;

    _focusNode.addListener(() {
      /// Allow detection of on focus lost events
      if (!_focusNode.hasFocus &&
          widget.onFocusLost != null &&
          _key.currentState?.validate() == true) {
        if (_oldValue != _textController.text) {
          /// update current value
          _oldValue = _textController.text;

          /// only fire onFocusLost if the value has changed
          widget.onFocusLost!(_removeValueFormat(_oldValue));
        }
      }
    });
  }

  /// call dispose method to cleanup all state variables to eliminate any
  /// memory leaks.
  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TextCellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldValue = _setValueFormat(widget.value);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      /// update controller value and selection position on cell state update
      _textController.value = TextEditingValue(
        text: _oldValue!,
        selection: TextSelection.collapsed(
          offset: _oldValue!.length,
        ),
      );
    });
    if (_focusNode.hasFocus && widget.selected == false) {
      FocusScope.of(context).unfocus();
    }
  }

  String _setValueFormat(String? value) {
    if (widget.inputParser != null) {
      return widget.inputParser!(value) ?? '';
    }
    return value ?? '';
  }

  String _removeValueFormat(String? value) {
    if (widget.outputParser != null) {
      return widget.outputParser!(value) ?? '';
    }
    return value ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      /// internal functionality
      key: _key,
      controller: _textController,
      focusNode: _focusNode,
      autocorrect: false,

      /// api properties
      style: widget.textStyle,
      textAlign: CellContentFunctions.getHorizontalAlignment(
          widget.horizontalAlignment),
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      decoration: widget.inputDecoration,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      cursorColor: widget.cursorColor,

      /// cell functions
      onTap: widget.onTap,
      onChanged: (val) {
        if (_key.currentState?.validate() == true) {
          widget.onChanged?.call(_removeValueFormat(val));
        }
      },

      /// both the onEditingComplete and onFieldSubmitted callbacks have been
      /// disabled so that the onFocusLost callback is used instead.
      /// onFocusLost will fire when the user submits the TextFormField and also
      /// when they click out of the cell or get kicked out of the cell on other
      /// user events.
      ///
      /// Assigning the same function to the onFocusLost and onEditingComplete ||
      /// onFieldSubmitted callbacks was causing the same function to run twice.
      /// For example the same update changes to database function to run twice.
      ///
      /// overwriting this method will cause the focus node to persist focus
      /// on the text field even after editing is completed
      // onEditingComplete: () {
      //   if (_key.currentState?.validate() == true &&
      //       widget.onEditingComplete != null) {
      //     widget.onEditingComplete!(_removeValueFormat(_textController.text));
      //   }
      // },
      // onFieldSubmitted: (val) {
      //   if (_key.currentState?.validate() == true &&
      //       widget.onFieldSubmitted != null) {
      //     widget.onFieldSubmitted!(_removeValueFormat(val));
      //   }
      // },
    );
  }
}
