part of premo_table;

/// [DataFormatter] is a generic class that contains Regex based functions for
/// formatting stings as certain types. For example decimals, currencies etc.
abstract class DataFormatter {
  /// [^] = negated set... match any character that is not in the set
  /// Therefore matches everything that is not a 0-9, . or - and replaces
  /// with nothing.
  static String? toNumber(String? value) {
    if (value == null) {
      return value;
    }
    return value.replaceAll(RegExp(r"[^0-9.-]"), "");
  }

  /// [?<=] = positive look behind... matches a group BEFORE the main expression
  /// e.g. matches a . followed by 2 numbers before matching a digit repeating
  /// any number of times
  static String? toDecimal(String? value) {
    if (value == null) {
      return value;
    }
    return value.replaceAll(RegExp(r"(?<=\.[0-9]{2})\d*"), "");
  }

  /// (\d) = any digit
  /// ?= = postive lookahead
  /// \d{3} = any 3 digits
  /// i.e. match any digit followed by 3 digits
  static String? addCommas(String? value) {
    if (value == null) {
      return value;
    }
    return value.replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (Match m) {
      return '${m.group(0)},';
    });
  }

  static String? addTrailingZeros(String? value) {
    if (value == null) {
      return null;
    } else if (!value.contains('.')) {
      return '$value.00';
    } else {
      if (value.indexOf('.') == (value.length - 2)) {
        return '${value}0';
      }
      return value;
    }
  }

  static String? toCurrency(String? value) {
    if (value == null) {
      return value;
    }

    /// remove $ sign and any other necessary characters
    value = toNumber(value);
    // enforce 2 decimal places
    value = toDecimal(value);
    // add trailing 0's
    // value = addTrailingZeros(value);
    // add commmas
    value = addCommas(value);
    // append $ sign
    if (value != null && value != '') {
      return '\$ $value';
    }
    return value;
  }

  static String? toDate(String? value) {
    if (value == null) {
      return value;
    }
    return RegExp(r"([0-9]{4}\-[0-9]{2}\-[0-9]{2})")
        .firstMatch(value)
        ?.group(0);
  }

  static bool isDate(String? date) {
    if (date == null) {
      return false;
    }

    /// ref. https://stackoverflow.com/questions/15491894/regex-to-validate-date-format-dd-mm-yyyy-with-leap-year-support
    RegExp regExp = RegExp(
      r"^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$",
    );
    return regExp.hasMatch(date);
  }

  /// [isInt] will check a string to determine if there are any matches for a
  /// character that is not a digit. If a match is made then the string is not
  /// considered an integer.
  static bool isInt(String value) {
    return !value.contains(RegExp(r"[^\d]"));
  }

  /// [intToDouble] will convert a integer to a double of one decimal place only
  /// on the case an integer is detected.
  static String? intToDouble(String? value) {
    if (value == null) {
      return value;
    }
    if (isInt(value)) {
      return '$value.0';
    }
    return value;
  }

  /// [isDoubleAnInt] checks for the case that an integer value is formatted as
  /// a decimal / double. i.e is it a number followed by a . and any number of 0
  /// characters.
  static bool isDoubleAnInt(String value) {
    return value.contains(RegExp(r"^-?\d+\.0+$"));
  }

  /// [doubleToInt] Will convert a interger formatted as a double to an integer
  /// format.
  static String? doubleToInt(String? value) {
    if (value == null) {
      return null;
    }
    if (isDoubleAnInt(value)) {
      return RegExp(r"^-?\d+(?!\d\.)").firstMatch(value)?.group(0);
    }
    return value;
  }

  /// [handleScientificNotation] will convert a number in scientific notation to
  /// its exact (non scientific) string representation.
  static String? handleScientificNotation(num? value) {
    if (value == null) {
      return null;
    }
    var sign = "";
    if (value < 0) {
      value = -value;
      sign = "-";
    }
    var string = value.toString();
    var e = string.lastIndexOf('e');
    if (e < 0) {
      // case 1 - no scientific notation in double
      return "$sign$string";
    }
    // case 2 - scientific notation detected
    if (string.indexOf('.') != 1) {
      /// case 2.1 - no decimal in large number...
      /// display with specificed number of decimal places
      return value.toStringAsFixed(2);
    }

    /// case 2.2 - otherwise
    assert(string.indexOf('.') == 1);
    var offset = int.parse(
      string.substring(
        e + (string.startsWith('-', e + 1) ? 1 : 2),
      ),
    );
    var digits = string.substring(0, 1) + string.substring(2, e);
    if (offset < 0) {
      return "${sign}0.${"0" * ~offset}$digits";
    }
    if (offset > 0) {
      if (offset >= digits.length) {
        return sign + digits.padRight(offset + 1, "0");
      }
      return "$sign${digits.substring(0, offset + 1)}"
          ".${digits.substring(offset + 1)}";
    }
    return digits;
  }

  /// [isNumeric] checks if a string is a number
  static bool? isNumeric(String? s) {
    if (s == null) {
      return false;
    }
    return num.tryParse(s) != null;
  }

  /// [getCurrencyColor] is a generic function that applys colors based on the
  /// sign of a passed value
  static Color? getCurrencyColor(num? value, Color bgColor) {
    /// determine background color luminance
    double lum = bgColor.computeLuminance();

    /// return values based on bg luminance
    if (value == null) {
      return Colors.grey;
    } else if (value >= 0) {
      return lum > 0.5 ? Colors.green : Colors.green[300];
    } else {
      return lum > 0.5 ? Colors.red : Colors.red[300];
    }
  }
}
