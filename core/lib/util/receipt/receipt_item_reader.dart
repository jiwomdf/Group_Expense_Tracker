import 'package:core/domain/model/receipt_row.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_amount.dart';
import 'package:core/util/receipt/receipt_keywords.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';

/// Pulls the purchased lines out of a receipt, so one photo can become several
/// expenses instead of one lump sum.
class ReceiptItemReader {
  /// Guards against a misread page turning into hundreds of form rows.
  final int maxItems;

  /// How far left of the price column an amount may still sit and count as the
  /// line total, as a fraction of the page width.
  final double columnTolerance;

  const ReceiptItemReader({this.maxItems = 40, this.columnTolerance = 0.2});

  static final _leadingQuantity = RegExp(r'^\d+\s*[xX*@]?\s+(?=[A-Za-z])');
  static final _trailingFigures = RegExp(r'(?:\s*[\d.,]+[xX*@]?|\s+[xX*@])+$');
  static final _trailingPunctuation = RegExp(r'\s*[.:\-]+$');
  static final _quantityBefore = RegExp(r'(\d+)\s*[xX*@]\s*$');

  List<ReceiptLineItem> read(
    List<ReceiptRow> rows, {
    required ReceiptMoneyFormat money,
    int? total,
    ReceiptScanLog? log,
  }) {
    final candidates = [
      for (final row in rows) _RowReading(row, money),
    ];

    final column = _priceColumn(candidates);
    if (column != null) {
      log?.detail(
          'price column at x≈${column.toStringAsFixed(0)} of the page width');
    }

    final items = <ReceiptLineItem>[];
    String? pendingName;

    for (final candidate in candidates) {
      if (items.length >= maxItems) break;
      if (candidate.isExcluded) {
        pendingName = null;
        continue;
      }

      if (candidate.amounts.isEmpty) {
        pendingName = _describe(candidate.text, candidate.text.length);
        continue;
      }

      final carried = pendingName;
      pendingName = null;

      final priced = candidate.priceToken(column, columnTolerance);
      if (priced == null) continue;

      // A name printed on its own row above its figures is common on café and
      // warung printers. Only a row that reads as quantities may claim it: a
      // lone stranded amount cannot be attributed to anything with confidence.
      final note = _describe(candidate.text, priced.start) ??
          (candidate.isQuantityLine ? carried : null);
      if (note == null) continue;

      final price = candidate.lineTotalOf(priced);
      if (total != null && price > total) continue;

      items.add(ReceiptLineItem(note: note, price: price));
    }

    return _reconcile(items, total, log);
  }

  /// The receipt's price column, as the median start of each row's rightmost
  /// amount. Null when no row carried geometry.
  double? _priceColumn(List<_RowReading> rows) {
    final starts = <double>[];
    var pageWidth = 0.0;

    for (final row in rows) {
      if (!row.row.hasGeometry || row.isExcluded) continue;
      pageWidth = pageWidth > row.row.right ? pageWidth : row.row.right;

      final last = row.amounts.isEmpty ? null : row.amounts.last;
      final x = last == null ? null : row.row.xOfCharIndex(last.start);
      if (x != null) starts.add(x);
    }

    if (starts.isEmpty || pageWidth <= 0) return null;

    starts.sort();
    return starts[starts.length ~/ 2] / pageWidth;
  }

  /// Drops the rows that make the lines overshoot the printed total, but only
  /// when removing one or two of them reconciles it exactly — anything less
  /// certain is left for the user to judge.
  List<ReceiptLineItem> _reconcile(
      List<ReceiptLineItem> items, int? total, ReceiptScanLog? log) {
    if (total == null || items.isEmpty) return items;

    final sum = items.fold(0, (value, item) => value + item.price);
    final excess = sum - total;
    if (excess <= 0) return items;

    for (var i = 0; i < items.length; i++) {
      if (items[i].price == excess) {
        log?.detail('dropped "${items[i].note}", double counted');
        return [...items]..removeAt(i);
      }

      for (var j = i + 1; j < items.length; j++) {
        if (items[i].price + items[j].price != excess) continue;
        log?.detail('dropped "${items[i].note}" and "${items[j].note}", '
            'double counted');
        return [
          for (var k = 0; k < items.length; k++)
            if (k != i && k != j) items[k]
        ];
      }
    }

    log?.detail('lines overshoot the total by Rp $excess, kept as read');
    return items;
  }

  /// The name is the text left of the price, minus quantities, unit prices and
  /// trailing punctuation.
  String? _describe(String row, int priceStart) {
    var description = row.substring(0, priceStart).trim();
    description = description.replaceFirst(_leadingQuantity, '');
    description = description.replaceFirst(_trailingFigures, '');
    description = description.replaceFirst(_trailingPunctuation, '').trim();

    final letters = description.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    return letters < 3 ? null : description;
  }
}

/// One row prepared for item reading: normalised text and its usable amounts.
class _RowReading {
  final ReceiptRow row;
  final String text;
  final ReceiptMoneyFormat money;
  final List<_Amount> amounts;

  _RowReading._(this.row, this.text, this.money, this.amounts);

  factory _RowReading(ReceiptRow row, ReceiptMoneyFormat money) {
    final text = ReceiptAmount.normalizeDigits(row.text);
    final amounts = <_Amount>[];

    for (final match in ReceiptAmount.pattern.allMatches(text)) {
      final token = match.group(1);
      if (token == null || !ReceiptAmount.isPlausibleToken(token)) continue;

      final value = money.toRupiah(token);
      if (value == null || value < ReceiptAmount.minPlausible) continue;

      amounts.add(_Amount(start: match.start, value: value));
    }

    return _RowReading._(row, text, money, amounts);
  }

  /// A row of figures belonging to the name printed above it, e.g.
  /// `2 x 15.000 30.000`.
  bool get isQuantityLine =>
      amounts.length > 1 || RegExp(r'^\s*\d+\s*[xX*@]').hasMatch(text);

  bool get isExcluded {
    final lower = text.toLowerCase();
    return ReceiptKeywords.itemExclusions.any(lower.contains);
  }

  /// The amount that is the line total: the rightmost one sitting in the price
  /// column, or simply the rightmost when the page had no geometry.
  _Amount? priceToken(double? column, double tolerance) {
    if (amounts.isEmpty) return null;
    if (column == null || !row.hasGeometry) return amounts.last;

    final pageWidth = row.right;
    if (pageWidth <= 0) return amounts.last;

    for (var i = amounts.length - 1; i >= 0; i--) {
      final x = row.xOfCharIndex(amounts[i].start);
      if (x == null) continue;
      if (x / pageWidth >= column - tolerance) return amounts[i];
    }

    return null;
  }

  /// `2 x 15.000` with no third figure prints the unit price, so the line total
  /// has to be multiplied back out.
  int lineTotalOf(_Amount amount) {
    if (amounts.length > 1) return amount.value;

    final quantity = ReceiptItemReader._quantityBefore
        .firstMatch(text.substring(0, amount.start));
    final count = int.tryParse(quantity?.group(1) ?? '');

    return count == null || count < 2 ? amount.value : amount.value * count;
  }
}

class _Amount {
  final int start;
  final int value;

  const _Amount({required this.start, required this.value});
}
