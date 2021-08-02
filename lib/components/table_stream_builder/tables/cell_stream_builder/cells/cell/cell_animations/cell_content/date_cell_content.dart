part of premo_table;

/// Manages all content within a [Cell] of type date. Is composed of a based
/// [TextCellContent] widget.
class DateCellContent extends StatelessWidget {
  /// Base [TextCellContent] widget
  final String? value;
  final bool selected;
  final TextStyle? textStyle;
  final Alignment horizontalAlignment;
  final bool readOnly;
  final bool enabled;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final InputDecoration? inputDecoration;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final void Function(String)? onChanged;
  final void Function(String)? onFocusLost;
  final VoidCallback? onTap;
  final String? Function(String?)? inputParser;
  final String? Function(String?)? outputParser;
  final List<TextInputFormatter>? inputFormatters;
  final Color? cursorColor;

  /// Additional properties for [DateCellContent]
  final bool enableDatePicker;
  final Icon datePickerIcon;

  DateCellContent({
    /// Base [TextCellContent] widget
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
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.onChanged,
    // this.onEditingComplete,
    // this.onFieldSubmitted,
    this.onFocusLost,
    this.onTap,
    this.inputParser = DataFormatter.toDate,
    this.outputParser,
    this.inputFormatters,
    this.cursorColor,

    /// Additional properties for [DateCellContent]
    this.enableDatePicker = true,
    this.datePickerIcon = const Icon(Icons.date_range),
  });

  Future<String> _selectDate(BuildContext context, String initialValue) async {
    DateTime? initialDate = DateTime.tryParse(initialValue);

    if (initialDate == null) {
      initialDate = DateTime.now();
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate.subtract(
        Duration(days: 20 * 365),
      ),
      lastDate: DateTime.now().add(
        Duration(days: 20 * 365),
      ),
    );

    final String newDate = inputParser?.call(pickedDate?.toString()) ?? '';

    return newDate;
  }

  @override
  Widget build(BuildContext context) {
    String? _date = inputParser?.call(value);
    return TextCellContent(
      value: _date ?? value,
      selected: selected,
      textStyle: textStyle,
      horizontalAlignment: horizontalAlignment,
      readOnly: readOnly,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputDecoration: inputDecoration,
      validator: (val) {
        if (!DataFormatter.isDate(val) && ![null, ''].contains(val)) {
          return 'yyyy-mm-dd format required';
        }
        return null;
      },
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      onFocusLost: onFocusLost,
      onTap: onTap,
      inputParser: inputParser,
      outputParser: outputParser,
      inputFormatters: inputFormatters,
      cursorColor: cursorColor,
      trailingBuilder: enableDatePicker
          ? (_context, _textController, _oldValue) {
              return IconButton(
                onPressed: enabled && !readOnly
                    ? () async {
                        final String initialDate = _textController.text;

                        /// load date selector
                        String newDate =
                            await _selectDate(_context, initialDate);

                        /// prevent onChange callback firing on same date selected
                        if (newDate != initialDate) {
                          /// update text form field data
                          /// Note: will NOT fire the [TextFormField] [onChanged]
                          /// event. Therefore change management must be handled.
                          _textController.text = newDate;

                          if (outputParser != null) {
                            newDate = outputParser!(newDate) ?? '';
                          }

                          onChanged?.call(newDate);
                          onFocusLost?.call(newDate);

                          // HOLD - Update state in parent component
                          _oldValue = newDate;
                        }
                      }
                    : null,
                icon: datePickerIcon,
              );
            }
          : null,
    );
  }
}
