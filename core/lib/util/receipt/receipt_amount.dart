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

  /// A run that is money apart from characters the OCR engine confuses with
  /// digits, e.g. `1S.OOO`.
  static final _confusable = RegExp(r'\b(?=[\dOoSsBbIl]*\d)[\dOoSsBbIl]{1,3}'
      r'(?:[.,][\dOoSsBbIl]{2,3})+\b');

  static const _confusedDigits = {
    'O': '0',
    'o': '0',
    'S': '5',
    's': '5',
    'B': '8',
    'b': '8',
    'I': '1',
    'l': '1',
  };

  /// The smallest amount treated as real money. Mirrors the "greater than
  /// Rp 100" rule the expense form validates, so the parser never seeds a row
  /// the form would immediately reject.
  static const minPlausible = 100;

  /// Longest unpunctuated run still read as a price. Beyond this it is a
  /// barcode, a member id or a phone number rather than money.
  static const maxBareDigits = 7;

  /// Rewrites letters the engine mistook for digits, inside money-shaped runs
  /// only, so item names keep their spelling.
  static String normalizeDigits(String line) =>
      line.replaceAllMapped(_confusable, (match) {
        final token = match.group(0)!;
        return token.split('').map((c) => _confusedDigits[c] ?? c).join();
      });

  /// True when the token is punctuated like money rather than being a bare run
  /// of digits. Postcodes, phone numbers and invoice ids are bare; prices are
  /// practically always written `150.000` or `154.06`.
  static bool looksLikeMoney(String token) => token.contains(RegExp(r'[.,]'));

  /// True when the token could be a price at all, before its value is read.
  static bool isPlausibleToken(String token) =>
      looksLikeMoney(token) ||
      token.replaceAll(RegExp(r'\D'), '').length <= maxBareDigits;

  /// Converts an OCR'd amount into whole rupiah, treating every separator as
  /// thousands grouping. Prefer [ReceiptMoneyFormat.toRupiah], which knows
  /// whether the receipt at hand prints cents.
  static int? toRupiah(String? raw) => ReceiptMoneyFormat.cents.toRupiah(raw);

  /// The rightmost amount on a line, which on an item row is the line total
  /// rather than the unit price.
  static int? lastIn(String line, {ReceiptMoneyFormat? money}) {
    final format = money ?? ReceiptMoneyFormat.cents;
    final matches = pattern.allMatches(line).toList();

    for (var i = matches.length - 1; i >= 0; i--) {
      final amount = format.toRupiah(matches[i].group(1));
      if (amount != null && amount >= minPlausible) return amount;
    }
    return null;
  }
}

/// How one receipt writes its amounts.
///
/// Indonesian receipts group thousands with `.` and rarely print cents, while
/// invoices in other currencies always do, and the same token `15.00` means
/// fifteen on one and fifteen thousand on the other. Deciding once per receipt
/// beats guessing per token.
class ReceiptMoneyFormat {
  /// Trailing two digits after a separator are cents and are dropped.
  static const cents = ReceiptMoneyFormat._(usesCents: true);

  /// Every separator is thousands grouping.
  static const whole = ReceiptMoneyFormat._(usesCents: false);

  final bool usesCents;

  const ReceiptMoneyFormat._({required this.usesCents});

  /// A token whose decimal separator is unambiguous because grouping precedes
  /// it, e.g. `1,234.56` or `2.500,00`.
  static final _unambiguousCents =
      RegExp(r'\d[.,]\d{3}(?:[.,]\d{3})*[.,]\d{2}\b');

  static final _twoDecimals = RegExp(r'\d[.,]\d{2}\b');
  static final _grouped = RegExp(r'\d[.,]\d{3}\b');

  /// Reads the convention off the whole receipt: cents only when the receipt
  /// shows them unambiguously, or when no amount on it is grouped in thousands.
  factory ReceiptMoneyFormat.detect(Iterable<String> rows) {
    var twoDecimals = 0;
    var grouped = 0;

    for (final row in rows) {
      if (_unambiguousCents.hasMatch(row)) return cents;
      twoDecimals += _twoDecimals.allMatches(row).length;
      grouped += _grouped.allMatches(row).length;
    }

    return grouped == 0 && twoDecimals > 0 ? cents : whole;
  }

  /// Converts an OCR'd amount into whole rupiah.
  int? toRupiah(String? raw) {
    if (raw == null) return null;

    var digits = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (usesCents) digits = digits.replaceFirst(RegExp(r'[.,]\d{2}$'), '');
    digits = digits.replaceAll(RegExp(r'[.,]'), '');

    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }
}
