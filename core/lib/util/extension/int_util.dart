import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension IntUtil on int {
  String? toRupiah() {
    var formatter = NumberFormat('##,###,###.##', 'en_US');
    return formatter.format(this);
  }

  Color toColor() {
    try {
      return Color(this);
    } catch (ex) {
      return const Color(0xFF4f378b);
    }
  }

  String addZeroPref() {
    var strLength = toString().length;
    if (strLength < 2) {
      return "0$this";
    } else {
      return "$this";
    }
  }

  String removeZeroPref() {
    var strLength = toString().length;
    if (strLength > 1 && toString().split('')[0] == '0') {
      return "${toString().split('').sublist(1)}";
    }

    return "$this";
  }
}
