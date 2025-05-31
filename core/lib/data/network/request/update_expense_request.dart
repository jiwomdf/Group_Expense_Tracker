import 'package:core/util/extension/string_util.dart';
import 'package:core/util/firestore_constants.dart';

class UpdateExpenseRequest {
  final String id;
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

  UpdateExpenseRequest({
    required this.id,
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
