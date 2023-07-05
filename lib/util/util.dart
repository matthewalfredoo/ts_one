import 'package:intl/intl.dart';

class Util{
  static String convertDateTimeDisplay(String date, [String format = "dd-MMMM-yyyy"]) {
    final DateFormat displayFormater = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final DateFormat serverFormater = DateFormat(format);
    final DateTime displayDate = displayFormater.parse(date);
    final String formatted = serverFormater.format(displayDate);
    return formatted;
  }

  // this is used to set the default date if the date is null
  static DateTime defaultDateIfNull = DateTime(1999, 9, 9, 9, 9, 9, 9, 9);

  // this is used to set the default string if the string is null
  static String defaultStringIfNull = "";

  // this is used to set the default int if the int is null
  static int defaultIntIfNull = 0;
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}