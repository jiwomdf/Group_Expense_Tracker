import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatUtil {
  static const ddSlashMMSlashyyyy = "dd/MM/yyyy";
  static const ddMMMyyyy = "dd MMM yyyy";
  static const ddMMMMyyyy = "dd MMMM yyyy";
  static const yyyyDashMMDashDD = "yyyy-MM-dd";

  static const listFormat = [
    ddSlashMMSlashyyyy,
    ddMMMyyyy,
    ddMMMMyyyy,
    yyyyDashMMDashDD
  ];
}

extension DateTimeStringExtension on String {
  DateTime? toDateGlobalFormat() {
    for (var element in DateFormatUtil.listFormat) {
      try {
        return DateFormat(element).parse(this);
      } catch (ex) {
        debugPrint("toDateGlobalFormat $ex");
      }
    }
    return null;
  }
}

extension DateTimeExtension on DateTime {
  String? toDateString(String format) {
    try {
      return DateFormat(format).format(this);
    } catch (ex) {
      return null;
    }
  }
}
