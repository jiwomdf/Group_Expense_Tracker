import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/domain/model/receipt_row.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_amount.dart';
import 'package:core/util/receipt/receipt_date_reader.dart';
import 'package:core/util/receipt/receipt_item_reader.dart';
import 'package:core/util/receipt/receipt_keywords.dart';
import 'package:core/util/receipt/receipt_line_grouper.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';

/// Turns the text an OCR engine reads off a receipt into a [ReceiptScanModel].
///
/// Plain Dart with no plugin dependency: the OCR engine is mobile only, but the
/// rules are the part worth unit testing.
///
/// The vocabulary lives in [ReceiptKeywords], money handling in [ReceiptAmount],
/// dates in [ReceiptDateReader], layout in [ReceiptLineGrouper] and the item
/// list in [ReceiptItemReader]. This file is only the extraction rules that use
/// them.
class ReceiptParser {
  final ReceiptLineGrouper _grouper;
  final ReceiptDateReader _dateReader;
  final ReceiptItemReader _itemReader;

  const ReceiptParser({
    ReceiptLineGrouper grouper = const ReceiptLineGrouper(),
    ReceiptDateReader dateReader = const ReceiptDateReader(),
    ReceiptItemReader itemReader = const ReceiptItemReader(),
  })  : _grouper = grouper,
        _dateReader = dateReader,
        _itemReader = itemReader;

  /// Fragments the engine is this unsure of are noise more often than text.
  /// Applied only when the engine reports a confidence at all.
  static const _minConfidence = 0.4;

  /// Parses positioned OCR lines. Preferred over [parse]: knowing where text
  /// sat lets a label and its amount be put back on one row, and separates an
  /// item's name from the price column.
  ReceiptScanModel parseLines(List<ReceiptOcrLine> lines,
      {ReceiptScanLog? log}) {
    final rawText = lines.map((line) => line.text).join('\n');

    final legible = lines
        .where((line) => (line.confidence ?? 1) >= _minConfidence)
        .toList();
    if (legible.length < lines.length) {
      log?.detail('${lines.length - legible.length} low-confidence lines '
          'ignored');
    }

    final rows = _grouper.groupRows(legible);
    log?.stage('Group',
        '${legible.length} OCR lines merged into ${rows.length} printed rows');

    return _parseRows(rows, rawText, log);
  }

  /// Parses flattened OCR text, for callers with no geometry to offer.
  ReceiptScanModel parse(String rawText, {ReceiptScanLog? log}) {
    final rows = rawText
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .map(ReceiptRow.new)
        .toList();

    log?.stage('Rows', '${rows.length} text rows, no geometry available');

    return _parseRows(rows, rawText, log);
  }

  ReceiptScanModel _parseRows(
      List<ReceiptRow> rows, String rawText, ReceiptScanLog? log) {
    final texts = rows.map((row) => row.text).toList();

    final money = ReceiptMoneyFormat.detect(texts);
    log?.stage('Money',
        money.usesCents ? 'amounts printed with cents' : 'whole rupiah');

    final note = _findMerchant(texts);
    log?.stage('Merchant', note.isEmpty ? 'not found' : '"$note"');

    final price = _findTotal(texts, money, log);

    final date = _dateReader.read(texts);
    log?.stage(
        'Date',
        date == null
            ? 'not printed, today will be used'
            : '${date.day}/${date.month}/${date.year}');

    final items = _itemReader.read(rows, money: money, total: price, log: log);
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
  int? _findTotal(
      List<String> rows, ReceiptMoneyFormat money, ReceiptScanLog? log) {
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
        final amount = ReceiptAmount.lastIn(rows[i], money: money) ??
            (i + 1 < rows.length
                ? ReceiptAmount.lastIn(rows[i + 1], money: money)
                : null);

        if (amount != null && amount >= ReceiptAmount.minPlausible) {
          log?.stage('Total', 'Rp $amount');
          log?.detail(
              'matched "$keyword" (tier ${tierIndex + 1}) in row $i: "${rows[i]}"');
          return amount;
        }
      }
    }

    final largest = _largestAmountIn(rows, money);
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
  int? _largestAmountIn(List<String> rows, ReceiptMoneyFormat money) {
    int? largest;

    for (final row in rows) {
      if (ReceiptKeywords.totalExclusions.any(row.toLowerCase().contains)) {
        continue;
      }

      for (final match in ReceiptAmount.pattern.allMatches(row)) {
        final token = match.group(1);
        if (token == null || !ReceiptAmount.looksLikeMoney(token)) continue;

        final amount = money.toRupiah(token);
        if (amount == null || amount < ReceiptAmount.minPlausible) continue;
        if (largest == null || amount > largest) largest = amount;
      }
    }

    return largest;
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
