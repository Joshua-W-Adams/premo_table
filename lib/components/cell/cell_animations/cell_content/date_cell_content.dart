part of premo_table;

/// Manages all content within a [Cell] of type date
class DateCellContent extends StatefulWidget {
  final CellState cellState;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  /// cannot be edited but can be selected
  final bool readOnly;

  /// cannot be edited or selected
  final bool enabled;

  /// label text, hint text, helper text, prefix icon, suffix icon
  final InputDecoration? inputDecoration;

  /// text field validator
  final void Function(String)? onChanged;

  /// user events
  final VoidCallback? onTap;

  DateCellContent({
    required this.cellState,
    this.textStyle,
    this.textAlign = TextAlign.left,
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
  });

  @override
  _DateCellContentState createState() => _DateCellContentState();
}

class _DateCellContentState extends State<DateCellContent> {
  final TextEditingController _textController = TextEditingController();

  /// required to enforce data formats for dates and currencies.
  final DataFormatter _dataFormatter = DataFormatter();

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
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
        Duration(days: 20 * 365),
      ),
    );

    _textController.text = _dataFormatter.toDate(pickedDate?.toString()) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    String? _date = _dataFormatter.toDate(widget.cellState.value);

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
      textAlign: widget.textAlign,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      decoration: widget.inputDecoration,
      onChanged: widget.onChanged,
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
