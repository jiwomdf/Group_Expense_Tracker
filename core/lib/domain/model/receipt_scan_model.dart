/// One purchased line off a receipt.
class ReceiptLineItem {
  /// Item description, used as the expense note.
  final String note;

  /// Line total in whole rupiah.
  final int price;

  const ReceiptLineItem({required this.note, required this.price});
}

/// The result of running OCR over a receipt photo and parsing it.
///
/// Every field is a best guess, so the user always confirms it in the expense
/// form before anything is saved.
class ReceiptScanModel {
  /// Merchant name. Used as the note when the receipt is saved as a single
  /// expense. Empty when not found.
  final String note;

  /// Total amount in whole rupiah. Null when no total could be identified.
  final int? price;

  /// Transaction date printed on the receipt. Null when not found.
  final DateTime? date;

  /// Individual purchased lines, when the receipt lists them legibly. Empty
  /// when only a total could be made out, in which case the form falls back to
  /// a single row.
  final List<ReceiptLineItem> items;

  /// Full OCR output, kept so the user can check what the scanner actually read.
  final String rawText;

  /// Stage-by-stage trace of how this result was reached, from the photo to the
  /// chosen total. Shown on the review screen for diagnosing a bad scan.
  final List<String> log;

  const ReceiptScanModel({
    required this.note,
    required this.price,
    required this.date,
    required this.items,
    required this.rawText,
    this.log = const [],
  });

  /// True when nothing useful was extracted, so the UI can say "scan failed"
  /// instead of opening an empty form.
  bool get isEmpty => note.isEmpty && price == null && items.isEmpty;

  /// Sum of the parsed lines, for comparing against [price].
  int get itemsTotal => items.fold(0, (sum, item) => sum + item.price);

  ReceiptScanModel copyWith({
    String? note,
    int? price,
    DateTime? date,
    List<ReceiptLineItem>? items,
  }) =>
      ReceiptScanModel(
        note: note ?? this.note,
        price: price ?? this.price,
        date: date ?? this.date,
        items: items ?? this.items,
        rawText: rawText,
        log: log,
      );

  /// The same scan reduced to its total, with the line items and the merchant
  /// name dropped.
  ///
  /// Used when the user chooses to book the receipt as a single unnamed
  /// expense: the name is left empty so the form asks them for one instead of
  /// pre-filling a merchant they did not ask for.
  ReceiptScanModel get totalOnly => ReceiptScanModel(
        note: "",
        price: price ?? (items.isEmpty ? null : itemsTotal),
        date: date,
        items: const [],
        rawText: rawText,
        log: log,
      );

  /// True when the parsed lines add up to the printed total, which means the
  /// item list is very likely complete and correct.
  ///
  /// Receipts routinely add tax or subtract a discount after the line items, so
  /// an exact match is strong evidence rather than a requirement.
  bool get itemsMatchTotal =>
      items.isNotEmpty && price != null && itemsTotal == price;
}
