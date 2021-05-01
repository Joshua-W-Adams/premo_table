part of premo_table;

/// Manages all content of type text in a [Cell].
class TextCellContent extends StatefulWidget {
  final CellBlocState cellBlocState;
  final TextStyle? textStyle;
  final TextAlign textAlign;

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
  final void Function(String value)? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onFocusLost;

  /// user events
  final VoidCallback? onTap;

  /// parsers for the value within the [CellBlocState] so that the data is
  /// presented in a certain format
  /// applied to all values set in a cell
  final String? Function(String?)? inputParser;
  // applied to all values returned from cell
  final String? Function(String?)? outputParser;

  /// input formatters applied to all keystrokes in the [TextFormField]
  final List<TextInputFormatter>? inputFormatters;

  TextCellContent({
    Key? key,
    required this.cellBlocState,
    this.textStyle,
    this.textAlign = TextAlign.left,
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
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onFocusLost,
    this.onTap,
    this.inputParser,
    this.outputParser,
    this.inputFormatters,
  }) : super(key: key);

  @override
  _TextCellContentState createState() => _TextCellContentState();
}

class _TextCellContentState extends State<TextCellContent> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  /// key required to perform validation on content when the value changes
  final GlobalKey<FormFieldState> _key = GlobalKey<FormFieldState>();

  void initState() {
    super.initState();
    _focusNode.addListener(() {
      /// Allow detection of on focus lost events
      if (!_focusNode.hasFocus &&
          widget.onFocusLost != null &&
          _key.currentState?.validate() == true) {
        widget.onFocusLost!(_removeValueFormat(_textController.text));
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
    String? _value = widget.cellBlocState.value;
    _value = _setValueFormat(_value);

    /// update controller value and selection position on cell state update
    _textController.value = TextEditingValue(
      text: _value,
      selection: TextSelection.collapsed(
        offset: _value.length,
      ),
    );

    return TextFormField(
      /// internal functionality
      key: _key,
      controller: _textController,
      focusNode: _focusNode,
      autocorrect: false,

      /// api properties
      style: widget.textStyle,
      textAlign: widget.textAlign,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      decoration: widget.inputDecoration,
      validator: widget.validator,
      onChanged: (val) {
        if (_key.currentState?.validate() == true && widget.onChanged != null) {
          widget.onChanged!(_removeValueFormat(val));
        }
      },
      onEditingComplete: () {
        if (_key.currentState?.validate() == true &&
            widget.onEditingComplete != null) {
          widget.onEditingComplete!(_removeValueFormat(_textController.text));
        }
      },
      onFieldSubmitted: (val) {
        if (_key.currentState?.validate() == true &&
            widget.onFieldSubmitted != null) {
          widget.onFieldSubmitted!(_removeValueFormat(val));
        }
      },
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
    );
  }
}
