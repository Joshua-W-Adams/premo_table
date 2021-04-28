part of premo_table;

/// Manages all content within a [Cell] of type switch
class SwitchCellContent extends StatefulWidget {
  final CellBlocState cellBlocState;

  /// cannot be edited or selected
  final bool enabled;

  /// label text, hint text, helper text, prefix icon, suffix icon
  final InputDecoration inputDecoration;

  final void Function(String)? onChanged;

  SwitchCellContent({
    required this.cellBlocState,
    this.enabled = true,
    this.inputDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(0),

      /// Required to ensure the FormField respects the cells alignment property
      /// E.g. so that the form field is centered within the parent widget.
      isDense: true,
    ),
    required this.onChanged,
  });

  @override
  _SwitchCellContentState createState() => _SwitchCellContentState();
}

class _SwitchCellContentState extends State<SwitchCellContent> {
  bool? _value;

  void initState() {
    super.initState();
    _value = widget.cellBlocState.value == 'true' ? true : false;
  }

  @override
  void didUpdateWidget(SwitchCellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.cellBlocState.value == 'true' ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      enabled: widget.enabled,
      builder: (FormFieldState<String> state) {
        return InputDecorator(
          decoration: widget.inputDecoration,
          child: Switch(
            value: _value!,
            onChanged: (val) {
              FocusScope.of(context).unfocus();
              if (widget.onChanged != null) {
                widget.onChanged!(val == true ? 'true' : 'false');
              }
            },
          ),
        );
      },
    );
  }
}
