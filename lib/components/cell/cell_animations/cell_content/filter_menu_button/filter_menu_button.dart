part of premo_table;

/// ui component to load a button which displays a dropdown menu of filter
/// options.
class FilterMenuButton extends StatefulWidget {
  /// callback function to execute when the filter value changes
  final Function(String value) onFilter;

  final VoidCallback? onTap;

  /// icon to display for the filter button
  final Widget? icon;

  final Color? iconColor;

  /// color to change the filter button to when the filter is applied
  final Color activeFilterColor;

  /// default width of all items in the displayed dropdown menu
  final double menuItemWidth;

  FilterMenuButton({
    required this.onFilter,
    this.onTap,
    this.icon,
    this.iconColor,
    this.activeFilterColor = const Color(0xFF81C784), // Colors.green[300]
    this.menuItemWidth = 100,
  });

  @override
  _FilterMenuButtonState createState() => _FilterMenuButtonState();
}

class _FilterMenuButtonState extends State<FilterMenuButton> {
  String _filterValue = '';

  Color? _getFilterColor() {
    if (_filterValue != '') {
      return widget.activeFilterColor;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: PopupMenuButton<int>(
        color: _getFilterColor(),
        child: widget.icon ??
            Icon(
              Icons.filter_list,
              color: widget.iconColor,
            ),
        itemBuilder: (context) {
          List<PopupMenuEntry<int>> items = [
            PopupMenuItem(
              value: 1,
              child: Container(
                width: widget.menuItemWidth,
                child: TextFormField(
                  initialValue: _filterValue,
                  decoration: InputDecoration(
                    labelText: 'Enter Filter Value',
                    hintText: '...',
                  ),
                  onChanged: (value) {
                    _filterValue = value;
                    widget.onFilter(_filterValue);
                  },
                ),
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Container(
                width: widget.menuItemWidth,
                child: Row(
                  children: [
                    ElevatedButton(
                      child: Text('Clear'),
                      onPressed: () {
                        /// clear current filter value
                        setState(() {
                          _filterValue = '';
                        });

                        widget.onFilter(_filterValue);

                        /// clear dropdown menu item
                        // Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    // ElevatedButton(
                    //   child: Text('Apply'),
                    //   onPressed: () {
                    //     widget.onFilter(_filterValue);

                    //     /// clear dropdown menu item
                    //     Navigator.of(context).pop();
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ];
          return items;
        },
      ),
    );
  }
}
