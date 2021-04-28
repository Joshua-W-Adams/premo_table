part of premo_table;

/// [InputFormatter] is a generic input formatter class that accepts a callback
/// function to format the current inputs value.
class InputFormatter extends TextInputFormatter {
  final String? Function(String? text) formatterCallback;

  InputFormatter({
    required this.formatterCallback,
  });

  TextSelection? _getTextSelectionDetails(
    TextEditingValue originalText,
    String formattedText,
  ) {
    int diff = originalText.text.length - formattedText.length;
    // text has been formatted to add or remove characters
    if (diff != 0) {
      // set new cursor position
      return TextSelection.collapsed(
        offset: originalText.selection.extent.offset - diff,
      );
    }
    return null;
  }

  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // new value is nothing.
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    // format new value
    String formattedText = formatterCallback(newValue.text) ?? '';
    return newValue.copyWith(
      // set new text value
      text: formattedText,
      // set new cursor position
      selection: _getTextSelectionDetails(
            newValue,
            formattedText,
          ) ??
          null,
    );
  }
}
