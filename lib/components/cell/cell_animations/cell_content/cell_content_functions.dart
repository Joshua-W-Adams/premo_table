part of premo_table;

abstract class CellContentFunctions {
  static TextAlign getHorizontalAlignment(Alignment a) {
    List<Alignment> centerArr = [
      Alignment.topCenter,
      Alignment.center,
      Alignment.bottomCenter,
    ];
    List<Alignment> leftArr = [
      Alignment.topLeft,
      Alignment.centerLeft,
      Alignment.bottomLeft,
    ];
    List<Alignment> rightArr = [
      Alignment.topRight,
      Alignment.centerRight,
      Alignment.bottomRight,
    ];
    if (centerArr.contains(a)) {
      return TextAlign.center;
    } else if (leftArr.contains(a)) {
      return TextAlign.left;
    } else if (rightArr.contains(a)) {
      return TextAlign.right;
    }
    return TextAlign.start;
  }
}
