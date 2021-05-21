part of premo_table;

/// Manages all content within a [Cell] of type date
class DateCellContent extends StatefulWidget {
  final String? value;
  final TextStyle? textStyle;

  final Alignment horizontalAlignment;

  /// cannot be edited but can be selected
  final bool readOnly;

  /// cannot be edited or selected
  final bool enabled;

  /// label text, hint text, helper text, prefix icon, suffix icon
  final InputDecoration? inputDecoration;

  final void Function(String)? onChanged;

  /// user events
  final VoidCallback? onTap;

  /// parsers for the string representation of the date passed to the value
  /// parameter so that the date is presented in a certain format
  /// applied to all values set in a date cell content
  final String? Function(String?) inputParser;
  // applied to all values returned from date cell content
  final String? Function(String?)? outputParser;

  final Color? cursorColor;

  DateCellContent({
    required this.value,
    this.textStyle,
    this.horizontalAlignment = Alignment.centerLeft,
    this.readOnly = true,
    this.enabled = true,
    this.inputDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(0),

      /// Required to ensure the FormField respects the cells alignment property
      /// E.g. so that the form field is centered within the parent widget.
      isDense: true,
    ),
    this.onChanged,
    this.onTap,
    this.inputParser = DataFormatter.toDate,
    this.outputParser,
    this.cursorColor,
  });

  @override
  _DateCellContentState createState() => _DateCellContentState();
}

class _DateCellContentState extends State<DateCellContent> {
  final TextEditingController _textController = TextEditingController();

  /// call dispose method to cleanup all state variables to eliminate any
  /// memory leaks.
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? initialDate = DateTime.tryParse(_textController.text);

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

    String newDate = widget.inputParser(pickedDate?.toString()) ?? '';

    /// prevent onChange callback firing on same date selected
    if (newDate != _textController.text) {
      /// update text form field data
      /// Note: will NOT fire the [TextFormField] [onChanged] event. Therefore
      /// change management must be handled
      _textController.text = newDate;

      if (widget.outputParser != null) {
        newDate = widget.outputParser!(newDate) ?? '';
      }
      if (widget.onChanged != null) {
        widget.onChanged!(newDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? _date = widget.inputParser(widget.value);

    /// update controller value and selection position on cell state update
    _textController.value = TextEditingValue(
      text: _date ?? '',
      selection: TextSelection.collapsed(
        offset: _date?.length ?? 0,
      ),
    );

    return TextFormField(
      /// internal functionality
      controller: _textController,
      autocorrect: false,

      /// api properties
      style: widget.textStyle,
      textAlign: CellContentFunctions.getHorizontalAlignment(
          widget.horizontalAlignment),
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      decoration: widget.inputDecoration,
      cursorColor: widget.cursorColor,
      onTap: () {
        /// load date selector
        _selectDate();

        /// execute on content on tap
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
    );
  }
}
