part of premo_table;

class ContentCell extends StatelessWidget {
  /// all cell operations are controlled in the tableBloC so cell state changes
  /// and operations can be shared through all relevant components in the table
  final TableBloc tableBloc;

  /// indexs of the cell in the displayed ui which is output in the [uiRow]s
  /// property from the tableBloc
  final int uiRowIndex;
  final int uiColumnIndex;

  /// configurable style properties
  final double width;
  final double height;
  final Color cellBorderColor;
  final Color disabledCellColor;
  final CellTypes cellType;
  final bool readOnly;
  final TextStyle? textStyle;
  final Alignment horizontalAlignment;
  final Alignment verticalAlignment;
  final List<String>? dropdownList;
  final String? Function(String?)? validator;
  final Widget? customCellContent;

  ContentCell({
    required this.tableBloc,
    required this.uiRowIndex,
    required this.uiColumnIndex,
    required this.width,
    this.height = 50,
    required this.cellBorderColor,
    required this.disabledCellColor,
    required this.cellType,
    required this.readOnly,
    this.textStyle,
    this.horizontalAlignment = Alignment.center,
    this.verticalAlignment = Alignment.center,
    this.dropdownList,
    this.validator,
    this.customCellContent,
  });

  @override
  Widget build(BuildContext context) {
    /// block assigned to each cell is final and does not change, however the
    /// values within the cell and the cells state will
    CellBloc cellBloc =
        tableBloc.tableState!.uiRows[uiRowIndex].cellBlocs[uiColumnIndex];
    return Cell(
      cellBloc: cellBloc,
      height: height,
      width: width,
      verticalAlignment: verticalAlignment,
      decoration: BoxDecoration(
        color: readOnly == true ? disabledCellColor : null,
        border: Border(
          right: BorderSide(
            color: cellBorderColor,
          ),
          bottom: BorderSide(
            color: cellBorderColor,
          ),
        ),
      ),
      onTap: () {
        tableBloc.select(uiRowIndex, uiColumnIndex);
      },
      onHover: (_) {
        tableBloc.hover(uiRowIndex, uiColumnIndex);
      },
      builder: (cellBlocState) {
        TableState tableState = tableBloc.tableState!;
        UiRow uiRow = tableState.uiRows[uiRowIndex];

        if (cellType == CellTypes.text ||
            cellType == CellTypes.number ||
            cellType == CellTypes.currency) {
          /// case 1 - text cell
          String? Function(String?)? inputParser;
          String? Function(String?)? outputParser;
          List<TextInputFormatter>? inputFormatters;
          TextInputType? keyboardType = TextInputType.text;

          if (cellType == CellTypes.number) {
            /// case 2 - numeric cell
            inputFormatters = [FilteringTextInputFormatter.digitsOnly];
            outputParser = DataFormatter.toNumber;
            keyboardType = TextInputType.number;
          } else if (cellType == CellTypes.currency) {
            /// case 3 - currency cell
            inputFormatters = [
              InputFormatter(formatterCallback: DataFormatter.toCurrency)
            ];
            inputParser = DataFormatter.toCurrency;
            outputParser = DataFormatter.toNumber;
            keyboardType = TextInputType.number;
          }

          return TextCellContent(
            cellBlocState: cellBlocState,
            enabled: !cellBlocState.requestInProgress,
            readOnly: readOnly,
            textStyle: textStyle,
            horizontalAlignment: horizontalAlignment,
            validator: validator,
            inputFormatters: inputFormatters,
            inputParser: inputParser,
            outputParser: outputParser,
            keyboardType: keyboardType,
            onTap: () {
              tableBloc.select(uiRowIndex, uiColumnIndex);
            },

            /// On focus lost fired when the user clicks out of the text cell
            /// or completes editing / submits value
            onFocusLost: (newValue) {
              /// server modifications never loose focus so checking the change
              /// state is not required.
              if (uiRow.rowState.rowModel != null) {
                tableBloc.update(
                  uiRow,
                  uiColumnIndex,
                  newValue,
                  cellBloc.state.value,
                );
              }
            },
          );
        } else if (cellType == CellTypes.dropdown) {
          return DropdownCellContent(
            cellBlocState: cellBlocState,
            enabled: !cellBlocState.requestInProgress && !readOnly,
            textStyle: textStyle,
            horizontalAlignment: horizontalAlignment,
            dropdownList: dropdownList!,
            onTap: () {
              tableBloc.select(uiRowIndex, uiColumnIndex);
            },
            onChanged: (newValue) {
              if (uiRow.rowState.rowModel != null) {
                tableBloc.update(
                  uiRow,
                  uiColumnIndex,
                  newValue,
                  cellBloc.state.value,
                );
              }
            },
          );
        } else if (cellType == CellTypes.cellswitch) {
          return SwitchCellContent(
            cellBlocState: cellBlocState,
            enabled: !cellBlocState.requestInProgress && !readOnly,
            horizontalAlignment: horizontalAlignment,
            onChanged: (newValue) {
              tableBloc.select(uiRowIndex, uiColumnIndex);
              if (uiRow.rowState.rowModel != null) {
                tableBloc.update(
                  uiRow,
                  uiColumnIndex,
                  newValue,
                  cellBloc.state.value,
                );
              }
            },
          );
        } else if (cellType == CellTypes.date) {
          return DateCellContent(
            cellBlocState: cellBlocState,
            enabled: !cellBlocState.requestInProgress && !readOnly,
            textStyle: textStyle,
            horizontalAlignment: horizontalAlignment,
            inputParser: DataFormatter.toDate,
            onTap: () {
              tableBloc.select(uiRowIndex, uiColumnIndex);
            },
            onChanged: (newValue) {
              if (uiRow.rowState.rowModel != null) {
                tableBloc.update(
                  uiRow,
                  uiColumnIndex,
                  newValue,
                  cellBloc.state.value,
                );
              }
            },
          );
        } else if (cellType == CellTypes.custom) {
          return customCellContent!;
        }

        /// Cell type not supported
        return Container();
      },
    );
  }
}
