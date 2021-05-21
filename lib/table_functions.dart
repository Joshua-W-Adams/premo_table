part of premo_table;

abstract class TableFunctions {
  static String? getAnimation(CellBlocState cellBlocState) {
    ChangeTypes? changeType = cellBlocState.changeType;
    if (changeType != null) {
      if (changeType == ChangeTypes.add) {
        return 'add';
      } else if (changeType == ChangeTypes.delete) {
        return 'delete';
      } else if (changeType == ChangeTypes.update) {
        return 'update';
      } else if (changeType == ChangeTypes.duplicate) {
        return 'duplicate';
      }
    } else if (cellBlocState.requestSucceeded == true) {
      return 'requestPassed';
    } else if (cellBlocState.requestSucceeded == false) {
      return 'requestFailed';
    }
    return null;
  }
}
