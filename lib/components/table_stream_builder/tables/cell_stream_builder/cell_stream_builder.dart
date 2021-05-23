part of premo_table;

/// [CellStreamBuilder] manages a stream of [CellBlocState] and passes the state
/// to a builder function once all stream status and errors have been handled.
class CellStreamBuilder extends StatelessWidget {
  /// bloc that controls all Cell state
  final CellBloc cellBloc;

  /// builder function to execute once all stream states have been addressed
  final Function(CellBlocState) builder;

  CellStreamBuilder({
    Key? key,
    required this.cellBloc,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CellBlocState>(
      stream: cellBloc.stream,
      builder: (_context, _snapshot) {
        if (_snapshot.connectionState == ConnectionState.waiting) {
          /// case 1 - awaiting connection
          return Center(child: Container());
        } else if (_snapshot.hasError) {
          /// case 2 - error in snapshot
          return ErrorMessage(error: '${_snapshot.error.toString()}');
        } else if (!_snapshot.hasData) {
          /// case 3 - no data recieved
          return ErrorMessage(error: 'No data recieved');
        }

        /// case 4 - all generic state checks passed
        /// build children with provided state
        return builder(_snapshot.data!);
      },
    );
  }
}
