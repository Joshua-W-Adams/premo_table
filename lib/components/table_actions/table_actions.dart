part of premo_table;

/// Widget that can generate buttons for all various user possible on the Table
/// Currently supports, undo, redo, add and delete.
class TableActions extends StatelessWidget {
  final Future<void>? Function()? onAdd;
  final Future<void>? Function()? onDelete;
  final Future<void>? Function()? onUndo;
  final Future<void>? Function()? onRedo;
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
