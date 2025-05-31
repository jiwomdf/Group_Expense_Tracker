import 'package:core/util/extension/string_util.dart';
import 'package:core/util/firestore_constants.dart';

class ExpenseCategoryModel {
  final String id;
  final String email;
  final String note;
  final int price;
  final String date;
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final String subCategoryId;
  final String subCategoryName;
  final int subCategoryColor;
  final String year;
  final String month;
  final String dayOfMonth;
  final String timeStamp;
  final String status;

  ExpenseCategoryModel({
    required this.id,
    required this.email,
    required this.note,
    required this.price,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.subCategoryColor,
    required this.year,
    required this.month,
    required this.dayOfMonth,
    required this.timeStamp,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[ExpenseConstants.id] = id;
    data[ExpenseConstants.email] = email;
    data[ExpenseConstants.note] = note;
    data[ExpenseConstants.price] = price;
    data[ExpenseConstants.date] = date;
    data[ExpenseConstants.categoryId] = categoryId;
    data[CategoryConstants.categoryName] = categoryName;
    data[CategoryConstants.categoryColor] = categoryColor;
    data[ExpenseConstants.subCategoryId] = subCategoryId;
    data[SubCategoryConstants.subCategoryName] = subCategoryName;
    data[SubCategoryConstants.subCategoryColor] = subCategoryColor;
    data[ExpenseConstants.year] = year;
    data[ExpenseConstants.month] = month.addZeroPref();
    data[ExpenseConstants.dayOfMonth] = dayOfMonth.addZeroPref();
    data[ExpenseConstants.timeStamp] = timeStamp;
    data[ExpenseConstants.status] = status;
    return data;
  }
}
