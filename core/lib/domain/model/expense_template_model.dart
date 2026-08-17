/// A saved expense the user enters over and over, kept so the form can be
/// filled from a list instead of typed out again every day.
///
/// It carries the same fields an expense row needs except the date, which is
/// always "now" at the moment the template is used.
class ExpenseTemplateModel {
  /// Local id, generated when the template is created. Templates never reach
  /// firestore, so this is unrelated to any expense id.
  final String id;

  /// Expense name, used as the note of the row it fills.
  final String note;

  /// Amount in whole rupiah. `0` means the template only pre-picks the name and
  /// category, and the user types the price each time.
  final int price;

  final String categoryId;
  final String categoryName;
  final int categoryColor;

  final String subCategoryId;
  final String subCategoryName;
  final int subCategoryColor;

  const ExpenseTemplateModel({
    required this.id,
    required this.note,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.subCategoryColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'note': note,
        'price': price,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryColor': categoryColor,
        'subCategoryId': subCategoryId,
        'subCategoryName': subCategoryName,
        'subCategoryColor': subCategoryColor,
      };

  /// Every field falls back to a default: a template written by an older build
  /// should still load rather than take the whole list down with it.
  factory ExpenseTemplateModel.fromMap(Map<String, dynamic> map) =>
      ExpenseTemplateModel(
        id: map['id']?.toString() ?? '',
        note: map['note']?.toString() ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        categoryId: map['categoryId']?.toString() ?? '',
        categoryName: map['categoryName']?.toString() ?? '',
        categoryColor: (map['categoryColor'] as num?)?.toInt() ?? 0xff443a49,
        subCategoryId: map['subCategoryId']?.toString() ?? '',
        subCategoryName: map['subCategoryName']?.toString() ?? '',
        subCategoryColor:
            (map['subCategoryColor'] as num?)?.toInt() ?? 0xff443a49,
      );

  ExpenseTemplateModel copyWith({
    String? id,
    String? note,
    int? price,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    String? subCategoryId,
    String? subCategoryName,
    int? subCategoryColor,
  }) =>
      ExpenseTemplateModel(
        id: id ?? this.id,
        note: note ?? this.note,
        price: price ?? this.price,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        categoryColor: categoryColor ?? this.categoryColor,
        subCategoryId: subCategoryId ?? this.subCategoryId,
        subCategoryName: subCategoryName ?? this.subCategoryName,
        subCategoryColor: subCategoryColor ?? this.subCategoryColor,
      );
}
