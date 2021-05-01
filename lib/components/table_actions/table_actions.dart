part of premo_table;

/// Widget that can generate buttons for all various user possible on the Table
/// Currently supports, undo, redo, add and delete.
class TableActions extends StatelessWidget {
  final VoidCallback? onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final double buttonWidth;

  TableActions({
    this.onAdd,
    this.onDelete,
    this.onUndo,
    this.onRedo,
    this.buttonWidth = 125.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.start,
            children: [
              if (onUndo != null) ...[
                ActionButton(
                  text: 'Undo',
                  icon: Icon(
                    Icons.undo,
                  ),
                  onPressed: onUndo,
                  width: buttonWidth,
                ),
              ],
              if (onRedo != null) ...[
                ActionButton(
                  text: 'Redo',
                  icon: Icon(
                    Icons.redo,
                  ),
                  onPressed: onRedo,
                  width: buttonWidth,
                ),
              ],
              if (onAdd != null) ...[
                ActionButton(
                  text: 'Add',
                  icon: Icon(
                    Icons.add,
                    color: Colors.green,
                  ),
                  onPressed: onAdd,
                  width: buttonWidth,
                ),
              ],
              if (onDelete != null) ...[
                ActionButton(
                  text: 'Delete',
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: onDelete,
                  width: buttonWidth,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final Icon? icon;
  final VoidCallback? onPressed;
  final double width;

  ActionButton({
    required this.text,
    this.icon,
    this.onPressed,
    this.width = 125.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          children: [
            if (icon != null) ...[
              icon!,
              SizedBox(width: 8.0),
            ],
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
