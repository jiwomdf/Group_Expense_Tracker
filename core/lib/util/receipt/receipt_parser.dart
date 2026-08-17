import 'package:core/domain/model/receipt_scan_model.dart';

/// Turns the raw text an OCR engine reads off a receipt into a
/// [ReceiptScanModel].
///
/// This is deliberately plain Dart with no plugin dependency: the OCR engine is
/// mobile only, but the parsing rules are the part worth unit testing.
///
/// Amounts are treated as whole rupiah, matching `ExpenseModel.price` being an
/// `int`.
class ReceiptParser {
  const ReceiptParser();

  /// Labels that mark the real total, most specific first. The first group that
  /// matches anywhere on the receipt wins, so `grand total` beats a bare
  /// `total`, and cash-tendered lines are only used as a last resort because
  /// the customer often pays more than the total.
  static const _totalKeywordTiers = <List<String>>[
    [
      'grand total',
      'total akhir',
      'total belanja',
      'total bayar',
      'receipt total',
      'total due',
      'balance due',
    ],
    ['total'],
    // Deliberately no bare 'amount': on printed invoices that matches the
    // AMOUNT column header and picks up the first line item instead.
    ['jumlah', 'amount due'],
    ['tunai', 'cash', 'bayar', 'debit', 'kredit', 'card'],
  ];

  /// Lines that contain a total-ish word but never the amount we want.
  /// `subtotal` sits above the total, and `total item`/`total qty` count goods
  /// rather than money.
  static const _totalExclusions = <String>[
    'sub total',
    'subtotal',
    'sub-total',
    'total item',
    'total qty',
    'total barang',
    'total diskon',
    'total discount',
    'ppn',
    'pajak',
    'tax',
    'kembali',
    'kembalian',
    'change',
    'save',
    'hemat',
    // Column headers on printed invoices, where the figures below them are line
    // items rather than the total.
    'unit price',
    'description',
    'qty',
  ];

  /// Words that mean a top-of-receipt line is address or registration detail
  /// rather than the merchant name.
  static const _merchantExclusions = <String>[
    'jl.',
    'jl ',
    'jalan',
    'telp',
    'tel.',
    'phone',
    'npwp',
    'no.',
    'kasir',
    'cashier',
    'struk',
    'receipt',
    'invoice',
    'nota',
    'faktur',
    'tanggal',
    'date',
    'www.',
    'http',
    '.com',
  ];

  static const _monthNames = <String, int>{
    'jan': 1,
    'feb': 2,
    'peb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'mei': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'agu': 8,
    'ags': 8,
    'sep': 9,
    'oct': 10,
    'okt': 10,
    'nov': 11,
    'dec': 12,
    'des': 12,
  };

  /// A rupiah amount: digits with optional `.` or `,` groupings, optionally
  /// prefixed by `Rp`.
  static final _amountPattern = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:[.,\s]\d{3})+|\d+(?:[.,]\d{1,2})?)',
      caseSensitive: false);

  static final _numericDatePattern =
      RegExp(r'(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{2,4})');

  static final _textualDatePattern = RegExp(
      r'(\d{1,2})[\s\-/]*([a-z]{3,9})[\s\-/]*(\d{2,4})',
      caseSensitive: false);

  /// The smallest amount treated as a plausible total. Mirrors the
  /// "greater than Rp 100" rule the expense form already validates.
  static const _minPlausibleTotal = 100;

  /// Guards against a misread page turning into hundreds of form rows.
  static const _maxLineItems = 40;

  /// A quantity opening a line item, as in `2 New set of pedal arms` or
  /// `2x Kopi`. Requires a letter after it, so a bare code like `1234567 9.000`
  /// is left alone.
  static final _leadingQuantity = RegExp(r'^\d+\s*[xX*]?\s+(?=[A-Za-z])');

  /// Lines that carry an amount but are not a purchased item: the summary block,
  /// column headers, and receipt metadata.
  static const _itemExclusions = <String>[
    'total',
    'jumlah',
    'tunai',
    'cash',
    'bayar',
    'debit',
    'kredit',
    'card',
    'amount due',
    'balance due',
    'ppn',
    'pajak',
    'tax',
    'kembali',
    'change',
    'save',
    'hemat',
    'diskon',
    'discount',
    'unit price',
    'description',
    'qty',
    'harga',
    'npwp',
    'telp',
    'kasir',
    'cashier',
    'struk',
    'invoice',
    'faktur',
    'tanggal',
    'date',
    'jl.',
    'jalan',
  ];

  ReceiptScanModel parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ReceiptScanModel(
      note: _findMerchant(lines),
      price: _findTotal(lines),
      date: _findDate(lines),
      items: _findLineItems(lines),
      rawText: rawText,
    );
  }

  /// Pulls out the purchased lines, so a receipt can become several expenses
  /// instead of one lump sum.
  ///
  /// A line qualifies only when it holds a description *and* its own amount on
  /// the same line. Amounts stranded on their own line by a two-column layout
  /// are skipped: pairing them back to a description by position is guesswork,
  /// and a wrong pairing is worse than no row at all.
  List<ReceiptLineItem> _findLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];

    for (final line in lines) {
      if (items.length >= _maxLineItems) break;

      final lower = line.toLowerCase();
      if (_itemExclusions.any(lower.contains)) continue;

      // A leading quantity is dropped first. Left in place it would be read as
      // the line's own first amount, so `2 New set of pedal arms 15.00 30.00`
      // would end up with an empty description.
      final item = line.replaceFirst(_leadingQuantity, '');

      final matches = _amountPattern.allMatches(item).toList();
      if (matches.isEmpty) continue;

      // The rightmost figure is the line total; anything before it is a unit
      // price or quantity.
      final token = matches.last.group(1);
      final price = _toRupiah(token);
      if (price == null || price <= 0) continue;

      // Held to the same Rp 100 floor the expense form validates against.
      // Seeding a row the form immediately rejects just hands the user an error
      // to clear, so such a line is left out and the total still covers it.
      if (price < _minPlausibleTotal) continue;

      final note = _describeItem(item, matches.first.start);
      if (note.isEmpty) continue;

      items.add(ReceiptLineItem(note: note, price: price));
    }

    return items;
  }

  /// The description is the text before the first figure, minus any leading
  /// quantity such as the `2` in `2 New set of pedal arms 15.00 30.00`.
  String _describeItem(String line, int firstAmountStart) {
    var description = line.substring(0, firstAmountStart).trim();
    description = description.replaceFirst(RegExp(r'^\d+\s*[xX*]?\s*'), '');
    description = description.replaceAll(RegExp(r'\s*[.:\-]+$'), '').trim();

    // Needs real words, otherwise it is leftover punctuation or a code.
    final letters = description.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letters < 3) return '';

    return description;
  }

  /// Walks the keyword tiers in order and, within a tier, prefers the lowest
  /// line on the receipt — the total is printed below the item list.
  int? _findTotal(List<String> lines) {
    for (final tier in _totalKeywordTiers) {
      for (var i = lines.length - 1; i >= 0; i--) {
        final lower = lines[i].toLowerCase();

        if (!tier.any(lower.contains)) continue;
        if (_totalExclusions.any(lower.contains)) continue;

        // The amount is usually on the label's line, but a two-column layout
        // can push it onto the next one.
        final amount = _lastAmountIn(lines[i]) ??
            (i + 1 < lines.length ? _lastAmountIn(lines[i + 1]) : null);

        if (amount != null && amount >= _minPlausibleTotal) return amount;
      }
    }

    return _largestAmountIn(lines);
  }

  /// Last-resort guess: the biggest amount on the receipt. On most receipts the
  /// total is the largest figure, and the user confirms it either way.
  ///
  /// Only tokens punctuated like money count. Without that rule bare digit runs
  /// win, and a postcode, phone number or invoice id is often the largest number
  /// printed — while real prices are practically always written with a grouping
  /// or decimal separator (`150.000`, `154.06`).
  int? _largestAmountIn(List<String> lines) {
    int? largest;

    for (final line in lines) {
      if (_totalExclusions.any(line.toLowerCase().contains)) continue;

      for (final match in _amountPattern.allMatches(line)) {
        final token = match.group(1);
        if (token == null || !token.contains(RegExp(r'[.,]'))) continue;

        final amount = _toRupiah(token);
        if (amount == null || amount < _minPlausibleTotal) continue;
        if (largest == null || amount > largest) largest = amount;
      }
    }

    return largest;
  }

  int? _lastAmountIn(String line) {
    final matches = _amountPattern.allMatches(line).toList();

    for (var i = matches.length - 1; i >= 0; i--) {
      final amount = _toRupiah(matches[i].group(1));
      if (amount != null && amount >= _minPlausibleTotal) return amount;
    }
    return null;
  }

  /// Converts an OCR'd amount into whole rupiah.
  ///
  /// Indonesian receipts group thousands with `.` and write cents as `,00`, but
  /// plenty of printers do the opposite, so a trailing two-digit group after any
  /// separator is dropped as cents and every remaining separator is grouping.
  int? _toRupiah(String? raw) {
    if (raw == null) return null;

    var digits = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    digits = digits.replaceFirst(RegExp(r'[.,]\d{2}$'), '');
    digits = digits.replaceAll(RegExp(r'[.,]'), '');

    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// The merchant name is nearly always in the first few lines, above the
  /// address block.
  String _findMerchant(List<String> lines) {
    for (final line in lines.take(5)) {
      final lower = line.toLowerCase();

      if (line.length < 3) continue;
      if (_merchantExclusions.any(lower.contains)) continue;

      final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      // Mostly-letters rules out barcodes, phone numbers and separator rows.
      if (letters < 3 || letters / line.length < 0.5) continue;

      return line;
    }

    return '';
  }

  DateTime? _findDate(List<String> lines) {
    for (final line in lines) {
      final numeric = _numericDatePattern.firstMatch(line);
      if (numeric != null) {
        final date = _fromNumericMatch(numeric);
        if (date != null) return date;
      }

      final textual = _textualDatePattern.firstMatch(line);
      if (textual != null) {
        final month = _monthNames[textual.group(2)!.toLowerCase().substring(
              0,
              3,
            )];
        if (month != null) {
          final date = _buildDate(
            int.parse(textual.group(1)!),
            month,
            int.parse(textual.group(3)!),
          );
          if (date != null) return date;
        }
      }
    }

    return null;
  }

  /// Handles both `dd/mm/yyyy` (the Indonesian norm) and `yyyy-mm-dd`.
  DateTime? _fromNumericMatch(RegExpMatch match) {
    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    final third = int.parse(match.group(3)!);

    if (match.group(1)!.length == 4) {
      return _buildDate(third, second, first);
    }
    return _buildDate(first, second, third);
  }

  /// Rejects impossible or implausible dates so a stray serial number cannot
  /// masquerade as the transaction date.
  DateTime? _buildDate(int day, int month, int year) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    if (year < 100) year += 2000;
    if (year < 2000) return null;

    final date = DateTime(year, month, day);

    // Guard against overflow, e.g. 31/02 silently becoming 02/03.
    if (date.day != day || date.month != month) return null;
    // A receipt cannot be from the future, allowing a day for timezone skew.
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;

    return date;
  }
}
