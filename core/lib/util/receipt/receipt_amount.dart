/// Reading money off a receipt line.
///
/// Amounts are whole rupiah, matching `ExpenseModel.price` being an `int`.
class ReceiptAmount {
  const ReceiptAmount._();

  /// A rupiah amount: digits with optional `.` or `,` groupings, optionally
  /// prefixed by `Rp`.
  static final pattern = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:[.,\s]\d{3})+|\d+(?:[.,]\d{1,2})?)',
      caseSensitive: false);

  /// The smallest amount treated as real money. Mirrors the "greater than
  /// Rp 100" rule the expense form validates, so the parser never seeds a row
  /// the form would immediately reject.
  static const minPlausible = 100;

  /// Converts an OCR'd amount into whole rupiah.
  ///
  /// Indonesian receipts group thousands with `.` and write cents as `,00`, but
  /// plenty of printers do the opposite, so a trailing two-digit group after any
  /// separator is dropped as cents and every remaining separator is grouping.
  static int? toRupiah(String? raw) {
    if (raw == null) return null;

    var digits = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    digits = digits.replaceFirst(RegExp(r'[.,]\d{2}$'), '');
    digits = digits.replaceAll(RegExp(r'[.,]'), '');

    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// True when the token is punctuated like money rather than being a bare run
  /// of digits. Postcodes, phone numbers and invoice ids are bare; prices are
  /// practically always written `150.000` or `154.06`.
  static bool looksLikeMoney(String token) => token.contains(RegExp(r'[.,]'));

  /// The rightmost amount on a line, which on an item row is the line total
  /// rather than the unit price.
  static int? lastIn(String line) {
    final matches = pattern.allMatches(line).toList();

    for (var i = matches.length - 1; i >= 0; i--) {
      final amount = toRupiah(matches[i].group(1));
      if (amount != null && amount >= minPlausible) return amount;
    }
    return null;
  }
}
