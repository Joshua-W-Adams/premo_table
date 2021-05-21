part of premo_table;

class TableStreamBuilder<T extends IUniqueParentChildRow>
    extends StatelessWidget {
  final Stream<TableState<T>> stream;
  final Widget Function(TableState<T> state) builder;

  TableStreamBuilder({
    required this.stream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TableState<T>>(
        stream: stream,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            /// case 1 - awaiting connection
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            /// case 2 - error in snapshot
            return ErrorMessage(
              error: '${snapshot.error.toString()}',
            );
          } else if (!snapshot.hasData) {
            /// case 3 - no data
            return ErrorMessage(
              error: 'No data recieved from server',
            );
          }

          /// case 4 - all verification checks passed.
          return builder(snapshot.data!);
        });
  }
}
