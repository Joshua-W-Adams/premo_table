part of premo_table;

/// Manages all content of type dropdown in a [Cell].
class DropdownCellContent extends StatefulWidget {
  final CellBlocState cellBlocState;
  final List<String> dropdownList;

  /// the icon to display for the dropdown button
  final Widget? icon;

  final TextStyle? textStyle;
  final Alignment horizontalAlignment;

  /// cannot be edited or selected
  final bool enabled;

  /// label text, hint text, helper text, prefix icon, suffix icon
  final InputDecoration inputDecoration;

  final void Function(String)? onChanged;

  /// user events
  final VoidCallback? onTap;

  DropdownCellContent({
    Key? key,
    required this.cellBlocState,
    required this.dropdownList,
    this.icon,
    this.textStyle,
    this.horizontalAlignment = Alignment.centerLeft,
    this.enabled = true,
    this.inputDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(0),

      /// dense display of text cell. Required to ensure the textFormField
      /// respects the cells alignment property. E.g. so that the text form
      /// field is centered within the parent widget.
      isDense: true,
    ),
    this.onChanged,
    this.onTap,
  }) : super(key: key);

  @override
  _DropdownCellContentState createState() => _DropdownCellContentState();
}

class _DropdownCellContentState extends State<DropdownCellContent> {
  /// dropdown value
  String? _value;

  void initState() {
    super.initState();
    _value = widget.cellBlocState.value ?? null;
  }

  @override
  void didUpdateWidget(DropdownCellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.cellBlocState.value ?? null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      enabled: widget.enabled,
      builder: (FormFieldState<String> state) {
        return InputDecorator(
          decoration: widget.inputDecoration,
          child: Align(
            alignment: widget.horizontalAlignment,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                icon: widget.icon,

                /// Expand dropdown button to size of parent widget
                isExpanded: true,

                /// TODO - Is this still required?
                /// conditional application of isDense. False required for correct
                /// operation on onclick events in tables. True required for
                /// correct display of dropdowns in formfields.
                // isDense: isDense,
                hint: Text(
                  widget.inputDecoration.hintText ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
                value: _value,
                style: widget.textStyle,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  if (widget.onTap != null) {
                    widget.onTap!();
                  }
                },
                onChanged: (val) {
                  /// update the dropdown value
                  state.setState(() {
                    _value = val ?? '';
                  });

                  /// excecute on changed callback
                  if (widget.onChanged != null) {
                    widget.onChanged!(val ?? '');
                  }
                },
                items: widget.dropdownList.map((String value) {
                  /// an instance of dropmenu item is returned for each item in
                  /// the dropdown menu and ALSO the displayed selected item.
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      // Dropdownmenu items must all be aligned left as per the
                      // issue currently logged on the git flutter repo.
                      // https://github.com/flutter/flutter/issues/3759
                      // textAlign: widget.textAlign,
                      style: widget.textStyle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
