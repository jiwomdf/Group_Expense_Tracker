class ExpenseConstants {
  static const constantName = "expense";

  static const String id = "id"; //Primary Key
  static const String date = "date";
  static const String email = "email";
  static const String note = "note";
  static const String price = "price";
  static const String subCategoryId = "subCategoryId"; //Foreign Key
  static const String categoryId = "categoryId"; //Foreign Key
  static const String year = "year";
  static const String month = "month";
  static const String dayOfMonth = "dayOfMonth";
  static const String timeStamp = "timeStamp";
  static const String status = "status";
}

class CategoryConstants {
  static const constantName = "category";

  static const String categoryId = "categoryId"; //Primary Key
  static const String categoryName = "categoryName";
  static const String categoryColor = "categoryColor";
  static const String email = "email";
}

class SubCategoryConstants {
  static const constantName = "subCategory";

  static const String subCategoryId = "subCategoryId"; //Primary Key
  static const String subCategoryName = "subCategoryName";
  static const String subCategoryColor = "subCategoryColor";
  static const String email = "email";
}

class UserConstants {
  static const constantName = "auth";

  static const String mail = "email"; //Primary Key
  static const String ame = "name";
}
