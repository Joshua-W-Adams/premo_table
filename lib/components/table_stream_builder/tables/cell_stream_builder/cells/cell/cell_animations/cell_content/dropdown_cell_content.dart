part of premo_table;

/// Manages all content of type dropdown in a [Cell].
class DropdownCellContent extends StatefulWidget {
  final String? value;

  /// the icon to display for the dropdown button
  final Widget? icon;
  final List<String> dropdownList;

  /// label text, hint text, helper text, prefix icon, suffix icon
  final InputDecoration inputDecoration;

  final TextStyle? textStyle;
  final TextStyle? dropdownItemTextStyle;
  final Alignment horizontalAlignment;

  /// Expand dropdown button to size of parent widget
  final bool isDropdownButtonExpanded;
  final bool isDropdownButtonDense;

  /// cannot be edited or selected
  final bool enabled;

  final void Function(String)? onChanged;

  /// user events
  final VoidCallback? onTap;

  DropdownCellContent({
    Key? key,
    required this.value,
    this.icon,
    required this.dropdownList,
    this.inputDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(0),

      /// dense display of text cell. Required to ensure the textFormField
      /// respects the cells alignment property. E.g. so that the text form
      /// field is centered within the parent widget.
      isDense: true,
    ),
    this.textStyle,
    this.dropdownItemTextStyle,
    this.horizontalAlignment = Alignment.centerLeft,
    this.isDropdownButtonExpanded = false,
    this.isDropdownButtonDense = false,
    this.enabled = true,
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
    _value = widget.value;
  }

  @override
  void didUpdateWidget(DropdownCellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.value;
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
                isExpanded: widget.isDropdownButtonExpanded,

                /// conditional application of isDense. False required for correct
                /// operation on onclick events in tables. True required for
                /// correct display of dropdowns in formfields.
                isDense: widget.isDropdownButtonDense,
                hint: Text(
                  widget.inputDecoration.hintText ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
                value: _value,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  if (widget.onTap != null) {
                    widget.onTap!();
                  }
                },

                /// if on changed is null the dropdown button will be disabled
                onChanged: widget.enabled == true
                    ? (val) {
                        /// update the dropdown value
                        state.setState(() {
                          _value = val ?? '';
                        });

                        /// excecute on changed callback
                        if (widget.onChanged != null) {
                          widget.onChanged!(val ?? '');
                        }
                      }
                    : null,
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
                      style: widget.dropdownItemTextStyle ?? widget.textStyle,
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return widget.dropdownList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: widget.textStyle,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
