import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_amount.dart';
import 'package:core/util/receipt/receipt_date_reader.dart';
import 'package:core/util/receipt/receipt_keywords.dart';
import 'package:core/util/receipt/receipt_line_grouper.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';

/// Turns the text an OCR engine reads off a receipt into a [ReceiptScanModel].
///
/// Plain Dart with no plugin dependency: the OCR engine is mobile only, but the
/// rules are the part worth unit testing.
///
/// The vocabulary lives in [ReceiptKeywords], money handling in [ReceiptAmount],
/// dates in [ReceiptDateReader], and layout in [ReceiptLineGrouper]. This file
/// is only the extraction rules that use them.
class ReceiptParser {
  final ReceiptLineGrouper _grouper;
  final ReceiptDateReader _dateReader;

  const ReceiptParser({
    ReceiptLineGrouper grouper = const ReceiptLineGrouper(),
    ReceiptDateReader dateReader = const ReceiptDateReader(),
  })  : _grouper = grouper,
        _dateReader = dateReader;

  /// Guards against a misread page turning into hundreds of form rows.
  static const _maxLineItems = 40;

  /// A quantity opening a line item, as in `2 New set of pedal arms` or
  /// `2x Kopi`. Requires a letter after it, so a bare code like `1234567 9.000`
  /// is left alone.
  static final _leadingQuantity = RegExp(r'^\d+\s*[xX*]?\s+(?=[A-Za-z])');

  /// Parses positioned OCR lines. Preferred over [parse]: knowing where text
  /// sat lets a label and its amount be put back on one row even when the
  /// engine reported them in separate blocks.
  ReceiptScanModel parseLines(List<ReceiptOcrLine> lines,
      {ReceiptScanLog? log}) {
    final rawText = lines.map((line) => line.text).join('\n');
    final rows = _grouper.group(lines);

    log?.stage('Group',
        '${lines.length} OCR lines merged into ${rows.length} printed rows');

    return _parseRows(rows, rawText, log);
  }

  /// Parses flattened OCR text, for callers with no geometry to offer.
  ReceiptScanModel parse(String rawText, {ReceiptScanLog? log}) {
    final rows = rawText
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    log?.stage('Rows', '${rows.length} text rows, no geometry available');

    return _parseRows(rows, rawText, log);
  }

  ReceiptScanModel _parseRows(
      List<String> rows, String rawText, ReceiptScanLog? log) {
    final note = _findMerchant(rows);
    log?.stage('Merchant', note.isEmpty ? 'not found' : '"$note"');

    final price = _findTotal(rows, log);

    final date = _dateReader.read(rows);
    log?.stage(
        'Date',
        date == null
            ? 'not printed, today will be used'
            : '${date.day}/${date.month}/${date.year}');

    final items = _findLineItems(rows);
    final itemsTotal = items.fold(0, (sum, item) => sum + item.price);
    log?.stage('Items', '${items.length} found, summing Rp $itemsTotal');
    if (items.isNotEmpty && price != null) {
      log?.detail(itemsTotal == price
          ? 'matches the total exactly'
          : 'differs from the total by Rp ${(price - itemsTotal).abs()}');
    }

    return ReceiptScanModel(
      note: note,
      price: price,
      date: date,
      items: items,
      rawText: rawText,
      log: log?.entries ?? const [],
    );
  }

  /// Walks the keyword tiers in order and, within a tier, prefers the lowest
  /// row on the receipt — the total is printed below the item list.
  int? _findTotal(List<String> rows, [ReceiptScanLog? log]) {
    for (var tierIndex = 0;
        tierIndex < ReceiptKeywords.totalTiers.length;
        tierIndex++) {
      final tier = ReceiptKeywords.totalTiers[tierIndex];

      for (var i = rows.length - 1; i >= 0; i--) {
        final lower = rows[i].toLowerCase();

        final keyword = tier.where(lower.contains).firstOrNull;
        if (keyword == null) continue;
        if (ReceiptKeywords.totalExclusions.any(lower.contains)) {
          log?.detail('skipped row $i "${rows[i]}" (excluded word)');
          continue;
        }

        // The amount is usually on the label's row, but a layout the grouper
        // could not reunite can push it onto the next one.
        final amount = ReceiptAmount.lastIn(rows[i]) ??
            (i + 1 < rows.length ? ReceiptAmount.lastIn(rows[i + 1]) : null);

        if (amount != null && amount >= ReceiptAmount.minPlausible) {
          log?.stage('Total', 'Rp $amount');
          log?.detail(
              'matched "$keyword" (tier ${tierIndex + 1}) in row $i: "${rows[i]}"');
          return amount;
        }
      }
    }

    final largest = _largestAmountIn(rows);
    log?.stage('Total', largest == null ? 'not found' : 'Rp $largest');
    log?.detail(largest == null
        ? 'no keyword matched and no money-shaped amount was present'
        : 'no keyword matched, fell back to the largest money-shaped amount');
    return largest;
  }

  /// Last-resort guess: the biggest amount on the receipt. On most receipts the
  /// total is the largest figure, and the user confirms it either way.
  ///
  /// Only tokens punctuated like money count, or a postcode or phone number
  /// wins instead.
  int? _largestAmountIn(List<String> rows) {
    int? largest;

    for (final row in rows) {
      if (ReceiptKeywords.totalExclusions.any(row.toLowerCase().contains)) {
        continue;
      }

      for (final match in ReceiptAmount.pattern.allMatches(row)) {
        final token = match.group(1);
        if (token == null || !ReceiptAmount.looksLikeMoney(token)) continue;

        final amount = ReceiptAmount.toRupiah(token);
        if (amount == null || amount < ReceiptAmount.minPlausible) continue;
        if (largest == null || amount > largest) largest = amount;
      }
    }

    return largest;
  }

  /// Pulls out the purchased lines, so a receipt can become several expenses
  /// instead of one lump sum.
  ///
  /// A row qualifies only when it holds a description *and* an amount. With
  /// geometry the grouper will already have reunited a description with the
  /// amount printed opposite it; without it, such a pair stays unusable.
  List<ReceiptLineItem> _findLineItems(List<String> rows) {
    final items = <ReceiptLineItem>[];

    for (final row in rows) {
      if (items.length >= _maxLineItems) break;

      final lower = row.toLowerCase();
      if (ReceiptKeywords.itemExclusions.any(lower.contains)) continue;

      // A leading quantity is dropped first. Left in place it would be read as
      // the row's own first amount, so `2 New set of pedal arms 15.00 30.00`
      // would end up with an empty description.
      final item = row.replaceFirst(_leadingQuantity, '');

      final matches = ReceiptAmount.pattern.allMatches(item).toList();
      if (matches.isEmpty) continue;

      // The rightmost figure is the line total; anything before it is a unit
      // price or quantity.
      final price = ReceiptAmount.toRupiah(matches.last.group(1));
      if (price == null || price < ReceiptAmount.minPlausible) continue;

      final note = _describeItem(item, matches.first.start);
      if (note.isEmpty) continue;

      items.add(ReceiptLineItem(note: note, price: price));
    }

    return items;
  }

  /// The description is the text before the first figure, minus any leading
  /// quantity.
  String _describeItem(String row, int firstAmountStart) {
    var description = row.substring(0, firstAmountStart).trim();
    description = description.replaceFirst(RegExp(r'^\d+\s*[xX*]?\s*'), '');
    description = description.replaceAll(RegExp(r'\s*[.:\-]+$'), '').trim();

    // Needs real words, otherwise it is leftover punctuation or a code.
    final letters = description.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letters < 3) return '';

    return description;
  }

  /// The merchant name is nearly always in the first few rows, above the
  /// address block.
  String _findMerchant(List<String> rows) {
    for (final row in rows.take(5)) {
      final lower = row.toLowerCase();

      if (row.length < 3) continue;
      if (ReceiptKeywords.merchantExclusions.any(lower.contains)) continue;

      final letters = row.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      // Mostly-letters rules out barcodes, phone numbers and separator rows.
      if (letters < 3 || letters / row.length < 0.5) continue;

      return row;
    }

    return '';
  }
}
