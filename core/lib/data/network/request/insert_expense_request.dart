import 'package:core/util/extension/date_format_util.dart';
import 'package:core/util/extension/string_util.dart';
import 'package:core/util/firestore_constants.dart';

class InsertExpenseRequest {
  String? email;
  final String note;
  final int price;
  final String date;
  final String categoryId;
  final String subCategoryId;
  final String year;
  final String month;
  final String dayOfMonth;
  final String timeStamp;
  final String status;

  InsertExpenseRequest({
    this.email,
    required this.note,
    required this.price,
    required this.date,
    required this.categoryId,
    required this.subCategoryId,
    required this.year,
    required this.month,
    required this.dayOfMonth,
    required this.timeStamp,
    required this.status,
  });

  factory InsertExpenseRequest.fromJson(Map<String, dynamic> json) =>
      InsertExpenseRequest(
        email: (json[ExpenseConstants.email] ?? "").toString().toInputFormat(),
        note: (json[ExpenseConstants.note] ?? "").toString().toInputFormat(),
        price: int.parse(json[ExpenseConstants.price] ?? 0),
        date: (json[ExpenseConstants.date] ??
                DateTime.now().toDateString(DateFormatUtil.ddMMMyyyy) ??
                "")
            .toString()
            .toInputFormat(),
        categoryId: (json[ExpenseConstants.categoryId] ?? "").toString(),
        subCategoryId: (json[ExpenseConstants.subCategoryId] ?? "").toString(),
        year: (json[ExpenseConstants.year] ?? "").toString().toInputFormat(),
        month: (json[ExpenseConstants.month] ?? "").toString().toInputFormat(),
        dayOfMonth: (json[ExpenseConstants.dayOfMonth] ?? "")
            .toString()
            .toInputFormat(),
        timeStamp:
            (json[ExpenseConstants.timeStamp] ?? "").toString().toInputFormat(),
        status:
            (json[ExpenseConstants.status] ?? "").toString().toInputFormat(),
      );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[ExpenseConstants.email] = email;
    data[ExpenseConstants.note] = note;
    data[ExpenseConstants.price] = price;
    data[ExpenseConstants.date] = date;
    data[ExpenseConstants.categoryId] = categoryId;
    data[ExpenseConstants.subCategoryId] = subCategoryId;
    data[ExpenseConstants.year] = year;
    data[ExpenseConstants.month] = month.addZeroPref();
    data[ExpenseConstants.dayOfMonth] = dayOfMonth.addZeroPref();
    data[ExpenseConstants.timeStamp] = timeStamp;
    data[ExpenseConstants.status] = status;
    return data;
  }
}
