import 'package:dbus/dbus.dart';

class DBusParsers {
  static int? tryParseUint64(DBusValue? value) {
    if (value == null) return null;
    try {
      return value.asUint64();
    } on FormatException {
      return null;
    }
  }

  static DateTime? parseTimestamp(DBusValue? value) {
    if (value == null) return null;
    try {
      final microseconds = value.asUint64();
      if (microseconds == 0) return null;
      return DateTime.fromMicrosecondsSinceEpoch(microseconds);
    } on FormatException {
      return null;
    }
  }

  static List<String> parseStringList(DBusValue? value) {
    if (value == null) return [];
    try {
      return value.asStringArray().toList();
    } on FormatException {
      return [];
    }
  }
}
